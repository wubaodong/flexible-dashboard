package com.ignite.olap
{
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.olap.*;
	
	public class ElementsDelegate
	{ 
		public function ElementsDelegate()
		{
			
		}
		public static function directlyRelated(e1:Element,e2:Element):Boolean{
			var rValue:Boolean=false;
			try{
				rValue= (e1.uniqueName.indexOf(e2.name)>-1) || 
					    (e2.uniqueName.indexOf(e1.name)>-1) ||
					    (e1.uniqueName==e2.uniqueName);
			
			}catch(err:Error){}
			
			return rValue;
		}
		public static function getMatches(testE:Element,knownE:Element):int{
			var rValue:int=0;
			//cases:   store.country.usa  , store.country   - true    3     2/3
			//		   store.country      , store			- true    3     1/2
			//		   store.country.usa  , store           - true    4     1/3
			//		   store.size		  , store.country   - false   1     1/2
			//		   store.country      , store.country   - false   0     2/2
			//         promotion          , store			- false   -1    0/1
			//         store			  , store.country   -         2     1/1
			//         store.state		  , store.state.ne            2     2/2
			//         store              , store.state.ne            2     1/1
			//         store.state.ne     , store.state.ne.omaha      2     3/3
			//		   store.state.ia     , store.state.ne.omaha      5     2/3
			if (directlyRelated(testE,knownE)){
					try{
						var testELevels:Array=testE.uniqueName.split(".");
						var knownELevels:Array=knownE.uniqueName.split(".");
						var numMatches:int=0;
						for (var cnt:int=0;cnt<testELevels.length;cnt++){
							var testLevel:String=testELevels[cnt];
							for (var knownCnt:int=0;knownCnt<knownELevels.length;knownCnt++){
								var knownLevel:String=knownELevels[knownCnt];
								if (testLevel==knownLevel){
									numMatches++;
								}
							}
						}
						rValue= numMatches;
					}catch(err:Error){
						rValue= 0;
					}
			}else{
				rValue= 0;
			}
			return rValue;
		}
		public static function getHasAllTuple(node:Dimension):String{
			var rValue:String=node.uniqueName;
			for each(var hier:Hierarchy in node.hierarchies){
				if (hier.hasAll){
					 return hier.allMemberName;
				}
			}
			return rValue;
		}
		public static function impliedLevel(uniqueName:String):int{
			//basically just count the "." in the uniquename to get
			//an idea of the level
			var rValue:int=uniqueName.split(".").length;
			return rValue;
		}
		public static function populateTuples(nodeList:IList):ArrayCollection{
			var rValue:ArrayCollection=new ArrayCollection();
			
			for (var j:int=0;j<nodeList.length;j++){
				try{
					var mem:Object=nodeList[j];
					
					var newTuple:Tuple=new Tuple();
					var newMem:Member=new Member(mem.name,mem.uniqueName);
					if (mem.allMemberName){
						newMem=new Member(mem.allMemberName,mem.allMemberName);	
					}
					newTuple.addMember(newMem);
					rValue.addItem(newTuple);
				}catch(err:Error){}
			}
			
			return rValue;
		}
	
		public static function hasChildren(node:Object):Boolean
	    {if (node is IOLAPMember){
	    		if ((Member(node)._type==Member.MDMEMBER_TYPE_ALL) || 
	    				(node.level.depth < node.hierarchy.levels.length)){
	    			return true;
	    		}else{
	    			return false;
	    		}
	    	}
	        if(node is IOLAPCube && node.dimensions.length > 0
	            ||node is IOLAPDimension && (node.hierarchies.length +node.attributes.length) > 0
	            || node is IOLAPHierarchy && node.levels.length > 0
	            || node is IOLAPLevel && (Level(node).hasMembers())
	            )
	                return true;
	        else if (!(node is IOLAPCube || node is IOLAPDimension 
	        || node is IOLAPHierarchy || node is IOLAPLevel || node is IOLAPMember)
	         &&  node is Object && node.children && node.children.length > 0)
	            return true;
	        return false;
	    }
		public static function canHaveChildren(node:Object):Boolean
	    {
	        if(!node)
	            return false;
	
	        if(node is IOLAPCube
	            || node is IOLAPDimension 
	            || node is IOLAPHierarchy 
	            || node is IOLAPLevel 
	            || node is IOLAPMember && node.level.depth < node.hierarchy.levels.length
	            || node is Object && node.children)
	                return true;
	             
	        return false;
	
	    }
		
		public static function getChildrenTuples(node:Object):IList{
			var rValue:IList=new ArrayCollection();
				
				if (node is Dimension){
					var dim:Dimension=node as Dimension;
					if(dim.hierarchies && dim.hierarchies.length>0){
							rValue=dim.hierarchies;
					}else{
							rValue=dim.members;
					}
				}else if (node is Cube){
					rValue=Cube(node).dimensions;
				}
				else if (node is Catalog){
				
					var newTupleC:Tuple=new Tuple;
					var newMemC:Member=new Member("Catalog","Catalog");
					newTupleC.addMember(newMemC);
					rValue.addItem(newTupleC);
				
				}else if (node is Hierarchy){
					var h:Hierarchy=Hierarchy(node);
					//TICKET 64
					if (h.levels.length==1){
						if (h.defaultMember){
						//use the level of the default member to get
						//all other members\
							rValue=h.defaultMember.level.members;
						}else{
							rValue=Level(h.levels[0]).members;
						}
					}else{
						if (Hierarchy(node).levels && 
							Hierarchy(node).levels.length>=1){
							rValue=Hierarchy(node).levels;
						}else{
							rValue=Hierarchy(node).members;
						}
					}
				}
				else if (node is Level){
					rValue=Level(node).members;
				}
				else if (node is Element){
					
					var newTuple:Tuple=new Tuple();
					var newMem:Member=new Member(Element(node).name,Element(node).uniqueName);
					
					rValue.addItem(newTuple);
				}
			return rValue;
		}
	}
}