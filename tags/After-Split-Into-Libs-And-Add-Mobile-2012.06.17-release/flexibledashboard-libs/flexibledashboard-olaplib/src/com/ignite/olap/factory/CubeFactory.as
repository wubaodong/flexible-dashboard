package com.ignite.olap.factory
{

import com.ignite.olap.*;
import com.ignite.olap.dto.RequestDTO;
import com.ignite.soap.SOAPCreator;
import com.igniteanalytics.logging.ASLogger;

import de.polygonal.ds.ArrayedQueue;

import flash.events.EventDispatcher;
import flash.utils.setTimeout;

import mx.collections.IList;
import mx.rpc.AsyncResponder;
import mx.rpc.AsyncToken;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;
import mx.rpc.http.HTTPService;

public class CubeFactory extends EventDispatcher
{
    private var _cube:Cube;
   
	private var _httpService:HTTPService;
	private var _getMembers:Boolean=true;
	
	public var logger:ASLogger=new ASLogger("com.ignite.olap.CubeFactory");
	
	private var userToken:AsyncToken;
    
    private var requestsStack:ArrayedQueue=new ArrayedQueue(150);
    public function CubeFactory(_httpService:HTTPService, cube:Cube, getMembers:Boolean=false)
    {
        this._httpService = _httpService;
        this._cube = cube;
        this._getMembers=getMembers;
       												logger.logInfo("CubeFactory() instantiation:"+cube.name+" url-"+_httpService.url);
        try{
	        _httpService.request = SOAPCreator.getDimensions(_cube);
			
	        var token:AsyncToken = _httpService.send();					
	       	token.dto=new RequestDTO(XML(_httpService.request),_cube);						
			token.addResponder(new AsyncResponder(resultHandler, faultHandler));
		  }catch(err:Error){
		  	logger.logError("CubeFactory():"+err.message);
		  	throw new Error(err.message,err.errorID);
		  }
    }
    
    private var cancelProgress:Boolean = false;
    public function cancelCreation():void
    {
        cancelProgress = true;
    }
	private function getdataRows(response:XML):XMLList{
			var soapNS:Namespace=response.namespace("SOAP-ENV");
	        var cxmlaNS:Namespace=new Namespace("urn:schemas-microsoft-com:xml-analysis");
	        var xsiNS:Namespace=new Namespace("http://www.w3.org/2001/XMLSchema-instance");
	        var body:XMLList=response.soapNS::Body;
	        
	        var msRS:Namespace= new Namespace( "urn:schemas-microsoft-com:xml-analysis:rowset");
			
	        //Get all the rows
	        var xsdNS:Namespace=new Namespace("http://www.w3.org/2001/XMLSchema");
	        var sqlNS:Namespace=new Namespace("urn:schemas-microsoft-com:xml-sql");
	        
	        return body..msRS::row;//.(@name=="row");
	}
    
    private function resultHandler(result:ResultEvent, token:Object = null):void
    {
        if(cancelProgress)
            return;
        
        var output:XML = result.result as XML;
		var token:Object=result.token;
		var uNow:int=new Date().time;
		try{
												logger.logInfo("resultHandler() dur:"+(new Date().time-RequestDTO(token.dto).createTime)+" response length:"+output.length());
											//	if (output!=null)logger.logDebug("resultHandler() response: "+output.toString());
	        //Reach the root node
	        var responseRows:XMLList=getdataRows(output);
	        //Find the sender
	        var parentElement:* = RequestDTO(token.dto).requestor;			 
	
	       	processDiscoveryRequest(parentElement,responseRows);
	        
	        var message:String
	        if(requestsStack.size > 0)
	        {
	            var latestReq:RequestDTO = requestsStack.dequeue();
	            _httpService.request = latestReq.packet;
	            var respToken:AsyncToken = _httpService.send();
	            respToken.dto=latestReq;
	            respToken.addResponder(new AsyncResponder(resultHandler, faultHandler));
	
	            var type:String;
	            var progress:int;
	
	            if(latestReq.requestor is Dimension)
	            {
	                progress = 0;
	                type = "Dimension Hierarchies ";
	            }
	            else if (latestReq.requestor is AttributeHierarchy)
	            {
	                progress = 20;
	                type = "Attr. Hierarchy Levels";
	            }
	            else if (latestReq.requestor is Hierarchy)
	            {
	                progress = 20;
	                type = "Hierarchy Levels";
	            }
	            else if (latestReq.requestor is Level)
	            {
	                progress = 50;
	                type = "Level Members";
	            }
	           																	
				message = "Retrieving "+type+ " "+latestReq.requestor.uniqueName;
	            _cube.dispatchProgressEvent(progress, 100, message);
	        }
	        else
	        {
	            _cube.dispatchCompleteEvent(_cube, message, userToken);
	        }
	  }catch(err:Error){
	  	logger.logError("resultHandler()"+err.name+" "+err.message);
	  }
    }
    private function processDiscoveryRequest(parent:*,rowsToTraverse:XMLList):void{
      if (!cancelProgress)
    	if(parent is Cube)
             attachDimensions(parent as Cube, rowsToTraverse);
        else if (parent is Dimension)
      		 flash.utils.setTimeout(attachHierarchies,10,parent,rowsToTraverse);  
	         //    findHierarchies(Dimension(parent), rowsToTraverse);
        else if (parent is Hierarchy)
             flash.utils.setTimeout(attachLevels,10,parent,rowsToTraverse);
             //findLevels(Hierarchy(parent), rowsToTraverse);
        else if(parent is Level )
             flash.utils.setTimeout(attachMembers,10,parent,rowsToTraverse);
        	//findMembers(Level(parent), rowsToTraverse);
	}
    public function attachDimensions(_cube:Cube, list:XMLList):void
    {
        var xmlNode:XML;
        var name:String;
        var uName:String;
        var dimension:Dimension;
        var i:int;
  										logger.logDebug("findDimensions:"+_cube.name);
        try{
        
	        for(i = 0; i< list.length(); i++)
	        {
	            xmlNode = list[i];
	  		  	var msRS2:Namespace= new Namespace( "urn:schemas-microsoft-com:xml-analysis:rowset");
				var xsdNS:Namespace=new Namespace("http://www.w3.org/2001/XMLSchema");
		        var sqlNS:Namespace=new Namespace("urn:schemas-microsoft-com:xml-sql");
		        var soapNS:Namespace=xmlNode.namespace("SOAP-ENV");
		        var cxmlaNS:Namespace=new Namespace("urn:schemas-microsoft-com:xml-analysis");
		        var xsiNS:Namespace=new Namespace("http://www.w3.org/2001/XMLSchema-instance");
		  
	        //    trace(xmlNode);
	            name = String((xmlNode.msRS2::DIMENSION_NAME)[0]);
	           																						 logger.logDebug(_cube.name+" found dimension:"+name);
	            uName = String((xmlNode.msRS2::DIMENSION_UNIQUE_NAME)[0]);
	            dimension = new Dimension(name, uName);
	            
	            if(String((xmlNode.msRS2::DIMENSION_TYPE)[0])=="2")
	                dimension.isMeasure = true;
	            
	            _cube.addDimension(dimension);
	            
	            var soapRequest:XML=SOAPCreator.getHierarchies(_cube, uName);
	            
	            requestsStack.enqueue(new RequestDTO(soapRequest, dimension));
	        }
	       }catch(err:Error){
	       	logger.logError("findDimensions "+err.name+" "+err.message);
	       }
    }
    
    public function attachHierarchies(dimension:Dimension, list:XMLList):void
    {
          var msRS:Namespace= new Namespace( "urn:schemas-microsoft-com:xml-analysis:rowset");
	
   																								logger.logDebug("findHierarchies:"+dimension.name);
        var xmlNode:XML;
        var name:String;
        var uName:String;
        var i:int;
        var h:Hierarchy;
        for(i = 0; i< list.length(); i++)
        {
			  try{
		         		xmlNode = list[i];
			            name = String((xmlNode.msRS::HIERARCHY_NAME)[0].children()[0]);						
			            uName = String((xmlNode.msRS::HIERARCHY_UNIQUE_NAME)[0].children()[0]);
			            var origin:String = String((xmlNode.msRS::HIERARCHY_ORIGIN)[0]);
			            
			            var defaultMember:String = String((xmlNode.msRS::DEFAULT_MEMBER)[0].children()[0]);
			           // if(origin=="undefined" || origin == "2")
			          //  {
			          //      h = new AttributeHierarchy(name, uName);
			               // h.setDefaultMember(defaultMember.substring(defaultMember.lastIndexOf("[")+1, defaultMember.lastIndexOf("]")));
			          //      h.setDefaultMember(defaultMember);
			          //      dimension.addAttribute(ASAttributeHierarchy(h));
			          //  }
			          //  else
			         //   {
			                h = new Hierarchy(name, uName);
			                h.setDefaultMember(defaultMember);
			              
			                dimension.addHierarchy(h);
			        //    }
			            
			            if(!dimension.isMeasure)
			            {
			                var allMember:String = String(xmlNode.msRS::ALL_MEMBER[0]);
			                if(allMember)
			                    h.allMemberName = allMember;
			            }
			            else
			            {
			              
			            }
																							logger.logDebug("found Hierarchy:"+uName+" allmem:"+h.allMemberName);
						var soapRequest:XML=SOAPCreator.getLevels(_cube, dimension.uniqueName, uName);
			            requestsStack.enqueue(new RequestDTO(soapRequest, h));
			      }catch(err:Error){
						logger.logError("findHierarchies dim:"+dimension.name+" "+err.name+" "+err.message);
				  }
		}//for
	 }

    public function attachLevels(hierarchy:Hierarchy, list:XMLList):void
    {
        var msRS:Namespace= new Namespace( "urn:schemas-microsoft-com:xml-analysis:rowset");
		
        var xmlNode:XML;
        var name:String;
        var uName:String;
        var i:int;
        var l:Level;
															logger.logDebug("findLevels:"+hierarchy.uniqueName);
        for(i = 0; i < list.length(); i++)
        {
         try{
	            xmlNode = list[i];
	            if((xmlNode.msRS::LEVEL_IS_VISIBLE).length() > 0)
	            {
	                name = String((xmlNode.msRS::LEVEL_NAME)[0]);							
	                uName = String((xmlNode.msRS::LEVEL_UNIQUE_NAME)[0]);				
	            }
	            else
	            {
	                name = "All";
	                uName = hierarchy.uniqueName+".[All]";
	            }
	            
	            l = new Level(name, uName);									logger.logDebug("found level:"+hierarchy.uniqueName+" "+uName);
	            
	            hierarchy.addLevel(l);
	            var soapRequest:XML;
	            if(hierarchy.dimension.isMeasure)
	           		 soapRequest=SOAPCreator.getMeasures(_cube, hierarchy.dimension.uniqueName, hierarchy.uniqueName, uName);
	            else{
	            	if (_getMembers){
	       			 soapRequest=SOAPCreator.getMembers(_cube,uName, hierarchy.dimension.uniqueName, hierarchy.uniqueName);
	            	 requestsStack.enqueue(new RequestDTO(soapRequest, l));
	      			}else{
	            		//add a dummy
	            		l.addMember(HAS_MEMBERS_PLACEHOLDER);
	            	}
	            }
	        }catch(err:Error){
	        	logger.logError("findLevels hier:"+hierarchy.uniqueName+" "+err.name+" "+err.message);
	        }
		}
    }
    public static var HAS_MEMBERS_PLACEHOLDER:Member=new Member("Get Members","Get Members");
	private var _requestThreshold:int=20;
    public function attachMembers(level:Level, list:XMLList):void
    {
        var msRS:Namespace= new Namespace( "urn:schemas-microsoft-com:xml-analysis:rowset");
	
        var xmlNode:XML;
        var name:String;
        var uName:String;
        var pList:IList;
        var pName:String, pUName:String;
        var i:int;
        var m:Member;
        var k:int;											
        											logger.logDebug("findMembers "+level.uniqueName);
            for(i = 0; (i< list.length()) && (i<= _requestThreshold); i++)
            {
        		 try{
	                  xmlNode = list[i];
				       
				        if(!level.hierarchy.dimension.isMeasure){
				          		name = String((xmlNode.msRS::MEMBER_NAME)[0]);		 
				                uName = String((xmlNode.msRS::MEMBER_UNIQUE_NAME)[0]);
				        }else{
				        	 name = String((xmlNode.msRS::MEASURE_NAME)[0]); 
				             uName = String((xmlNode.msRS::MEASURE_UNIQUE_NAME)[0]);
				       }
				       
	                m = new Member(name, uName);
	                if((xmlNode.msRS::PARENT_UNIQUE_NAME).length() > 0)
	                {
	                    pUName = String((xmlNode.msRS::PARENT_UNIQUE_NAME)[0]);
	                    pName = pUName.substring(pUName.lastIndexOf("[")+1, pUName.lastIndexOf("]"));
	                 	
	                    pList = level.hierarchy.levels[level.depth-1].findMember(pName);
	                    var r:Boolean=_cube.isMember(pName);
	                    if (pList!=null){
		                    for(k = 0; k < pList.length; k++)
		                        if(pList[k].uniqueName == pUName)
		                            m.parent = pList[k];
	                    }else{
	                    	var pM:Member=new Member(pName,pUName);
	                    	m.parent=pM;
	                    }
		           }
	                    else
	                        m.parent = null;
	                
	                level.addMember(m);							logger.logDebug(level.uniqueName+" addMember "+m.uniqueName);	
	               }catch(err:Error){
	               	logger.logError("findMembers "+level.uniqueName+" "+err.name+" "+err.message);
	               }
            }
            if (list.length()>_requestThreshold){
            	//well there were too many so create a fake one
            	//to act as a marker that more exist
            	var newList:XMLList=getTailElements(list,_requestThreshold);
             }
          
    }
    private function getTailElements(list:XMLList,tailSize:int):XMLList{
    	var loopSize:int=list.length()-tailSize;
    	var rList:XMLList=new XMLList();
    	var i:int=0;
    	for (var x:int=loopSize;x<list.length();x++){
    		rList[i]=list[x];
    	}
    	return rList;
    }
    private function faultHandler(event:FaultEvent, token:Object=null):void
    {
        _cube.dispatchFaultEvent(event);
    }
}
}

