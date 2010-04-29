package com.ignite.collections
{
	import flash.events.Event;

	public class NoiseyCollectionEvent extends Event
	{
		public static const CHANGED:String="changed";
		public static const REMOVAL:String="removed";
		public static const ADDITION:String="added";
		
		public function NoiseyCollectionEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}