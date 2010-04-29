package com.ignite.xmla
{

import com.ignite.soap.SOAPCreator;
import com.igniteanalytics.logging.ASLogger;

import mx.core.mx_internal;
import mx.rpc.AsyncResponder;
import mx.rpc.AsyncToken;
import mx.rpc.IResponder;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;
import mx.rpc.http.HTTPService;
use namespace mx_internal;

[Exclude(name="request", kind="property")]
[Exclude(name="result", kind="event")]

//--------------------------------------
//  Events
//--------------------------------------

/**
*  Dispatched when an XMLAService call returns successfully.
*
*  @eventType XMLAEvent.XMLA_RESULT
*/
[Event(name="xmlaResult", type="events.XMLAEvent")]

public class XMLAService extends HTTPService
{
	
	private static var logger:ASLogger=new ASLogger("com.com.ignite.xmla.XMLAService");
    //--------------------------------------------------------------------------
    //
    //  Constants
    //
    //--------------------------------------------------------------------------

    /**
     * Constants defining the name of requests XMLAService handles
     *
     */
    public static const DISCOVER_DATASOURCES:String = "discoverDataSources";
    public static const DISCOVER_CATALOGS:String = "discoverCatalogs";
    public static const DISCOVER_CUBES:String = "discoverCubes";
    
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
    public function XMLAService()
    {
        method = "POST";
        contentType = "application/xml";
        resultFormat = "e4x";
        headers = getHeaders();
    }

    /**
     * The request object. The actual request object is sent by wrapping the parameters
     * given in this object in a SOAP Envelope
     * <p>
     * xmlaRequest Object can have following properties</p>
     * <code>type</code>(Required) - type of the discover request a.k.a datasources, catalogs, cubes or cube<br>
     * <code>DATASOURCE_NAME</code> - Name of the datasource on which discover has been requested<br>
     * <code>CATALOG_NAME</code>(Required) - Name of the catalog on which discover has been requested<br>
     * <code>CUBE_NAME</code>(Required) - Name of the cube on which discover has been requested<br>
     * <p>
     * Notice that a <code>DISCOVER_CUBE</code> requires all other higher parameters to be present in the request.
     * Similar requirement holds for <code>DISCOVER_CUBES</code> and <code>DISCOVER_CATALOGS</code> requests also.</p>
     */
    public var xmlaRequest:Object;

    /**
     *  @private
     */
    override public function send(parameters:Object=null):AsyncToken
    {																			logger.logDebug("send: url-"+this.url);
        if(!xmlaRequest || !xmlaRequest.type)
            xmlaRequest = {type:DISCOVER_DATASOURCES};

        return sendRequest(xmlaRequest.type, 
                           xmlaRequest["DATASOURCE_NAME"], 
                           xmlaRequest["CATALOG_NAME"]);
    }
    
    private function sendRequest(type:String, dataSource:String = null,catalog:String = null):AsyncToken
    {
        var userToken:AsyncToken = new AsyncToken(null);

        request = null;

        switch(type)
        {
            case DISCOVER_DATASOURCES:
                request = SOAPCreator.getDatasources();
                break;

            case DISCOVER_CATALOGS:
                if(dataSource)
                    request = SOAPCreator.getCatalogs(dataSource);
                break;

            case DISCOVER_CUBES:
                if(dataSource && catalog)
                    request = SOAPCreator.getCubes(dataSource, catalog);
                break;
        }
        
        if(request)
        {
            var token:AsyncToken = super.send();
            token.addResponder(new AsyncResponder(resultHandler, faultHandler, {type:type, returnToken:userToken}));
            return userToken;
        }
        return null;
    }
    
    /**
     *  @private
     *  Handles the incoming result XML stream, parses it 
     *  and dispatches an XMLAEvent when done
     */
    protected function resultHandler(event:ResultEvent, token:Object = null):void
    {																		logger.logDebug("resultHandler for:"+this.url);
        var requestType:String = token.type;
        var output:XMLList;

        if(event.result is XML)
        {
            output = getOutputBody(event.result as XML);

            var i:int;
            //0th child in output is the schema for rest of the elements
            if(output.children().length() > 1)
            {
                var msRS:Namespace= new Namespace( "urn:schemas-microsoft-com:xml-analysis:rowset");
		
                var n:int = output.length();
                
                var result:Array = [];
                for (var k:int=0;k<n;k++){
	                var crntXML:XML=output[k] as XML;
	                switch(requestType)
	                {
	                    case DISCOVER_DATASOURCES:
	                            result.push(crntXML..msRS::DataSourceName.toString());
	                        break;
	
	                    case DISCOVER_CATALOGS:
	                            result.push(crntXML..msRS::CATALOG_NAME.toString());
	                        break;
	
	                    case DISCOVER_CUBES:
	                            result.push(crntXML..msRS::CUBE_NAME.toString());
	                        break;
	                }
                }
                dispatchEvent(new XMLAEvent(requestType, result));
            }
        }
        
        if(token && token.returnToken && token.returnToken is AsyncToken)
            callUserResultResponders(AsyncToken(token.returnToken), result);
    }

    /*
     * Calls the AsyncResponders defined by the user, If any
     */
    private function callUserResultResponders(asyncToken:AsyncToken, result:Object):void
    {
        var responder:IResponder;
        if(asyncToken.hasResponder())
        {
            if (result)
            {
                for each(responder in asyncToken.responders)
                    {
                        responder.result(result);
                    }
            }
        }
    }

    /*
     * Calls the AsyncResponders defined by the user, If any
     */
    private function faultHandler(event:FaultEvent, token:Object=null):void
    {													logger.logError("faultHandler for "+this.url+" "+event.fault.message);
        var responder:IResponder;
        for each(responder in token.responders)
            {
                responder.fault(event);
            }
            
        dispatchEvent(new XMLAEvent(XMLAEvent.XMLA_FAULT,event));
        if(token && token.returnToken && token.returnToken is AsyncToken)
            callUserFaultResponders(AsyncToken(token.returnToken), event);
    
    }
	/*
     * Calls the AsyncResponders defined by the user, If any
     */
    private function callUserFaultResponders(asyncToken:AsyncToken, result:Object):void
    {
        var responder:IResponder;
        if(asyncToken.hasResponder())
        {
            if (result)
            {
                for each(responder in asyncToken.responders)
                    {
                        responder.fault(result);
                    }
            }
        }
    }

    private function getHeaders():Object
    {
        var o:Object = {};
        o["SOAPAction"] = '"urn:schemas-microsoft-com:xml-analysis:Discover"';
        o["Content-Type"] = "text/xml";
        return o;
    }

    /*
     * Parses the xml output to reach the area
     * in result xml where the corresponding data starts
     * i.e removes the xml headers and schema portion
     */
    private function getOutputBody(output:XML):XMLList
    {
            
//trace("RESPONSE===========================================\n");
//trace(output);
        //Reach the root node
        var soapNS:Namespace=output.namespace("SOAP-ENV");
        var cxmlaNS:Namespace=new Namespace("urn:schemas-microsoft-com:xml-analysis");
        var xsiNS:Namespace=new Namespace("http://www.w3.org/2001/XMLSchema-instance");
        var body:XMLList=output.soapNS::Body;
        
      
        //namespace msRS = "urn:schemas-microsoft-com:xml-analysis:rowset";
        //use namespace msRS;
		var msRS:Namespace= new Namespace( "urn:schemas-microsoft-com:xml-analysis:rowset");
		
        //Get all the rows
        var xsdNS:Namespace=new Namespace("http://www.w3.org/2001/XMLSchema");
        var sqlNS:Namespace=new Namespace("urn:schemas-microsoft-com:xml-sql");
        
        var list:XMLList = body..msRS::row;//.(@name=="row");
        
        return list;    
    }
    
    public static function getdataRows(response:XML):XMLList{
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
}
}
