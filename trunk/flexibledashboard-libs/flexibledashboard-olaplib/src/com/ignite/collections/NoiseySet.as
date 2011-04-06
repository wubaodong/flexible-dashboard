package com.ignite.collections
{
	import com.ignite.olap.Element;
	
	
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
	

	public class NoiseySet extends NoiseyArrayCollection
	{
		public function NoiseySet()
		{
			super();
		}
		public override function addItem(item:Object):void{
			if (super.contains(item)){
				
			}else{
				super.addItem(item);	 
			}
		}
		public override function addItemAt(item:Object, index:int):void{
			if (super.contains(item)){
				
			}else{
				super.addItemAt(item,index);
			}
		}
	}
}