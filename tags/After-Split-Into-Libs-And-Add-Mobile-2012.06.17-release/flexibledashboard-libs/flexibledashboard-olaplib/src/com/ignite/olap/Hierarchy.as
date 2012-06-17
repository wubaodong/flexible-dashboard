package com.ignite.olap
{
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.collections.IList;
import mx.olap.IOLAPHierarchy;
import mx.olap.IOLAPLevel;
import mx.olap.IOLAPMember;

public class Hierarchy extends Element
    implements IOLAPHierarchy
{
    public function Hierarchy(name:String, uniqueName:String)
    {
        super(name, uniqueName);
    }
    private var _allMemberName:String
    public function get allMemberName():String
    {
        return _allMemberName;
    }

    public function set allMemberName(value:String):void
    {
        _allMemberName = value;
    }

    private var _levels:IList;
    private var _levelNameMap:Dictionary = new Dictionary(false);
    public function get levels():IList
    {
        return _levels;
    }
    public function addLevel(l:Level):void
    {
        if(!_levels)
        {
            _levels = new ArrayCollection;
            l.parent = null;
        }
        else
            l.parent = Level(_levels.getItemAt(_levels.length-1));

        l.depth = _levels.length;

        _levels.addItem(l);

        l.hierarchy = this;
        l.dimension = this.dimension;
        _levelNameMap[l.name] = l;
    }

    public function findLevel(name:String):IOLAPLevel
    {
        var rValue:IOLAPLevel;
        var cleanName:String=name.replace("]","");
    	cleanName=cleanName.replace("[","");
    	
        if(_levelNameMap && _levelNameMap[cleanName])
            rValue= _levelNameMap[cleanName];
            
        if (rValue==null){
	      		//check unique names
	    		for each (var l:Level in _levelNameMap){
	    			if (l.uniqueName==name){
	    				rValue=_levelNameMap[l.name];
	    			}
	    		}
    	}
    	return rValue;
    }

    public function get children():IList
    {
        return null;
    }

    private var _defaultMember:String
    public function get defaultMember():IOLAPMember
    {
        return this.findMember(_defaultMember);
    }
    public function setDefaultMember(value:String):void
    {
        _defaultMember = value;
    }

    public function findMember(name:String):IOLAPMember
    {
        if(levels)
        {
            for ( var i:int = 0; i < levels.length; i++)
            {
                var list:IList = levels[i].findMember(name);
                if(list && list.length)
                    return list[0];
            }
        }
        return null;
    }

    public function get hasAll():Boolean
    {
        return allMemberName!=null;
    }

    public function get members():IList
    {

        var temp:Array = [];
        if (hasAll)
        {
            //TODO optimize by caching?
            // add the all member then add children of each member up to the leaf level.
            var allMember:IOLAPMember = findMember(_allMemberName) as IOLAPMember;
            temp.push(allMember);
            temp = temp.concat(getMembersRecursively(allMember));
            return new ArrayCollection(temp);       
        }
        else
        {
            //TODO handle the case when all member is not present. Is this correct?
            for (var levelIndex:int = 0; levelIndex < levels.length; ++levelIndex)
            {
                var level:Level = levels.getItemAt(levelIndex) as Level;
                temp = temp.concat(level.members.toArray());
            }
        }
        return new ArrayCollection(temp);
    }

    private function getMembersRecursively(m:IOLAPMember):Array
    {
        var temp:Array = [];
        try{
        var children:IList = m.children;
        for (var index:int = 0; index < children.length; ++index)
        {
            var member:IOLAPMember = children.getItemAt(index) as IOLAPMember;
            temp.push(member);
            if (member.children.length)
            {
                var members:Array = getMembersRecursively(member);
                temp = temp.concat(members);
            }
        }
        }catch(err:Error){
        	
        }
        return temp;
    }

    public function refresh():void
    {
    }

}
}
