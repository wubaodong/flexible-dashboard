package com.ignite.xmla
{
import mx.rpc.events.ResultEvent;
import flash.events.Event;

public class XMLAEvent extends ResultEvent
{
    /**
     *  The <code>XMLAEvent.XMLA_RESULT</code> constant defines the value of the 
     *  <code>type</code> property of the event object for a 
     *  <code>xmlaResult</code> event.
     * 
     *  <p>The properties of the event object have the following values:</p>
     *  <table class="innertable">
     *     <tr><th>Property</th><th>Value</th></tr>
     *     <tr><td><code>bubbles</code></td><td><code>false</code></td></tr>
     *     <tr><td><code>cancelable</code></td><td><code>true</code></td></tr>
     *     <tr><td><code>currentTarget</code></td><td>The Object that defines the 
     *       event listener that handles the event. For example, if you use 
     *       <code>myButton.addEventListener()</code> to register an event listener, 
     *       myButton is the value of the <code>currentTarget</code>. </td></tr>
     *     <tr><td><code>xmlaResult</code></td><td>Result Obtained from the request.</td></tr>
     *     <tr><td><code>target</code></td><td>The Object that dispatched the event; 
     *       it is not always the Object listening for the event. 
     *       Use the <code>currentTarget</code> property to always access the 
     *       Object listening for the event.</td></tr>
     *     <tr><td><code>type</code></td><td>XMLAEvent.XMLA_RESULT</td></tr>
     *  </table>
     *
     *  @eventType xmlaResult
     */
    public static const XMLA_RESULT:String = "xmlaResult";
	public static const XMLA_FAULT:String = "xmlaFault";

    /**
     *  The object which holds the result of the xmlaRequest (after being parsed)
     *  Except DISCOVER_CUBE, all other discover requests return an Array. A DISCOVER_CUBE
     *  request returns an ASCube Object
     */
    public var xmlaResult:Object;

    /**
     *  <p>Holds the type of the request, for which the event has been dispatched.</p>
     *
     *  It can have following values:<br>
     *  <code>XMLAService.DISCOVER_DATASOURCES</code><br>
     *  <code>XMLAService.DISCOVER_CATALOGS</code>
     *  <code>XMLAService.DISCOVER_CUBES</code>
     */
    public var requestType:String;

    /**
     *  Constructor.
     *
     *  @param type The event type; indicates the action that caused the event.
     */
    public function XMLAEvent(type:String, result:Object, progress:int = 100, total:int = 100, message:String = null)
    {	
    	if (type == null){
    		type=XMLA_RESULT;
    	}
       	super (type);
    	
    	this.xmlaResult = result;
        this.requestType = type;
    }

}
}
