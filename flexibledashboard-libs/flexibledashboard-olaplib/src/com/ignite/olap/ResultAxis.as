package com.ignite.olap
{
	import mx.olap.IOLAPResultAxis;
	import mx.olap.IOLAPTuple;
	import mx.collections.IList;
	import mx.collections.ArrayCollection;
	import mx.olap.IOLAPAxisPosition;

	public class ResultAxis implements IOLAPResultAxis
	{
	    private var _positions:IList = new ArrayCollection;
	    public function get positions():IList
	    {
	        return _positions;
	    }
	    public function addTuple(tuple:IOLAPAxisPosition):void
	    {
	        _positions.addItem(tuple);
	    }
	}
}