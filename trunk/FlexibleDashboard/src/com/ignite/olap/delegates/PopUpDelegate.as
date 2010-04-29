package com.ignite.olap.delegates
{
	import com.ignite.olap.Cube;
	import com.ignite.olap.Dimension;
	import com.ignite.olap.Element;
	import com.ignite.olap.ElementsDelegate;
	import com.ignite.olap.Member;
	import com.ignite.olap.Tuple;
	import com.ignite.olap.controls.TuplePopUp;
	import com.igniteanalytics.logging.ASLogger;
	
	import de.polygonal.ds.HashMap;
	
	import mx.collections.ArrayCollection;
	import mx.olap.IOLAPResult;
	import mx.olap.IOLAPResultAxis;
	import mx.olap.OLAPQuery;
	
	public class PopUpDelegate
	{
		
		public var logger:ASLogger=new ASLogger("com.ignite.olap.delegates.PopUpDelegate");

		//how wide should the selectors be
		public var _rowSelectorWidth:int=20;
		public var _columnSelectorWidth:int=40;
		public var _filterSelectorWidth:int=40;
				
		//Maxium lenght for label text
		public var _rowMaximumLabelChars:int=20;
		public var _columnMaximumLabelChars:int=20;
		public var _filtersMaximumLabelChars:int=20;
		
		public var _cube:Cube;
		
		public function PopUpDelegate(cube:Cube,rowSelectorWidth:int=-1,columnSelectorWidth:int=-1,filterSelectorWidth:int=-1)
		{
			_cube=cube;
			_rowSelectorWidth=rowSelectorWidth;
			_columnSelectorWidth=columnSelectorWidth;
			_filterSelectorWidth=filterSelectorWidth;
		}
		
		public function createPopUp(node:Object,axisType:int):TuplePopUp{
			
			switch(axisType){
				case (OLAPQuery.COLUMN_AXIS):
							return new TuplePopUp(node,_columnMaximumLabelChars,_columnSelectorWidth);
							break;
				
				case (OLAPQuery.ROW_AXIS):
							return new TuplePopUp(node,_rowMaximumLabelChars,_rowSelectorWidth);
							break;
				
				case (OLAPQuery.SLICER_AXIS):
							return new TuplePopUp(node,_filtersMaximumLabelChars,_filterSelectorWidth);
							break;
			}
			return null;
		}
		
		public function createPopUpsFromOLAPResult(result:IOLAPResult):Array{
			/*
				Given an iolap result create some popupselector objects
				the array will be 2-dimenions with the first being:
				OLAPQuery.ROW_AXIS,OLAPQuery.COLUMN_AXIS,OLAPQuery.SLICER_AXIS
				the second dim contains the popup selectors for that axis
				
				When to use:  This should be used when stored queries are being
				executed and the grid needs to present the appropriate selectors.
				OR in instances, like a drill down, where the current selectors
				may not be relevant to the new query result.
			*/
			var rValue:Array=new Array(3);
			rValue[OLAPQuery.COLUMN_AXIS]=createPopUpsForAxis(result.getAxis(OLAPQuery.COLUMN_AXIS),OLAPQuery.COLUMN_AXIS);
			rValue[OLAPQuery.ROW_AXIS]=createPopUpsForAxis(result.getAxis(OLAPQuery.ROW_AXIS),OLAPQuery.ROW_AXIS);
			//rValue[OLAPQuery.SLICER_AXIS]=createPopUpsForAxis(result.getAxis(OLAPQuery.SLICER_AXIS),OLAPQuery.SLICER_AXIS);
			
			return rValue;
		}
		
		private function createPopUpsForAxis(resultAxis:IOLAPResultAxis,axisType:int):Array{
			// each position is a array location
			/*
				In this example the row result axis will have 2 positions
				1: all stores, 2: all pay types 
																	[Store Type].[All Store Types]	
				[Store].[All Stores]	[Pay Type].[All Pay Types]	$39,431.67
			
				this function should, for rows, return 2 popups 1: Store.all stores, 2:Pay Type.All Pay Types
			*/
			var rValue:ArrayCollection=new ArrayCollection();									logger.logDebug("createPopUpsForAxis:axis:"+axisType);
			try{
				var positions:ArrayCollection=ArrayCollection(resultAxis.positions);
				if (positions && positions.length>0){
				//only need to create a popup for highest level tuple 
				//loop through the member of each and save the highest
				var hm:HashMap=new HashMap();
				for (var tCnt:int=0;tCnt<positions.length;tCnt++){
					var t:Tuple=Tuple(positions.getItemAt(tCnt));							
					if (t){
						for (var i:int=0;i<t.members.length;i++){
							//now this is where we start creating popups
							var m:Member=Member(t.members.getItemAt(i));
							//Probably need more logic here to more accurately 
							//determine the element to create a popup for?
							//TICKET 64+
							//PERSIST PRevious drilldowns
							if (axisType==OLAPQuery.COLUMN_AXIS || axisType==OLAPQuery.ROW_AXIS){
								var e:Element=Element(_cube.getElement(m.uniqueName));
								logger.logDebug("createPopUpsForAxis:element:"+m.uniqueName);
								try{
								
									m=Member(e);	
									
								}catch(err:Error){
									var d:Dimension=Dimension(e.dimension);
									
								}
							}
							if (hm.containsKey(m.hierarchy.name)){
								//check the level size
								var prevM:Member=hm.find(m.hierarchy.name) as Member;
								if (m.level.depth>prevM.level.depth){
								logger.logDebug("createPopUpsForAxis:element high:"+m.uniqueName);
								
									//this current one is higher than in the hashmap
									//replace
									hm.remove(m.hierarchy.name);
									hm.insert(m.hierarchy.name,m);
								}
							}else{
								//hm does not contain this heir
								//so add
								hm.insert(m.hierarchy.name,m);
							}
						}
					}
				}
				for each (var hmKey:String in hm.getKeySet()){
					var winningMem:Member=hm.find(hmKey) as Member;
					//Create the popups
					var popUp:TuplePopUp;
					popUp=createPopUp(winningMem.hierarchy,axisType);				logger.logDebug("createPopUpsForAxis-created for:"+winningMem.hierarchy.uniqueName);
					rValue.addItem(popUp); //^^ Ticket 79
				
					
					
					
					//Now make the members that came back checked
					//and those that did not unchecked
					if (popUp){
						var checkedValues:ArrayCollection=new ArrayCollection();
						for each (var t2:Tuple in positions){
							for each (m in t2.members){
								//need to check each member to figure out relevance
								
								if (ElementsDelegate.directlyRelated(
																		Element(m),Element(popUp._olapElement)
																	 )
									){
										//related so update
										if (m.uniqueName.indexOf("Measures")>0){
											checkedValues.addItem(m.uniqueName);
										}else{
											checkedValues.addItem(m.level.uniqueName);
										}
										
									}
							}
						}
						popUp.clearAllSelections();				
						popUp.change(checkedValues.toArray(),true);
						//ticket 79, 72
						popUp.setDefault();
					}
				 }
			  }
			}catch (err:Error){
				logger.logError(err.message);
			}
			return rValue.toArray();
		}
	}
}