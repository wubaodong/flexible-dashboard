package com.ignite.olap.browser
{
import com.ignite.olap.Level;

import flash.events.EventDispatcher;

import mx.collections.ArrayCollection;
import mx.collections.ICollectionView;
import mx.collections.IHierarchicalData;
import mx.collections.ListCollectionView;
import mx.controls.advancedDataGridClasses.AdvancedDataGridColumn;
import mx.olap.IOLAPAttribute;
import mx.olap.IOLAPCube;
import mx.olap.IOLAPDimension;
import mx.olap.IOLAPHierarchy;
import mx.olap.IOLAPLevel;
import mx.olap.IOLAPMember;

public class CubeView extends EventDispatcher implements IHierarchicalData
{
	private var _includeMembers:Boolean;
    public function CubeView(source:ICollectionView,includeMemberLevel:Boolean=true)
    {
        super();
        this._includeMembers=includeMemberLevel;
        this.source = source;
        
    }
    private var source:ICollectionView;

    public function getChildren(node:Object):Object
    {
        if(!node)
            return source;
		var collection:ListCollectionView;
        try{
	        if(node is IOLAPCube)
	            collection = new ArrayCollection(node.dimensions.toArray());
	        else if(node is IOLAPDimension)
	            collection = new ArrayCollection(node.attributes.toArray().sort().concat(node.hierarchies.toArray().sort()));
	        else if(node is IOLAPAttribute)
	            collection = new ArrayCollection(getDummyObject(IOLAPHierarchy(node)).concat(node.levels.toArray().sort()));
	        else if (node is IOLAPHierarchy)
	        {
	        	
	            var array:Array = node.levels.toArray();
	            if (array.length>0)    collection = new ArrayCollection(array);
	        }
	        else if (node is IOLAPLevel){
	        	if (this._includeMembers){
		        	var members:ArrayCollection=node.members;
		             collection = members;
	         	}else{
	         		collection=new ArrayCollection();
	         	}
	     	 }
	        else if (node is IOLAPMember)
	        {
	            if(node.level.depth < node.hierarchy.levels.length)
	                collection = new ListCollectionView(node.children);
	        }
	        else if (node is Object && node.dummy && node.children && node.children.length>0)
	            collection = new ArrayCollection(node.children.sort());
        }catch(err:Error){}
        return collection;
    }

    private function cmpFunction(a:Object, b:Object):int
    {
        if(a is IOLAPLevel && b is IOLAPMember)
            return 1;
        else
            return a.displayName.localCompare(b.displayName);
    }

    public function hasChildren(node:Object):Boolean
    {
        if(!node)
        {
            // sreiner avoid warning
            //return source;
            Boolean(source);
        }
		//Ticket 38  Tree component display bug
		//Ticket 50 Get members go wonky
		//Ticket 39 Tree Questions
		//All nodes should not have children displayed in the browsing tree
		if ( (node is IOLAPMember)
			 || 
			  (node is IOLAPLevel && String(node.uniqueName).indexOf("[(All)]")>0)
		    ){
			return false;
		}
		if (node is IOLAPLevel && (Level(node).hasMembers())){
			return this._includeMembers;
		}
		//Tickets ^^^^^^^^^^^^^^^^^^^^^^^^^^^
		
		//Email Ticket - getting a null exception on line 93
		// As i sense that this logic will require a lot of various 
		// OLAP designs to fully flush I am wrapping
		// and letting an except help us determine if children are
		// acceptable.
        
        try{
	        if(node is IOLAPCube && node.dimensions.length > 0
	            ||node is IOLAPDimension && (node.hierarchies.length +node.attributes.length) > 0
	            || node is IOLAPHierarchy && node.levels.length > 0
	            || node is IOLAPMember && node.level.depth < node.hierarchy.levels.length)
	                return true;
	        else if (!(node is IOLAPCube || node is IOLAPDimension || node is IOLAPHierarchy || node is IOLAPLevel || node is IOLAPMember) && !(node is AdvancedDataGridColumn) && node is Object && node.children && node.children.length > 0)
	            return true;
        }catch(err:Error){}
        //^^^^^^^^^^^^^^^ email ticket
        return false;
    }

    public function canHaveChildren(node:Object):Boolean
    {
        if(!node)
        {   
            // sreiner avoid warning
            // return source;
            Boolean(source);            
        }
		try{
	        if(node is IOLAPCube
	            || node is IOLAPDimension 
	            || node is IOLAPHierarchy 
	            || node is IOLAPLevel 
	            || node is IOLAPMember && node.level.depth < node.hierarchy.levels.length
	            || !(node is AdvancedDataGridColumn) && node is Object && node.children)
	                return true;
        }catch(err:Error){}
        return false;

    }

    public function getParent(node:Object):*
    {
        if(!node)
            return source;

        if(node is IOLAPCube)
            return null;
        if(node is IOLAPDimension)
            return node.cube;
        else if(node is IOLAPAttribute)
            return node.dimension;
        else if (node is IOLAPHierarchy)
            return node.dimension;
        else if (node is IOLAPLevel)
            return node.hierarchy;
        else if (node is IOLAPMember)
        {
            if(node.level.depth >0)
                return node.parent;
            else
                return node.level;
        }
        return null;
    }
    public function getData(node:Object):Object
    {	
        if(node)
            return node.displayName;
        return null;
    }

    public function getRoot():Object
    {
        return source;
    }

    private function getDummyObject(node:IOLAPHierarchy):Array
    {
        try
        {
            var obj:Object = {name:"Members", children:[]};
            obj.children = [node.defaultMember];
            obj.dummy = true;
            return [obj];

        }
        catch(e:Error)
        {
            return  [];
        }
        return [];
    }


}
}
