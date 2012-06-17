package com.ignite.olap
{
import com.ignite.olap.factory.CubeFactory;
import com.ignite.olap.factory.MemberFactory;

import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.collections.IList;
import mx.olap.IOLAPHierarchy;
import mx.olap.IOLAPLevel;

public class Level extends Element
    implements IOLAPLevel
{
    public function Level(name:String, uniqueName:String)
    {
        super(name, uniqueName);
        _members = new ArrayCollection;
    }


    private var _depth:int = 0;
    public function set depth(value:int):void
    {
        _depth = value
    }
    public function get depth():int
    {
        return _depth
    }
    private var _hierarchy:IOLAPHierarchy;
    public function get hierarchy():IOLAPHierarchy
    {
        return _hierarchy;
    }

    public function set hierarchy(value:IOLAPHierarchy):void
    {
        _hierarchy = value;
    }
    private var _parent:IOLAPLevel
    public function get parent():IOLAPLevel
    {
        return _parent;
    }
    public function set parent(p:IOLAPLevel):void
    {
        _parent = p;
    }

    private var _members:IList = new ArrayCollection;
    private var _memberNameMap:Dictionary = new Dictionary(false);
    public var _needsMemberPopulation:Boolean=true;
    public function get members():IList
    {
    	if (_members.length<=1 && _needsMemberPopulation)
    	{
    			removeDummyMembers();
    			var mf:MemberFactory=new MemberFactory(this);
    			_needsMemberPopulation=false;
    	}
        return _members;
    }
    public function removeDummyMembers():void{
    		////remove the dummy object ticket #35
        	try{
        		if (ArrayCollection(_members).length==1)
	    		{
		    		if (Member(_members[0]).uniqueName==CubeFactory.HAS_MEMBERS_PLACEHOLDER.uniqueName){
		    			_members.removeItemAt(0);
		    		}
	    		}	
        	}catch(err:Error){}
        	//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^remove the dummy object ticket #35
    }
    
    public function hasMembers():Boolean{
    	return (_members && _members.length>0);
    }
    
    public function addMember(m:Member):void
    {
    	
	    	if (m.uniqueName!=CubeFactory.HAS_MEMBERS_PLACEHOLDER.uniqueName){
	    		   if (_needsMemberPopulation)removeDummyMembers(); //first time so remove
	    		    _needsMemberPopulation=false;
	        }
	        _members.addItem(m);
			m.level = this;
	        m.dimension = this.dimension;
	        if(!_memberNameMap[m.name])
	            _memberNameMap[m.name] = new ArrayCollection;
	        _memberNameMap[m.name].addItem(m);
	   
    }
    public function findMember(name:String):IList
    {
    	var cleanName:String=name.replace("]","");
    	cleanName=cleanName.replace("[","");
    	
    	var rValue:IList=_memberNameMap[cleanName];
    	if (rValue==null){
    		//check unique names
    		for each (var m:Member in _members){
    			if (m.uniqueName==name){
    				rValue=_memberNameMap[m.name];
    			}
    		}
    	}
    	return rValue;
    }

    public function refresh():void
    {
    }
    public function get child():IOLAPLevel
    {
        if(depth < hierarchy.levels.length - 2)
            return hierarchy.levels[depth+1];
        return null;
    }

    public function get dataField():String
    {
        return null;
    }

}
}
