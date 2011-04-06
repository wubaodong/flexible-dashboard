package com.ignite.olap
{
	import mx.olap.IOLAPElement;
import mx.olap.IOLAPAxisPosition;
import mx.collections.IList;
import mx.collections.ArrayCollection;

public class Tuple implements IOLAPAxisPosition
{
    private var _members:IList = new ArrayCollection;
	public function addMember(member:IOLAPElement):void
    {
        _members.addItem(member);
    }

	/**
	 *  Add a list of members to the tuple. 
	 *  This can be called when many members need to be added to the tuple.
	 *
	 *  @param value The members to add, as a list of IOLAPMember instances. 
	 */
	public function addMembers(value:IList):void
    {
        _members = new ArrayCollection(_members.toArray().concat(value.toArray()));
    }

	/**
	 * The members of this tuple as a list of IOLAPMember instances.
	 */
	public function get members():IList
    {
        return _members;
    }
    
}
}