package org.integratedsemantics.flexibledashboard.data
{
	import mx.controls.Alert;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;

	public class XmlDataService implements IDataService
	{
		private var httpService:HTTPService;
		
		public function XmlDataService(service:HTTPService)
		{		
			httpService = service;			
		}
		
		public function getData():AsyncToken
		{
			var token:AsyncToken;
			token = httpService.send();
			token.addResponder(new AsyncResponder(resultHandler, faultHandler));			
			return token;
		}
		
		private function resultHandler(event:ResultEvent, token:AsyncToken=null):void 
		{
			var event2:ResultEvent = new ResultEvent(ResultEvent.RESULT, false, true, event.result.catalog.product);
			event.token.dispatchEvent(event2);
		}		
		
		private function faultHandler(event:FaultEvent, token:AsyncToken=null):void
		{
			Alert.show(event.fault.faultString + "\n" + event.fault.faultDetail, "SoapDataService getData: error invoking WebService");
		}		
		
	}
}