package com.ignite.olap
{
import mx.collections.ArrayCollection;
import mx.collections.IList;
import mx.olap.IOLAPHierarchy;
import mx.olap.IOLAPLevel;
import mx.olap.IOLAPMember;

public class Member extends Element
    implements IOLAPMember
{
	public static  const  MDMEMBER_TYPE_REGULAR:int=1;
	public static const  MDMEMBER_TYPE_ALL:int=2;
	public static const  MDMEMBER_TYPE_MEASURE:int=3;
	public static const  MDMEMBER_TYPE_FORMULA:int=4;
	public static const  MDMEMBER_TYPE_UNKNOWN:int=0;
	
	public var _type:int=0;
	
    public function Member(name:String, uniqueName:String,type:int=0)
    {
        super(name, uniqueName);
        this._type=type;
    }
    private var _children:ArrayCollection = new ArrayCollection([]);
    public function get children():IList
    {
        return _children;
    }

    public function findChildMember(name:String):IOLAPMember
    {
        for( var i:int = 0; i < children.length; i++)
            if(children[i].name == name)
                return children [i];

        return null;
    }

    public function get hierarchy():IOLAPHierarchy
    {
        return level.hierarchy;
    }

    public function get isAll():Boolean
    {
    	if (_type==MDMEMBER_TYPE_ALL) return true;
        if(name == hierarchy.allMemberName)
            return true;
        return false;
    }

    public function get isMeasure():Boolean
    {
    	if (_type==MDMEMBER_TYPE_MEASURE) return true;
        return dimension.isMeasure;
    }

    private var _level:IOLAPLevel;
    public function get level():IOLAPLevel
    {
        return _level;
    }

    public function set level(l:IOLAPLevel):void
    {
        _level = l;
    }
    private var _parent:IOLAPMember
    public function set parent(p:IOLAPMember):void
    {
        _parent = p;
        if(p)
            p.children.addItem(this);
    }
    public function get parent():IOLAPMember
    {
        return _parent;
    }

}
}
