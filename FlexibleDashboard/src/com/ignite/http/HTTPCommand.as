package com.ignite.http
{
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.http.HTTPService;
	
	public class HTTPCommand implements Command
	{
		private var _service:HTTPService;
		private var _req:*;
		private var _result:Function;
		private var _fault:Function;
		
		public function HTTPCommand(httpService:HTTPService,
									request:*,
									resultHandler:Function,
									faultHandler:Function)
		{
			_service=httpService;
			_req=request;
			_result=resultHandler;
			_fault=faultHandler;
		}
		
		public function send():void
		{
			  var token:AsyncToken = _service.send();		
			  			
	       		//token.dto=new RequestDTO(XML(_httpService.request),_cube);						
				token.addResponder(new AsyncResponder(_result, _fault));
		}
		
	}
}