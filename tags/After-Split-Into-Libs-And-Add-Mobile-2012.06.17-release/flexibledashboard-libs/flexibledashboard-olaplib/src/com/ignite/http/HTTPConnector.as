package com.ignite.http
{
	import de.polygonal.ds.ArrayedQueue;
	
	import flash.utils.setTimeout;
	
	import mx.rpc.http.HTTPService;
	
	public class HTTPConnector  //Invoker in Command Pattern 
								//http://en.wikipedia.org/wiki/Command_pattern
	{
		private var _httpService:HTTPService;
	  	
	  	private var _requestsStack:ArrayedQueue;
  
  		private var _timeOutThreshold:int; //the size of the queue when processing stops
  											  //for a time
  		private var _counter:int=0;
  		
		public function HTTPConnector(service:HTTPService,sizeTillTimeout:int=20,queueSize:int=150):void
		{
			_timeOutThreshold=sizeTillTimeout;
			_requestsStack=new ArrayedQueue(queueSize);
		}
				
		public function process(requestPacket:*,service:HTTPService,result:Function,fault:Function):void{
			var cmd:HTTPCommand=new HTTPCommand(service,requestPacket,result,fault);
			_requestsStack.enqueue(cmd);
			_counter++;
			if (_counter<_timeOutThreshold){
				HTTPService(_requestsStack.dequeue()).send();
			}else{
				flash.utils.setTimeout(reset,18000);
			}
		}
		private function reset():void{
			_counter=0;
		}
	}
}