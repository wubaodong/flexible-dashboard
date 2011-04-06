package  com.ignite.olap.dto
{
	import flash.utils.Timer;
	
	
	public class RequestDTO
	{
		public var packet:XML;
		public var requestor:*;
		public var createTime:int;
		public var uid:Number;
		public function RequestDTO(packet:XML,requestor:*):void{
			this.packet=packet;
			this.requestor=requestor;
			createTime=new Date().time;
			uid=Math.random()+Math.random();
		}
	}
}