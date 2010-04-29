package com.ignite.olap
{
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.collections.IList;
import mx.olap.IOLAPAttribute;
import mx.olap.IOLAPCube;
import mx.olap.IOLAPDimension;
import mx.olap.IOLAPHierarchy;
import mx.olap.IOLAPMember;

public class Dimension extends Element
    implements IOLAPDimension
{

    public function Dimension(name:String, uniqueName:String)
    {
        super(name, uniqueName);
        this.dimension = this;
    }

    private var _cube:IOLAPCube;
    public function set cube(value:IOLAPCube):void
    {
        this._cube = value;
    }
    public function get cube():IOLAPCube
    {
        return _cube;
    }

    public function get defaultMember():IOLAPMember
    {
        if(hierarchies && hierarchies.length == 1)
            hierarchies[0].defaultMember;
        return null;
    }
    private var _hierarchies:IList = new ArrayCollection;;
    private var _hierarchyNameMap:Dictionary = new Dictionary(false);
    public function get hierarchies():IList
    {
        return _hierarchies;
    }
    public function addHierarchy(h:Hierarchy):void
    {
        _hierarchies.addItem(h);
        h.dimension = this;
        _hierarchyNameMap[h.name] = h;

    }
    public function findHierarchy(name:String):IOLAPHierarchy
    {
    	var rValue:IOLAPHierarchy;
        var cleanName:String=name.replace("]","");
    	cleanName=cleanName.replace("[","");
    	
        if(_hierarchyNameMap && _hierarchyNameMap[cleanName])
            rValue= _hierarchyNameMap[cleanName];
            
        if (rValue==null){
	      		//check unique names
	    		for each (var h:Hierarchy in _hierarchyNameMap){
	    			if (h.uniqueName==name){
	    				rValue=_hierarchyNameMap[h.name];
	    			}
	    		}
    	}
    	return rValue;
    }
    private var _attributes:IList = new ArrayCollection;
    private var _attributeNameMap:Dictionary = new Dictionary(false);
    public function get attributes():IList
    {
        return _attributes;
    }
    public function addAttribute(a:AttributeHierarchy):void
    {
        _attributes.addItem(a);
        a.dimension = this;
        _attributeNameMap[a.name] = a;
    }


    public function findAttribute(name:String):IOLAPAttribute
    {
        if(_attributeNameMap && _attributeNameMap[name])
            return _attributeNameMap[name]
        return null;
    }

    public function get members():IList
    {
        var temp:Array = [];

        for (var hIndex:int = 0; hIndex < hierarchies.length; ++hIndex)
            temp = temp.concat(hierarchies.getItemAt(hIndex).members.toArray());

        return new ArrayCollection(temp);
    }

    public function refresh():void
    {
    }
    private var _isMeasure:Boolean = false;
    public function set isMeasure(value:Boolean):void
    {
        _isMeasure = value;
    }
    public function get isMeasure():Boolean
    {
        return _isMeasure;
    }

    public function findMember(name:String):IOLAPMember
    {
        var member:IOLAPMember;
        var hIndex:int = 0;
        var h:Hierarchy;

        for (hIndex = 0; hIndex < attributes.length; ++hIndex)
        {
            h = attributes.getItemAt(hIndex) as Hierarchy;
            member = h.findMember(name);
            if (member)
                break;
        }

        if (!member)
        {
            for (hIndex = 0; hIndex < hierarchies.length; ++hIndex)
            {
                h = hierarchies.getItemAt(hIndex) as Hierarchy;
                member = h.findMember(name);
                if (member)
                    break;
            }
        }

        return member;          
    }

}
}
