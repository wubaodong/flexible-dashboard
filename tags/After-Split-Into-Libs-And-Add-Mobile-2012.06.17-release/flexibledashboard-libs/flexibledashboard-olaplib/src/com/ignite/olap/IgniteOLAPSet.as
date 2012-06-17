package com.ignite.olap
{
	import mx.collections.ArrayCollection;
	import mx.olap.IOLAPElement;
	import mx.olap.OLAPSet;

	public class IgniteOLAPSet extends OLAPSet
	{
		public function IgniteOLAPSet()
		{
			super();
		}
		public var _elements:ArrayCollection=new ArrayCollection();
		public override function addElement(e:IOLAPElement):void{
			super.addElement(e);
			_elements.addItem(e);
		}
		
	}
}