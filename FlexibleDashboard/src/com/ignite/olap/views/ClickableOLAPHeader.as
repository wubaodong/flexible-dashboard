package com.ignite.olap.views
{
	import flash.events.MouseEvent;
	
	import mx.controls.olapDataGridClasses.OLAPDataGridHeaderRenderer;

	public class ClickableOLAPHeader extends OLAPDataGridHeaderRenderer
	{
		public function ClickableOLAPHeader()
		{
			super();
			var i:int=0;
			super.addEventListener(MouseEvent.CLICK,doIt);
		}
		private function doIt(event:Object):void{
			var x:int=32;
		}
		protected override function measure():void{
			super.measure();
		}
	}
}