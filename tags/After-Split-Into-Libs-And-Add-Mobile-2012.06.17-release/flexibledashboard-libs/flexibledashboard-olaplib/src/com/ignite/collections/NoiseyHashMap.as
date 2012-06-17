package com.ignite.collections
{
	import de.polygonal.ds.HashMap;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;

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
	
	public class NoiseyHashMap extends HashMap implements IEventDispatcher 
	{
		
		
		
		public function NoiseyHashMap(size:int=500)
		{
			     dispatcher = new EventDispatcher(this);
	   			super(size);
		}
	 
		public override function insert(key:*, obj:*):Boolean{
			var rValue:Boolean=super.insert(key,obj);
			if (!silent){
				fireAdd();
				fireChange();
			}
			return rValue
		}
		public override function remove(key:*):*{
			var rValue:*=super.remove(key);
			if (!(rValue == null)){
				if (!silent){
					fireChange();
					fireRemove();
				}
			}
			return rValue;
		}
		public function silentClear():void{
			if (this.silent==false) this.silent=true;
			
			super.clear();
			this.silent=false;
		}
		//8/14/08
		//a silence events for when code needs to perform multiple changes
		//b for external code to explicitly fire off an even
		//  useful for when silent but need to initiate a change based event
		public var silent:Boolean=false;
		
		public function fireChange():void{
			dispatchEvent(new NoiseyCollectionEvent(NoiseyCollectionEvent.CHANGED));
		}
		public function fireRemove():void{
			dispatchEvent(new NoiseyCollectionEvent(NoiseyCollectionEvent.REMOVAL));
		}
		public function fireAdd():void{
				dispatchEvent(new NoiseyCollectionEvent(NoiseyCollectionEvent.ADDITION));
			
		}
		//8/14/08 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		//-----------------------------------------------------------------
		// IEventDispatcher Methods
		//-----------------------------------------------------------------
		private var dispatcher:EventDispatcher;
        
	    public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void{
	        dispatcher.addEventListener(type, listener, useCapture, priority);
	    }
	           
	    public function dispatchEvent(evt:Event):Boolean{
	        return dispatcher.dispatchEvent(evt);
	    }
	    
	    public function hasEventListener(type:String):Boolean{
	        return dispatcher.hasEventListener(type);
	    }
	    
	    public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void{
	        dispatcher.removeEventListener(type, listener, useCapture);
	    }
	                   
	    public function willTrigger(type:String):Boolean {
	        return dispatcher.willTrigger(type);
	    }

		
	}
}