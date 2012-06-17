// ActionScript file
package com.ignite.olap.grid
{
import flash.events.Event;

import mx.collections.ArrayCollection;
import mx.controls.DataGrid;
import mx.controls.OLAPDataGrid;
import mx.core.mx_internal;
import mx.olap.OLAPAxisPosition;
import mx.olap.OLAPHierarchy;
import mx.olap.OLAPLevel;
import mx.olap.OLAPMember;
import mx.olap.OLAPResult;
import mx.olap.OLAPResultAxis;
use namespace mx_internal;
//--------------------------------------
//  Events
//--------------------------------------


[Event (name="removeSlicer", type="flash.events.Event")]
[Event (name="updateSlicerBox", type="flash.events.Event")]
[Event (name="collectionChange", type="flash.events.Event")]

 public class PivotOLAPGrid extends OLAPDataGrid
		{

		
		// flex4spark changed from "collectionChange" to "collectionChangeCustom" to avoid 
	    // conflict with CollectionEvent
		public static var EVENT_COLLECTION_CHANGE:String="collectionChangeCustom";
		public static var EVENT_NEWCOLUMNS_LOADED:String="newcolumnsLoaded";
				
		public function PivotOLAPGrid():void
		{
			super();
			//super.headerRenderer=new ClassFactory(com.ignite.olap.grid.CheckboxHeaderRenderer);
			super.sortExpertMode=false;
		}
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void{
			try{
				super.updateDisplayList(unscaledWidth,unscaledHeight);
			}catch(err:Error){
				trace (err.message);
				
			}
		}
	private var _newColumnData:Boolean=false;
	override protected function collectionChangeHandler(event:Event):void{
		_newColumnData=true;
		super.collectionChangeHandler(event);
		var even:Event=new Event(EVENT_COLLECTION_CHANGE,true,false);
		dispatchEvent(even);
	}
	 
	override public function validateDisplayList():void{
		super.validateDisplayList();
		if (_newColumnData){
			var even:Event=new Event(EVENT_NEWCOLUMNS_LOADED,true,false);
			dispatchEvent(even);
		}
		_newColumnData=false;
	}
	override protected function commitProperties():void
    {
		try{
				super.commitProperties();
		} catch(err:Error){
			
		}
	} 
		
		/**
		 * @private
		 * clear the datagrid to a default view
		 */
		public function clear():void
		{
			//super.commitProperties();
			invalidateDisplayList();
	        this.defaultCellString = " ";
	        super.dataProvider = null;
	   	}
		/**
		 * @private 
		 * build a empty, placeholder OLAPResult and give it 
		 * to the OlapDataGrid
		 */ 
		private function getEmptyData():OLAPResult
		{
			var olapResult:OLAPResult =  new OLAPResult();
			var axi:Array=new Array(2);
		    for( var i:int = 0; i < 2; i++)
	        {	
	        	var p:OLAPAxisPosition; 
	        	var m:OLAPMember;
	        	var k:int;
				var resultAxis:OLAPResultAxis = new OLAPResultAxis;
	       		//First create levels in a hierarchy
	            var childLevel:OLAPLevel = new OLAPLevel;
		        var h:OLAPHierarchy = new OLAPHierarchy(" ", " ");
	     	    h.levels = new ArrayCollection([childLevel]);
			    
				p = new OLAPAxisPosition;
	            m = new OLAPMember(" " , " " );
	            m.level = childLevel;
	            p.addMember(m);
	            resultAxis.addPosition(p);
	            olapResult.setAxis(i, resultAxis);
			}
				
			return olapResult;
		}
		
	  	
   }
}