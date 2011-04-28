package org.integratedsemantics.flexibledashboard.data
{
	import mx.controls.Alert;
	import mx.messaging.ChannelSet;
	import mx.messaging.channels.AMFChannel;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.RemoteObject;

	public class RemoteObjectDataService implements IDataService
	{
		private var remoteObject:RemoteObject;

		public function RemoteObjectDataService(remoteObject:RemoteObject)
		{			
			this.remoteObject = remoteObject;			
		}
		
		public function getData():AsyncToken
		{
			var token:AsyncToken;
			token = remoteObject.getProducts();
			token.addResponder(new AsyncResponder(resultHandler, faultHandler));			
			return token;
		}
		
		private function resultHandler(event:ResultEvent, token:AsyncToken=null):void 
		{
			event.token.dispatchEvent(event);
		}		
		
		private function faultHandler(event:FaultEvent, token:AsyncToken=null):void
		{
			Alert.show(event.fault.faultString + "\n" + event.fault.faultDetail, "RemoteObjectDataService getData: error invoking RemoteObject");
		}
				
	}
}