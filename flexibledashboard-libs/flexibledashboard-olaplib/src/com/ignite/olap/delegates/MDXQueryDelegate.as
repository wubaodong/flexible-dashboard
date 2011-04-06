package com.ignite.olap.delegates
{
	import com.ignite.collections.NoiseyArrayCollection;
	import com.ignite.collections.NoiseyHashMap;
	import com.ignite.olap.Cube;
	import com.ignite.olap.Element;
	import com.ignite.olap.ElementsDelegate;
	import com.ignite.olap.IgniteOLAPSet;
	import com.ignite.olap.Member;
	import com.ignite.olap.Query;
	import com.ignite.olap.QueryAxis;
	import com.ignite.olap.Tuple;
	import com.igniteanalytics.logging.ASLogger;
	
	import mx.collections.ArrayCollection;
	import mx.olap.OLAPQuery;
           
	public class MDXQueryDelegate
	{
		
		private static var logger:ASLogger=new ASLogger("com.ignite.olap.util.MDXQueryDelegate");
  	
		public function MDXQueryDelegate()
		{
			
		}
		public static function createDrillDownQuery(selectedRow:Tuple,
													selectedColumn:Tuple,
													cube:Cube,
													rows:NoiseyHashMap,
													columns:NoiseyHashMap,
													filters:NoiseyHashMap,
													allowEmpty:Boolean=false):Boolean{
	   ///---------------------------------------------------------------------------
	   // All we are doing here is interpreting the tuples that are related
	   // to the drill down choices then modifing the existing row and column
	   // selector data structures to correctly identify all the elements of the query
			var rValue:Boolean=true;;
			var rowSilenceState:Boolean=rows.silent;
			var colSilenceState:Boolean=columns.silent;
			try{																	logger.logDebug("createDrillDownQuery");
				
				//=================== ROW STUFF =========================
				var newRowElem:ArrayCollection=new ArrayCollection();
				if (selectedRow){
					rows.silent=true;
					//setDrillDownMatches(selectedRow.members as ArrayCollection);
					//see if the row selectors have the appropriate level for drill down
					updateAxisForDrillDown(selectedRow,rows,cube,OLAPQuery.ROW_AXIS);
					rows.silent=rowSilenceState;  //restore to original state
				} 
				
				//==============COLUMN STUFF=======================
				//IF there are no rows and just the header clicked
				//Then we clear the columsn and make the query
				//return just the one choosen
				var newColElem:ArrayCollection=new ArrayCollection();
				if (selectedColumn){
					columns.silent=true;
					//setDrillDownMatches(selectedColumn.members as ArrayCollection);
					//see if the row selectors have the appropriate level for drill down
				    updateAxisForDrillDown(selectedColumn,columns,cube,OLAPQuery.COLUMN_AXIS);
				
					columns.silent=colSilenceState;  //restore to original state
				}
			
				//now all the axis collections should be setup to correctly
				//reflect the drill down request
				//fire off whatever the query is using the rows collect
																				logger.logDebug("createDrillDownQuery firing row.fireChange");
				rows.fireChange();
				//if we do this twice then 2 queries will probably fire
			
			}catch(err:Error){
				try{rows.silent=rowSilenceState;}catch(err:Error){}
				try{columns.silent=colSilenceState;}catch(err:Error){}
				logger.logError(err.message);
				rValue=false;
			}
			return rValue;
		}
		public static function updateAxisForDrillDown(ddTuple:Tuple,axisTuples:NoiseyHashMap,cube:Cube,axisType:int):Boolean{
			var rValue:Boolean=true;
			try{
			axisTuples.silent=true;
			for each (var m:Member in ddTuple.members){         logger.logDebug("updateAxisForDrillDown:checking:"+m.uniqueName +" on axis:"+axisType);
				var drillDownElement:Element=getUpdatedCubeElementForDrillDown(cube,m.uniqueName);
				
				if ((axisType==OLAPQuery.COLUMN_AXIS)
					||
					(addDrillDownMember(drillDownElement,axisTuples,cube))
					){																logger.logDebug("updateAxisForDrillDown new Sel&Elem:"+drillDownElement.uniqueName);
							var newSelector:NoiseyArrayCollection=new NoiseyArrayCollection();
							//need to use an already existing id
							var id:String="drillDown_"+drillDownElement.uniqueName;
							var keys:Array=axisTuples.getKeySet();
							if (keys.length>0)	id=keys[0];
							newSelector.addItem(drillDownElement);									
							
							axisTuples.clear();
							axisTuples.insert(id,newSelector);
				}
				
			}
			axisTuples.silent=false;
			}
			catch(err:Error){
				logger.logError(err.message);
				rValue=false;
			}
			return rValue;
		}
		private static function getUpdatedCubeElementForDrillDown(cube:Cube,uniqueName:String):Element{
			var drillDownElement:Element=Element(cube.getElement(uniqueName));
			if (drillDownElement)
					drillDownElement.drillDownSelected=true;//toggleElementDrillDown(drillDownElement);
				
			return drillDownElement;
		}
		private static function addDrillDownMember(drillDownElement:Element,axisTuples:NoiseyHashMap,cube:Cube):Boolean{
																		
			var impliedDDLevel:int=ElementsDelegate.impliedLevel(drillDownElement.uniqueName);
			var bestMatches:Array=new Array(20);
			var found:Boolean=false;
			for each (var key:Object in axisTuples.getKeySet()){
				var selector:Object=axisTuples.find(key);
				
				var needToAdd:Boolean=true;
			 	var crntSelector:ArrayCollection=ArrayCollection(selector);
			    var relevantSelector:Boolean=true;
				for (var x:int=0;x<crntSelector.length;x++){
					var child:Object=crntSelector.getItemAt(x);
					if (child is Element){
						//check the selectors in here
						var matches:int=ElementsDelegate.getMatches(Element(drillDownElement),Element(child));
						var diff:int=impliedDDLevel-matches;
						var tmpDto:Object=new Object();
						tmpDto.element=child;
						tmpDto.indexLoc=x;
						//update object because we need this in next logic area
																			logger.logDebug("addDrillDownMember: ddElem:"+drillDownElement.uniqueName+" :: "+Element(child).uniqueName +" diff indx:"+diff);
						
						if (diff>-1 && diff!=impliedDDLevel) bestMatches[diff]=tmpDto;
					}
				}
				
				//now go through the array and use the best match
				for (var aCnt:int=0;aCnt<bestMatches.length;aCnt++){
					if (bestMatches[aCnt]!=null){
						var e:Element=Element(bestMatches[aCnt].element);
						var loc:int=bestMatches[aCnt].indexLoc;
						
						needToAdd=false;	logger.logDebug("addDrillDownMember match found at:"+aCnt);
						
							crntSelector.removeItemAt(loc);
							crntSelector.addItemAt(drillDownElement,loc);
						
						//stop the loop
						aCnt=bestMatches.length+1;
						found=true;	
					}
				}
				if (found) break;
				
			}
			return needToAdd;
		}
		
		
		private static function toggleElementDrillDown(elem:Element):void{
			logger.logDebug("toggleElementDrillDown:"+elem.uniqueName+">"+elem.drillDownSelected);
			elem.drillDownSelected=!elem.drillDownSelected;
			logger.logDebug("toggleElementDrillDown:"+elem.uniqueName+">"+elem.drillDownSelected);
		}
		private static function toggleDrillDownMatches(selections:ArrayCollection):void{
				for each (var obj:Object in selections){
						
						//ticket 65 tf
						//for each tuple choosen iterate through the selectors and 
						//make the matches as drilldowns
						toggleElementDrillDown(Element(obj));
					}
		}
		private static function setDrillDownMatches(selections:ArrayCollection,value:Boolean):void{
				for each (var obj:Object in selections){
						
						//ticket 65 tf
						//for each tuple choosen iterate through the selectors and 
						//make the matches as drilldowns
						Element(obj).drillDownSelected=value;
					}
		}
		private static function resetDrillDown(aryOfSets:Array,value:Boolean):void{
				for (var i:int=0;i<aryOfSets.length;i++){
				        // sreiner: comment out to avoid warning
					    //if (value==null){
					    //	toggleDrillDownMatches(ArrayCollection(aryOfSets[i]));
					    //}else{
							setDrillDownMatches(ArrayCollection(aryOfSets[i]),value);
					    //}
					}
		}
		public static function buildIOLAPQueryAxis (items:Array):QueryAxis{
			var rQueryAxis:QueryAxis=new QueryAxis();
			for each (var ns:NoiseyArrayCollection in items){
				var axisSet:IgniteOLAPSet=new IgniteOLAPSet();
				for each (var ele:Element in ns.toArray()){
					axisSet.addElement(ele);
				}
				rQueryAxis.addSet(axisSet);
			}
			return rQueryAxis;
		}
		public static function buildIOLAPQuery(rows:Array,
											columns:Array,
											filters:Array,cube:Cube,allowEmpty:Boolean=false):Query{
												
			var rowQA:QueryAxis=buildIOLAPQueryAxis(rows);
			var colQA:QueryAxis=buildIOLAPQueryAxis(columns);
			var filterQA:QueryAxis=buildIOLAPQueryAxis(filters);
			
			var rQuery:Query=new Query(null);
			rQuery.setAxis(OLAPQuery.ROW_AXIS,rowQA);
			rQuery.setAxis(OLAPQuery.COLUMN_AXIS,colQA);
			rQuery.setAxis(OLAPQuery.SLICER_AXIS,filterQA);
			
			return rQuery;										
		}
		
	}
}
