package com.esria.samples.dashboard.view
{
	import mx.core.IVisualElement;

	public interface IPodContentBase extends IVisualElement
	{
		function get properties():XML;
		
		function set properties(value:XML):void;
	
	}
}