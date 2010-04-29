package com.ignite.olap.factory
{
	import com.ignite.olap.Cube;
	import com.ignite.olap.Level;
	import com.ignite.olap.Member;
	import com.ignite.olap.dto.RequestDTO;
	import com.ignite.olap.events.MemberFactoryEvent;
	import com.ignite.soap.SOAPCreator;
	import com.ignite.xmla.XMLAService;
	import com.igniteanalytics.logging.ASLogger;
	
	import de.polygonal.ds.ArrayedQueue;
	
	import flash.events.EventDispatcher;
	
	import mx.collections.IList;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	
	public class MemberFactory extends EventDispatcher
	{
		private var _level:Level;
		
		public var logger:ASLogger=new ASLogger("com.ignite.olap.MemberFactory");
	
		private var userToken:AsyncToken;
    	private var requestsStack:ArrayedQueue=new ArrayedQueue(150);
   
   		private var _cube:Cube;
   		private var _service:HTTPService;
   		
		public function MemberFactory(specificLevel:Level)
		{	
															logger.logDebug("(): level-"+specificLevel.name);
				_cube=specificLevel.dimension.cube as Cube;
				
				init();	
				if (specificLevel!=null){
					forLevel(specificLevel);
				}else{
					//for each level in cube
				}
		}
		private function init():void{
			 if (_service==null){
			 	if (_cube!=null){
			 		_service=_cube.service;	
			 	}
			}
		}
		private function forLevel(level:Level):void{
		     															logger.logDebug("forLevel:"+level.name);
		     var soapRequest:XML=SOAPCreator.getMembers(_cube,level.uniqueName,
		     										level.dimension.uniqueName,
		     										level.hierarchy.uniqueName);
		
		    _service.request = soapRequest;
																		logger.logDebug(soapRequest);
	        var token:AsyncToken = _service.send();					
	       	token.dto=new RequestDTO(XML(_service.request),level);						
			token.addResponder(new AsyncResponder(resultHandler, faultHandler));
		}
		private var _requestThreshold:int=20;
		
	    public function attachMembers(level:Level, list:XMLList):void
	    {
        var msRS:Namespace= new Namespace( "urn:schemas-microsoft-com:xml-analysis:rowset");
	
        var xmlNode:XML;
        var name:String;
        var uName:String;
        var pList:IList;
        var pName:String, pUName:String;
        var m:Member;
        var k:int;					
        																	logger.logDebug("attachMembers:"+level.name+" found num mems:"+list.length());
        										
            for(var i:int = 0; (i< list.length()) && (i<= _requestThreshold); i++)
            {
        		 try{
	                  xmlNode = list[i];
				       	//try measures first:
				       	var x:XMLList=XMLList(xmlNode.msRS::MEASURE_NAME);
				       	if (x.length()>0){
				       		name = String((xmlNode.msRS::MEASURE_NAME)[0]); 
				        	uName = String((xmlNode.msRS::MEASURE_UNIQUE_NAME)[0]);
				       	}else{
				       		name = String((xmlNode.msRS::MEMBER_NAME)[0]);		 
				            uName = String((xmlNode.msRS::MEMBER_UNIQUE_NAME)[0]);
				        }
				     //Ticket 56 add type support
				       var xType:String= String((xmlNode.msRS::MEMBER_TYPE)[0]);
				       var itype:int=0;
				       if (xType){
				       	itype=int(xType);
				       }
				       //56^^^^^^^^^^^^^^^^^^
				         
	                m = new Member(name, uName,itype);
	                if((xmlNode.msRS::PARENT_UNIQUE_NAME).length() > 0)
	                {
	                    pUName = String((xmlNode.msRS::PARENT_UNIQUE_NAME)[0]);
	                    pName = pUName.substring(pUName.lastIndexOf("[")+1, pUName.lastIndexOf("]"));
	                 	
	                    pList = level.hierarchy.levels[level.depth-1].findMember(pName);
	                    if (pList!=null){
		                    for(k = 0; k < pList.length; k++)
		                        if(pList[k].uniqueName == pUName){		logger.logDebug(m.uniqueName+" attaching parent:"+pList[k].uniqueName);
		                            m.parent = pList[k];
		                         }
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
		
		private function resultHandler(result:ResultEvent, token:Object = null):void
    	{
         
        var output:XML = result.result as XML;
		var token:Object=result.token;
		var uNow:int=new Date().time;
		try{
												logger.logInfo("resultHandler() dur:"+(new Date().time-RequestDTO(token.dto).createTime)+" response length:"+output.length());
											//	if (output!=null)logger.logDebug("resultHandler() response: "+output.toString());
	        //Reach the root node
	        
	        var responseRows:XMLList=XMLAService.getdataRows(output);
	        if (responseRows.length()>0){
	         //Find the sender
	        var parentElement:* = RequestDTO(token.dto).requestor;			 
	
	         attachMembers(parentElement,responseRows);
	       	if(requestsStack.size > 0)
	        {
	        
	            var latestReq:RequestDTO = requestsStack.dequeue();
	            _service.request = latestReq.packet;
	            var respToken:AsyncToken = _service.send();
	            respToken.dto=latestReq;
	            respToken.addResponder(new AsyncResponder(resultHandler, faultHandler));
	        }
	        else
	        {
	        	dispatchEvent(new MemberFactoryEvent(MemberFactoryEvent.COMPLETE));
	        }
	        }
	  }catch(err:Error){
	  	logger.logError("resultHandler()"+err.name+" "+err.message);
	  }
    }
	private function faultHandler(event:FaultEvent, token:Object=null):void
    {
        _cube.dispatchFaultEvent(event);
    }
		
		
	}
}