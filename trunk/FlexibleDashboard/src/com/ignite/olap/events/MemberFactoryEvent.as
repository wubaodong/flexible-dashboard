package com.ignite.olap.events
{
	import flash.events.Event;

	public class MemberFactoryEvent extends Event
	{
		public static var COMPLETE:String="memberscomplete";
		public function MemberFactoryEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}