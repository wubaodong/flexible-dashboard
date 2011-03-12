package com.ignite.olap
{
import com.ignite.olap.dto.RequestDTO;
import com.ignite.olap.factory.CubeFactory;
import com.ignite.soap.SOAPCreator;
import com.igniteanalytics.logging.ASLogger;

import flash.events.EventDispatcher;
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.collections.IList;
import mx.core.mx_internal;
import mx.events.CubeEvent;
import mx.olap.IOLAPCube;
import mx.olap.IOLAPDimension;
import mx.olap.IOLAPHierarchy;
import mx.olap.IOLAPQuery;
import mx.olap.IOLAPSet;
import mx.olap.OLAPQuery;
import mx.olap.OLAPSet;
import mx.rpc.AsyncResponder;
import mx.rpc.AsyncToken;
import mx.rpc.IResponder;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;
import mx.rpc.http.HTTPService;
use namespace mx_internal;

//--------------------------------------
//  Events
//--------------------------------------

/**
*  Dispatched when a cube has been created
*  and is ready to be queried.
*
*  @eventType mx.events.CubeEvent.CUBE_COMPLETE
*/
[Event(name="complete", type="mx.events.CubeEvent")]

/**
*  Dispatched continuously as a cube is being created
*  by a call to the <code>refresh()</code> method.
*
*  @eventType mx.events.CubeEvent.CUBE_PROGRESS
*/
[Event(name="progress", type="mx.events.CubeEvent")]

/**
*  Dispatched continuously as a cube is being created
*  by a call to the <code>refresh()</code> method.
*
*  @eventType mx.events.FaultEvent.FAULT
*/
[Event(name="fault", type="mx.events.FaultEvent")]

public class Cube extends EventDispatcher implements IOLAPCube
{

	public var logger:ASLogger=new ASLogger("com.ignite.olap.Cube");

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
    public function Cube(name:String=null, dataSource:String=null, catalog:String=null, url:String=null)
    {
        this.dataSource = dataSource;
        this.catalog = catalog;
        this.name = name;
        											logger.logInfo("Cube creation:"+name+" dataSource:"+dataSource+" catalog:"+catalog+" url-"+url);
      
        //Initialize the service object needed to query the server
        service = new HTTPService;
        service.method = "POST";
        service.contentType = "application/xml";
        service.resultFormat = "e4x";
        service.headers = getHeaders();

        this.serviceURL = url;
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    /**
    *  service object associated with the remote cube
    */
    public var service:HTTPService;
    
    /**
    *  cubeCreator instance responsible for triggering
    *  cube refresh.
    */
    private var cubeCreator:CubeFactory;
    

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    private var _dimensions:IList;

    private var _dimensionNameMap:Dictionary = new Dictionary(false);

    /**
     *  an IList of the ASDimension objects of this cube
     */
    public function get dimensions():IList
    {
        return _dimensions;
    }

    /**
     *  @private
     */
    private var _name:String;

    /**
     * name of the Analysis Services Cube
     */
    public function set name(value:String):void
    {
        this._name = value;
    }
    public function get name():String
    {
        return _name;
    }

    /**
    *  Name of the dataSource to which this cube belongs
    */
    public var dataSource:String;

    /**
    *  Name of the catalog to which this cube belongs
    */
    public var catalog:String;

    /**
    *  service URL of the HTTP pump
    */
    private var _serviceURL:String;
    public function get serviceURL():String
    {
        return _serviceURL;
    }

    public function set serviceURL(url:String):void
    {
        if(service)
            service.url = url;
        _serviceURL = url;
    }

    /**
    *  adds a dimension to the cube
    */
    public function addDimension(dim:Dimension):void
    {
        if(!_dimensions)
            _dimensions = new ArrayCollection;
        _dimensions.addItem(dim);
        dim.cube = this;
        _dimensionNameMap[dim.name] = dim;

    }
    public function getElement(uniqueName:String):*{
    	//recursively searches for uniqueName
    	if (this.findDimension(uniqueName)){
    		return this.findDimension(uniqueName);
    	}else{
    		for each (var dim:IOLAPDimension in this._dimensions){				//trace(dim.uniqueName+" searching for "+uniqueName);
    			var possibleRValue:Object=dim.findHierarchy(uniqueName);
    			if (!possibleRValue){
    				possibleRValue=dim.findMember(uniqueName);
    				if (possibleRValue){
    					return possibleRValue;
    				}else{//look in levels (dim has no search for level
    					for each (var h:IOLAPHierarchy in dim.hierarchies){			//trace("-"+h.uniqueName+" searching for "+uniqueName);
    						if (h.uniqueName.indexOf("[Store]")>0){
    							var i:int=23;
    						}
    						possibleRValue=h.findLevel(uniqueName);
    						if (!possibleRValue){
    							
    							possibleRValue=h.findMember(uniqueName);
    							if (possibleRValue){
    								return possibleRValue;
    							}
    						}else{
    							return possibleRValue;
    						}
    					}
    				}
    			}else{
    				return possibleRValue;
    			}
    		}
    	}
    	return null;
    }
    /**
    *  finds a dimension in the cube
    */
    public function findDimension(name:String):IOLAPDimension
    { 
    	name=name.replace("[","");
    	name=name.replace("]","");
        if(_dimensionNameMap && _dimensionNameMap[name])
            return _dimensionNameMap[name]
        return null;
    }

	
	public function isMember(name:String):Boolean{
		//iterate through all dimensions and the children
		if (findDimension(name)!=null){
			return false;
		}else{
			for each (var id:Dimension in _dimensions){
				if (id.findMember(name)!=null){
					return true;
				}
			}
		}
		return false;
	}
    /**
    *  executes the given query and returns an AsyncToken
    *  associated with the request
    *  <br>
    *  <code>query</code> should be of type ASQuery with the 
    *  query parameter set.
    */
    public function execute(_query:IOLAPQuery):AsyncToken
    {
    	var rToken:AsyncToken = new AsyncToken(null);
	    var allowEmpty:Boolean=false;
	    var mdxExists:Boolean=false;
	    if (_query is Query){
	    	allowEmpty=Query(_query).allowEmpty;
	    }
	    		logger.logDebug("executing Query:");
	    		var mdx:String="";
	    		if (_query is com.ignite.olap.Query){
	    			if (com.ignite.olap.Query(_query).mdxFormat){
	    				mdx=com.ignite.olap.Query(_query).query;
	    			}else{
	    				mdx=buildMDX(_query,allowEmpty);
	    			}
	    		}else{
	    			mdx=buildMDX(_query,allowEmpty);
	    		}								
	    	 	
	    	 	rToken.mdxQuery=mdx;
	            
				logger.logDebug("---Query:"+mdx);
				
				// sreiner added so don't send discover in header with execute in body								
				service.headers = getExecuteHeaders();											
													
	    	 	service.request = SOAPCreator.execute(this,mdx );
	            var actualTokenQuery:AsyncToken = service.send();
	            
	            actualTokenQuery.dto=new RequestDTO(XML(service.request),_query);		
	            actualTokenQuery.addResponder(new AsyncResponder(resultHandler, faultHandler,rToken));
	    
	      return rToken;
	}
	
    public var logResult:Boolean=false;
    private function resultHandler(event:ResultEvent, callBackToken:Object = null):void
    {
        var output:XML;
        var responder:IResponder;
        							logger.logDebug("resultHandler");
		try{
	        if(event.result is XML)
	        {
	            output = event.result as XML;
			
	           // trace(output);
	           // if(!isInvalidResult(output, token))
	   				
					logger.logDebug("resultHandler result is xml");
					if (logResult){
						logger.logDebug("resultHandler result Length:"+output.toXMLString());
					}else{
						logger.logDebug("resultHandler result Length:"+output.length());
					}
					
	                if(callBackToken && callBackToken is AsyncToken)
	                {
	                    var aToken:AsyncToken = AsyncToken(callBackToken);
	                    if(aToken.hasResponder())
	                    {
	                        var result:MDDatasetResult = new MDDatasetResult(output, this);
	                        						logger.logDebug("resultHandler result xml is parsed");
	                        if (result)
	                        {
	                            for each(responder in aToken.responders)//This should be calling a function in the flex UI
	                                {
	                                				logger.logDebug("resultHandler calling responder for results");
	                                    responder.result(result);
	                                }
	                        }
	                    }
	                }
	        }
	 }catch(err:Error){
	 	var i:int=432;
	 	handleError(err,callBackToken);
	 }
    }

    /**
    *  Triggers the cube discover process. 
    *  <br>
    *  Discovery works by discovering the cube tree in a Breadth First manner. 
    *  i.e first all the dimensions are discovered, then all the attributes 
    *  and hierarchies of each dimension are discoverd. Finally, all the OLAPLevel 
    *  for each of the hierarchy and attribute are discovered
    *
    *  Note: Discovery of members is deferred and they are added to the levels
    *  at the time of querying
    */
    public var _getMembers:Boolean=false;
    public function refresh():void
    {
        if (_serviceURL=="" || _serviceURL==null){
       		throw new Error("URL is not defined. Please define the url to the xmla server. e.g.: http://localhost:8081/mondrian/xmla");
       	}
       	
		if (_name=="" || _name==null){
       		throw new Error("Cube Name not defined. Please define the cube name.");
       	}
		
		// sreiner ok to have empty string datasource
       	//if (dataSource =="" || dataSource==null){
		if (dataSource == null)
		{
       		throw new Error("Data Source Name not defined. Please define the data source. eg: Provider=Mondrian;DataSource=MondrianFoodMart;");
       	}
       	
        //Trigger the Cube creation
        cubeCreator = new CubeFactory(service, this,this._getMembers);
        
       
    }
    public function cancelQuery(query:IOLAPQuery):void
    {
        //TODO
    }
    
    /**
     *  Aborts a cube refresh which is getting processed.
     */
    public function cancelRefresh():void
    {
        cubeCreator.cancelCreation();
        cubeCreator = null;
    }

    /*
     * Dispatches the <code>CUBE_COMPLETE</code> event indicating the progress
     * of cube discover process
     */
    public function dispatchCompleteEvent(cube:Cube, message:String, userToken:AsyncToken):void
    {
        dispatchEvent(new CubeEvent(CubeEvent.CUBE_COMPLETE));
    }

    /*
     * Dispatches the <code>CUBE_PROGRESS</code> event indicating the progress
     * of cube discover process
     */
    public function dispatchProgressEvent(progress:int, total:int, message:String):void
    {
        var ev:CubeEvent = new CubeEvent(CubeEvent.CUBE_PROGRESS);
        ev.progress = progress;
        ev.total = total;
        ev.message = message;
        dispatchEvent(ev);
    }
    /*
     * Dispatches the <code>Fault</code> event indicating some error has occurred while
     * discovering the cube
     */
    public function dispatchFaultEvent(event:FaultEvent):void
    {
        dispatchEvent(event);
    }

    private function handleError(err:Error, token:Object):void
    {
    	  															 logger.logInfo("handleError processing an error");
           if(token is AsyncToken && AsyncToken(token).hasResponder())
            {
                var responder:IResponder;
                var error:Error = err;
                for each(responder in token.responders)
                    {
                        responder.fault(error);
                    }
            }
    }

    /*
     * Calls the AsyncResponders defined by the user, If any
     */
    private function faultHandler(event:FaultEvent, token:Object=null):void
    {
        var e:Error = new Error(event.fault);
        var responder:IResponder;
        for each(responder in token.responders)
            {
                responder.fault(event);
            }
    }

    private function getHeaders():Object
    {
        var o:Object = {};
        o["SOAPAction"] = '"urn:schemas-microsoft-com:xml-analysis:Discover"';
        o["Content-Type"] = "text/xml";
        return o;
    }

	// sreiner added
	private function getExecuteHeaders():Object
	{
		var o:Object = {};
		o["SOAPAction"] = '"urn:schemas-microsoft-com:xml-analysis:Execute"';
		o["Content-Type"] = "text/xml";
		return o;
	}	
	
    /*
     * Parses the xml output to reach the area
     * in result xml where the corresponding data starts
     * i.e removes the xml headers and schema portion
     */
    private function getOutputBody(output:XML):XML
    {
        if(!output.children().length > 0)
            return output;
        else if(!output.children()[0].children().length > 0)
            return output.children()[0];
        else if(!output.children()[0].children()[0].children().length > 0)
            return output.children()[0].children()[0];
        else if(!output.children()[0].children()[0].children()[0].children().length > 0)
            return output.children()[0].children()[0].children()[0];
        
        return output.children()[0].children()[0].children()[0].children()[0];    
    }
    
    
     //-================================================================
    // For converting to MDX QUery------------------------------------
    //=================================================================
    	private function buildMDX(query:IOLAPQuery,allowEmpty:Boolean=false):String{
    		
    		return buildQuery(query.getAxis(OLAPQuery.ROW_AXIS).sets,
    						  query.getAxis(OLAPQuery.COLUMN_AXIS).sets,
    						  query.getAxis(OLAPQuery.SLICER_AXIS).sets,allowEmpty)
    	}
    	
    	private function buildQuery(	rows:Array,
											columns:Array,
											filters:Array,allowEmpty:Boolean=false):String{
				
				var cube:Cube=this;
				//Build the list of sets
				//Each array should represnt a set {} of tuples
				
				var completeMDX:String=null;
				
				var colAxis:String=buildAxis(cube,columns,OLAPQuery.COLUMN_AXIS);
				
				var rowAxis:String=buildAxis(cube,rows,OLAPQuery.ROW_AXIS);
				
				var defaultAxis:String="[Measures].members";
				var needDefault:Boolean=true;
				
				try{
					needDefault=rowAxis.indexOf(defaultAxis)<0;
				}catch(err:Error){}
				try{
						needDefault= needDefault && (colAxis.indexOf(defaultAxis)<0);
				}catch(err:Error){}
				
				if (needDefault){
					if (rowAxis==null){rowAxis=defaultAxis +" on rows"};
					if (colAxis==null){colAxis=defaultAxis+" on columns"};
				}
				//build out the final string
				completeMDX="select ";
				if (!allowEmpty){
						completeMDX=completeMDX.concat(" NON EMPTY ");
					}
				if (colAxis!=null){
				 completeMDX=completeMDX.concat(colAxis);
				 if (rowAxis!=null){
				 	completeMDX=completeMDX.concat(",");
				 }
				}
				if (rowAxis!=null){
				 completeMDX=completeMDX.concat(rowAxis);	
				}
				
				// sreiner add brackets for cube names with spaces
				completeMDX=completeMDX.concat(" from [" + cube.name + "]");
				
				if (completeMDX!=null && completeMDX!='')
					if (filters!=null && filters.length>0){
						completeMDX=completeMDX+buildFilters(cube,filters);
					}
				 return completeMDX;
																	logger.logDebug ("buildQuery built:"+completeMDX);
		}
		
		private function buildAxis(cube:Cube,aryOfSets:Array,axisType:int):String{
			
			//Each array should represnt a set {} of tuples 
				var axisLabel:String="";
				switch (axisType){
					case OLAPQuery.ROW_AXIS:
							axisLabel=" rows ";
											break;
				    case OLAPQuery.COLUMN_AXIS:
				    				axisLabel=" columns";
				    						break;
				    						
				   /* case OLAPQuery.SLICER_AXIS:
				    				axisLabel=" where "	;
				    						break;
				    						*/		
				}
				var rValue:String=null;
				var needHierarchy:Boolean=false;
				if (aryOfSets.length>0){
					rValue="";
					for (var i:int=0;i<aryOfSets.length;i++){
						//Ticket 77
						if (IgniteOLAPSet(aryOfSets[i])._elements.length>1) needHierarchy=true;
						//^^^^^^^^^^^^
					
						rValue=rValue.concat(buildSet(aryOfSets[i]));
						//now we are going to use different notations for cross joins rather
						//than CrossJoin({},{})
						if ((i+1)<aryOfSets.length){
							rValue=rValue.concat(" * ");
						}
					}
					if (needHierarchy){
						//Ticket 77
						rValue="Hierarchize(" +rValue+")"; 
					}
					if (rValue!=null && rValue!="" && rValue!="null"){
						
						rValue=rValue.concat(" on "+axisLabel);
					}else{
						rValue=null;
					}
					
				}
				return rValue;
		}
		private function buildFilters(cube:Cube,filters:Array):String{
			var rValue:String=null;
			try{
				if (filters.length>0){
					rValue="";
					for (var k:int=0;k<filters.length;k++){
						rValue=rValue.concat(buildSet(filters[k]));
					}
					if (rValue!=null){
						rValue=" WHERE (" + rValue+")";
					}
				}
			}catch(err:Error){}
			
			return rValue;
		}
		public function buildSet(oSet:IOLAPSet):String{
			var cube:Cube=this;
			
			var rValue:String=null;
			var temp:String="";
			/* drill down example:
			
			select DrillDownLevel({[Store Type].[All Store Types].children}) on columns, DrillDownLevel({[Store].[All Stores].children}) *
			DrillDownLevel({[Pay Type].[All Pay Types].children}) 
			on rows from HR

			*/
			var wrapInBrackets:Boolean=false;
			if (oSet!=null)
			if (oSet is IgniteOLAPSet){
				logger.logDebug (" buildSet IgniteOLAPSet");
				if(IgniteOLAPSet(oSet)._elements.length>0){
					wrapInBrackets=true;	
					var elements:Array=IgniteOLAPSet(oSet)._elements.toArray();
					
					for (var j:int;j<elements.length;j++){
							temp=temp+deriveTuple(elements[j],cube);
						
							if (j+1<elements.length){
									if (Element(elements[j]).drillDownSelected){
										temp=temp.concat("*");
										wrapInBrackets=false;
									}else{
										temp=temp.concat(",");
									}
							}	
					}
													
				}	
			}else{
				logger.logDebug (" buildSet OLAPSet");
				
				var olapSet:OLAPSet=OLAPSet(oSet);
				if(olapSet.tuples.length>0){
					wrapInBrackets=true;	
						for (var tCnt:int=0;tCnt<olapSet.tuples.length;tCnt++){
						var members:Array=Tuple(olapSet.tuples[tCnt]).members as Array;
						for each (var mem:Member in members){
							temp=temp+deriveTuple(mem,cube);
						
							if (j+1<elements.length){
									if (Element(elements[j]).drillDownSelected){
										temp=temp.concat("*");
										wrapInBrackets=false;
									}else{
										temp=temp.concat(",");
									}
							}	
						}
					}
				}
			}
			if (wrapInBrackets){ rValue=rValue= " {"+temp+"} ";
				}else{
					rValue=temp;
			}
										logger.logDebug (" buildSet:"+rValue);
			return rValue;
		}
		public function deriveTuple(node:Element,cube:Cube):String{
			var rValue:String=node.uniqueName;
		    var temp:String=node.uniqueName;			
		    					logger.logDebug("deriveTuple:"+node.uniqueName+" drilldown:"+node.drillDownSelected);
		   //Ticket 65 making drilldown part of the object via dyanmic 
					 var createForDrillDown:Boolean=node.drillDownSelected;
		    try{
		    	
		    	if (node is Tuple){
		    		node=Tuple(node).members[0];
		    	}
		    	
		    	//If coming from a popup the node is not really defined
		    	//so try to get the correct element from cube
		    	var explicitElem:Object=cube.getElement(node.uniqueName);
		    	
		    	if (ElementsDelegate.hasChildren(explicitElem) && createForDrillDown){
					rValue= "Descendants("+explicitElem.uniqueName +")";
				}else{
					rValue= explicitElem.uniqueName;
					createForDrillDown=false;
				}
		    	
				if (explicitElem is Dimension){
					rValue= explicitElem.uniqueName;
				}
				if (explicitElem is Cube){
				}
				
				if (explicitElem is Catalog){
				}
				if (explicitElem is Hierarchy){
					rValue= explicitElem.uniqueName;
				}
				if (explicitElem is Level){
					rValue= explicitElem.uniqueName+".members";
				}
				if (explicitElem is Member){
					if (Member(explicitElem).isMeasure){
						rValue= explicitElem.uniqueName;
					}else{
						if ((Member(explicitElem).level && Member(explicitElem).level.depth>0)
							&&	(Member(explicitElem).parent==null || Member(explicitElem).isAll)
							&&  (Member(explicitElem).children.length>0)
							){
							rValue= explicitElem.uniqueName+".children";
						}else{
							rValue=explicitElem.uniqueName;
						}
					}
				}
			    if (createForDrillDown){
			    	 rValue=" DrillDownLevel({"+rValue+"}) ";
			    }
			 }catch(err:Error){
					return rValue;
		    }
		    return rValue;
		}
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    
    
    
    
    
}
}
