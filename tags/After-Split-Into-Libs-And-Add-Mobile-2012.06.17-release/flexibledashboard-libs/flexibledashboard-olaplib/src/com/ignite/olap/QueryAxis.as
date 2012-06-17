package com.ignite.olap
{
	import mx.collections.ArrayCollection;
	import mx.olap.IOLAPMember;
	import mx.olap.IOLAPQueryAxis;
	import mx.olap.IOLAPSet;
	import mx.olap.IOLAPTuple;
	import mx.olap.OLAPSet;

	public class QueryAxis implements IOLAPQueryAxis
	{
		public function QueryAxis()
		{
		}
		private var _sets:ArrayCollection=new ArrayCollection();
		public function addSet(s:IOLAPSet):void
		{
			_sets.addItem(s);
		}
		
		private var _tuples:ArrayCollection=new ArrayCollection();
		public function addTuple(t:IOLAPTuple):void
		{
			_tuples.addItem(t);
		}
		
		public function addMember(s:IOLAPMember):void
		{
			var nt:Tuple=new Tuple();
			nt.addMember(s);
			this.addTuple(IOLAPTuple(nt));
		}
		
		public function get tuples():Array
		{
			return _tuples.toArray();
		}
		
		public function get sets():Array
		{
			return _sets.toArray();
		}
		
	}
}