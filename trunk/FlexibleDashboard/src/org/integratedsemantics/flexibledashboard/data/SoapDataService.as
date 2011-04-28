package org.integratedsemantics.flexibledashboard.data
{
	import mx.controls.Alert;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.soap.WebService;

	public class SoapDataService implements IDataService
	{
		private var webService:WebService;

		public function SoapDataService(service:WebService)
		{			
			webService = service;
			
			if (webService != null)
			{
				webService.loadWSDL();
			}
		}
		
		public function getData():AsyncToken
		{
			var token:AsyncToken;
			token = webService.getCategories();
			token.addResponder(new AsyncResponder(resultHandler, faultHandler));			
			return token;
		}
		
		private function resultHandler(event:ResultEvent, token:AsyncToken=null):void 
		{
			event.token.dispatchEvent(event);
		}		
		
		private function faultHandler(event:FaultEvent, token:AsyncToken=null):void
		{
			Alert.show(event.fault.faultString + "\n" + event.fault.faultDetail, "SoapDataService getData: error invoking WebService");
		}		
		
	}
}