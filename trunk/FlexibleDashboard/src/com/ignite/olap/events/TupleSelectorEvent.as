package com.ignite.olap.events
{
	import flash.events.Event;

	public class TupleSelectorEvent extends Event
	{
		public static const CHANGED:String="selector_changed";
		public static const REMOVED:String="selector_removed";
		
		public function TupleSelectorEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}