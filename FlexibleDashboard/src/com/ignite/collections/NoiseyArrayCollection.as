package com.ignite.collections
{
	import mx.collections.ArrayCollection;

	//--------------------------------------
	//  Events
	//--------------------------------------
	
	/**
	*  Dispatched when an element is added or removed by key
	*  @eventType com.ignite.collections.CollectionEvent.CHANGED
	*/
	[Event(name="changed", type="com.ignite.collections.NoiseyCollectionEvent")]
	
	/**
	*  Dispatched when objects are removed by key
	*
	*  @eventType com.ignite.collections.CollectionEvent.REMOVED
	*/
	[Event (name="removed",type="com.ignite.collections.NoiseyCollectionEvent")]
	/**
	*  Dispatched when elements are added to the map
	*  
	*  @eventType com.ignite.collections.CollectionEvent.ADDED
	*/
	[Event (name="added",type="com.ignite.collections.NoiseyCollectionEvent")]
	
	public class NoiseyArrayCollection extends ArrayCollection
	{
		public function NoiseyArrayCollection(source:Array=null)
		{
			super(source);
		}
		public override function addItemAt(item:Object, index:int):void{
			super.addItemAt(item,index);
			dispatchEvent(new NoiseyCollectionEvent(NoiseyCollectionEvent.ADDITION));
			dispatchEvent(new NoiseyCollectionEvent(NoiseyCollectionEvent.CHANGED));
		}
		
		public override function addItem(item:Object):void{
			super.addItem(item);
			dispatchEvent(new NoiseyCollectionEvent(NoiseyCollectionEvent.ADDITION));
			dispatchEvent(new NoiseyCollectionEvent(NoiseyCollectionEvent.CHANGED,true));
		}
		
		public override function removeItemAt(index:int):Object{
			var rValue:Object=super.removeItemAt(index);
			dispatchEvent(new NoiseyCollectionEvent(NoiseyCollectionEvent.REMOVAL));
			dispatchEvent(new NoiseyCollectionEvent(NoiseyCollectionEvent.CHANGED));
			return rValue;
		}
		
		public override function removeAll():void{
			super.removeAll();
			dispatchEvent(new NoiseyCollectionEvent(NoiseyCollectionEvent.REMOVAL));
			dispatchEvent(new NoiseyCollectionEvent(NoiseyCollectionEvent.CHANGED));
		}
		
	}
}