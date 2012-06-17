/*
* Base class for pod content.
*/

package com.esria.samples.dashboard.view
{
import com.esria.samples.dashboard.managers.PodLayoutManager;

import flash.xml.XMLNode;

import mx.controls.Alert;
import mx.events.FlexEvent;
import mx.events.IndexChangedEvent;
import mx.managers.IFocusManagerComponent;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;
import mx.rpc.http.HTTPService;
import mx.utils.ObjectProxy;

import org.springextensions.actionscript.module.BasicSASModule;

import spark.components.VGroup;

// todo: in flex 4.1 now extends mx:Module, later with flex 4.5 can use spark s:Module

//public class PodContentBase extends Module implements IPodContentBase
public class PodContentBase extends BasicSASModule implements IPodContentBase	
{
	private var _properties:XML; // Properties are from pods.xml.
	
	private var _pod:Pod;
	private var _podMgr:PodLayoutManager;
	
	
	function PodContentBase()
	{
		super();
		percentWidth = 100;
		percentHeight = 100;
		addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
	}
	
	// sreiner made protected instead of private
	protected function onCreationComplete(e:FlexEvent):void
	{
		// sreiner addded check for no properties, no dataSource
		if ( properties != null)
		{
			// Load the data source.
			var httpService:HTTPService = new HTTPService();
			httpService.url = properties.@dataSource;
			// sreiner addded check for no dataSource
			if (httpService.url != "")
			{
	    		httpService.resultFormat = "e4x";
	    		httpService.addEventListener(FaultEvent.FAULT, onFaultHttpService);
	    		httpService.addEventListener(ResultEvent.RESULT, onResultHttpService);
	    		httpService.send();
			}
		}
	}
	
	private function onFaultHttpService(e:FaultEvent):void
	{
		Alert.show("Unable to load datasource, " + properties.@dataSource + ".");
	}
	
	// abstract.
	protected function onResultHttpService(e:ResultEvent):void	{}
	
	// Converts XML attributes in an XMLList to an Array.
	protected function xmlListToObjectArray(xmlList:XMLList):Array
	{
		var a:Array = new Array();
		for each(var xml:XML in xmlList)
		{
			var attributes:XMLList = xml.attributes();
			var o:Object = new Object();
			for each (var attribute:XML in attributes)
			{
				var nodeName:String = attribute.name().toString();
				var value:*;
				if (nodeName == "date")
				{
					var date:Date = new Date();
					date.setTime(Number(attribute.toString()));
					value = date;
				}
				else
				{
					value = attribute.toString();
				}
					
				o[nodeName] = value;
			}
			
			a.push(new ObjectProxy(o));
		}
		
		return a;
	}
	
	// Dispatches an event when the ViewStack index changes, which triggers a state save.
	// ViewStacks are only in ChartContent and FormContent.
	protected function dispatchViewStackChange(newIndex:Number):void
	{
		dispatchEvent(new IndexChangedEvent(IndexChangedEvent.CHANGE, true, false, null, -1, newIndex));
	}

	[Bindable]
	public function get properties():XML
	{
		return _properties;
	}

	public function set properties(value:XML):void
	{
		_properties = value;
	}

	[Bindable]
	public function get pod():Pod
	{
		return _pod;
	}
	
	public function set pod(pod:Pod):void
	{
		_pod = pod;
	}

	[Bindable]
	public function get podManager():PodLayoutManager
	{
		return _podMgr;
	}
	
	public function set podManager(podMgr:PodLayoutManager):void
	{
		_podMgr = podMgr;
	}	
	
}
}