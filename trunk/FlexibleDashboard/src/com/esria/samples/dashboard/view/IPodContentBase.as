package com.esria.samples.dashboard.view
{
	import com.esria.samples.dashboard.managers.PodLayoutManager;
	
	import mx.core.IVisualElement;

	public interface IPodContentBase extends IVisualElement
	{
		function get properties():XML;
		
		function set properties(value:XML):void;

		function get pod():Pod;
		
		function set pod(value:Pod):void;

		function get podManager():PodLayoutManager;
		
		function set podManager(value:PodLayoutManager):void;
		
	}
}