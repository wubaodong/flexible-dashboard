package com.ignite.olap.controls
{
	import com.ignite.collections.NoiseySet;
	import com.ignite.olap.Element;
	import com.ignite.olap.ElementsDelegate;
	import com.ignite.olap.Hierarchy;
	import com.ignite.olap.Level;
	import com.ignite.olap.MDDatasetResult;
	import com.ignite.olap.Member;
	import com.ignite.olap.ResultAxis;
	import com.ignite.olap.Tuple;
	import com.ignite.olap.events.TupleSelectorEvent;
	import com.igniteanalytics.logging.ASLogger;
	

	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	import mx.controls.Menu;
	import mx.controls.PopUpButton;
	import mx.core.IUIComponent;
	import mx.events.MenuEvent;

//--------------------------------------
//  Events
//--------------------------------------

/**
*  Dispatched when a menu item has changed
*  and is meant to tell the parent that the cube is to be queried.
*
*  @eventType com.ignite.olap.events.TupleSelectorEvent.CHANGED
*/
[Event(name="changed", type="com.ignite.olap.events.TupleSelectorEvent")]

/**
*  Dispatched the selector's menu REMOVE item has been selected
*  and is ready to be removed
*
*  @eventType com.ignite.olap.events.TupleSelectorEvent.REMOVED
*/
[Event (name="removed",type="com.ignite.olap.events.TupleSelectorEvent")]

	public class TuplePopUp extends PopUpButton
	{   
		public static var  ALL_MENU:String="all";
		public static var  NONE_MENU:String="none";
		public static var  CHILD_ACTION:String="child";
		public static var  REMOVE_MENU:String="remove";
		
	
	
		private var logger:ASLogger=new ASLogger("com.ignite.olap.controls.TuplePopUp");
	    public var _olapElement:Object; //dimension/member/level/heir whatever was dragged
		public var _rootTupleUName:String="";
		public var _rootTupleName:String="";
		
		public function TuplePopUp(olapElement:Object,maximumLabelChars:int=20,maximumControlWidth:int=-1)
		{	
			
			//Ticket 52: When dragging a level members not listed
			//SOme of these child calls are asynch so this may need to be 
			//refactored
			var children:ArrayCollection=ElementsDelegate.getChildrenTuples(olapElement) as ArrayCollection;		
			super();
			_max_label_length=maximumLabelChars;
			_olapElement=olapElement;
			_rootTupleUName=olapElement.uniqueName;
			_rootTupleName=olapElement.name;
			if (maximumControlWidth<0){
				this.percentWidth=100;
			}else{
				this.width=maximumControlWidth;
			}
			this.styleName="selectorUI";
																		logger.logDebug("new PopUp:_rootTupleUName-"+this._rootTupleUName);
		
			_selections.addItem(_olapElement); //add as default item
			
			this.label=createLabel(olapElement);
			this.id=_rootTupleUName+"_selector_"+Math.round(Math.random()*10000);;
			this.name=_rootTupleUName;
			
			this.popUp=buildMenu(children);
			if (olapElement is Level){
				//want to make sure the dragged level is preselected and
				//used in the query
				//test: drag hr-store.store name  it should query for store.name not just store
			//	changeSelection(this.name,true);
			}
			super.useHandCursor=true;
			super.buttonMode=true;
			super.mouseChildren=false;
			
			//per bug SDK-14445 ------------------------
			this.setStyle("closeDuration",1);
			this.setStyle("openDuration",0);
			
			super.addEventListener(Event.ADDED_TO_STAGE,addedToStageHandler);//per bug SDK-14445
			super.addEventListener(Event.REMOVED_FROM_STAGE,removeFromStageHandler);//per bug SDK-14445 
																					//http://tech.groups.yahoo.com/group/flexcoders/message/110289
		    ////per bug SDK-14445^^^^^^^^^^^^^^^^^^^^^^^
		    
			//monitor changes to trigger events like queries
		}
				
		public static var _max_label_length:int=20;//may have to adjust this depending on row/colum/filter
		private function createLabel(origElem:Object):String{
			//Ticket 68
			var origLabel:String=Element(origElem).name;
			
			if (origLabel=="(All)"){
				origLabel=Element(origElem).dimension.name;
			}
			//^^^^^^^^^^^^^^^^^^^^
			if (origLabel.length>_max_label_length){
				this.styleName="selectorUILongLabel";
				return origLabel.substr(0,_max_label_length);
				
			}
			return origLabel;
		}
		
		/*-----------------
		//	//Per http://tech.groups.yahoo.com/group/flexcoders/message/110289
		// //per bug SDK-14445 
		//  keep re adding the menu
		*/
		private var _popUpMenuHolder:IUIComponent=null;
		private function removeFromStageHandler(event:Object):void{
		    super.popUp=_popUpMenuHolder;
			    
			super.popUp.owner = this;
		}
		private function addedToStageHandler(event:Object):void{
			super.popUp=_popUpMenuHolder;
			   
			super.popUp.owner = this;
		}
		//^^^^^^^^^^^^^^^^^^^^
		
		public function remove():void{
			try{
					_selections.removeAll();
					parent.removeChild(this);
				}catch(err:Error){
					logger.logError(err.message);
				}
				dispatchEvent(new TupleSelectorEvent(TupleSelectorEvent.REMOVED));
		}
		
		public function populateFromResult(md:MDDatasetResult):void{
			//since the xmla query results have the full population of available tuples
			//and for large cubes the entire schema may not be available in the browser
			//provide functionality to populate the selector choices with xmla query result data
			/*
			XMLA Result snippet:
			<Axis name="Axis1">
			−
			<Tuples>
			−
				<Tuple>
					−
					<Member Hierarchy="Store Type">
						−
						<UName>
						[Store Type].[All Store Types].[Deluxe Supermarket]
						</UName>
						<Caption>Deluxe Supermarket</Caption>
						<LName>[Store Type].[Store Type]</LName>
						<LNum>1</LNum>
						<DisplayInfo>0</DisplayInfo>
					</Member>
					.
					.
					.
					<Member .....
					</Member>
				</Tuple>
		
			
			*/
			var relevantTuples:ArrayCollection=new ArrayCollection();			logger.logDebug("populateFromResult:_rootTupleUName-"+this._rootTupleUName);

			var axi:Array=md.axes;
			for each (var ra:ResultAxis in axi){
				if(ra.positions){
					for each (var t:Tuple in ra.positions){
						for each (var m:Member in t.members){
							try{
								if (isRelevantMember(m)){	
									//in xmla every member in a tuple is from hierarchy
									//this is a match ie this tuple is relevant to this popup
									var rT:Tuple=new Tuple();	//add a new because multiple mems in tuple
									rT.addMember(m);
									relevantTuples.addItem(rT);					logger.logDebug("populateFromResult add:"+m.uniqueName);
								}
							}catch(err:Error){}
						}
					}
				}
			} 
			this.popUp=buildMenu(relevantTuples);
		}
		public function isRelevantMember(m:Member):Boolean{
			var rValue:Boolean=false;
			try{
				var memRoot:String=m.uniqueName.substr(0,m.uniqueName.indexOf("."));
				rValue=this._rootTupleUName.indexOf(memRoot)>-1;
				
			}catch(err:Error){}
			
			return rValue;
		}
		public var _selections:NoiseySet=new NoiseySet();
		
		private var _flagForRemoval:Boolean=false;  
		public function FlagForRemove():void{
			//will remove once all menus and state are ok for removal;
			_flagForRemoval=true;
		}
	
		public override function set popUp(value:IUIComponent):void{
			//Add menu selection handlers for when menu items are selected
			//Throw custom menus
			super.popUp=value;
			this._popUpMenuHolder=super.popUp;
			if (popUp is Menu){
				popUp.addEventListener(MenuEvent.ITEM_CLICK,selectorMenuItemClick);
				popUp.addEventListener(MenuEvent.MENU_HIDE,menuClose);
			}
		}
		private function createMenuEntry(m:Object):String{
				var newNode:String="";
				try{
				newNode="<node label='"+m["name"]+"'";
				newNode=newNode+" tupleName='"+m["uniqueName"]+"'";
				newNode=newNode+" id='"+this._rootTupleUName+"~"+CHILD_ACTION+"~";
				newNode=newNode+m["uniqueName"]+"' member='yes' type='check' toggled='true'/>";
				}catch(err:Error){
					return "";
				}
				return newNode;
		}
		private function buildMenu(childrenTuples:ArrayCollection):Menu{
			
		//	<node label="type=check" id="ch" type="check" toggled="true" />
			
			var hasMembers:Boolean=false;
					
			
			hasMembers=(this._olapElement is Level || this._olapElement is Hierarchy);
			
			var root:String="<root>";
			root=root+"<node label='REMOVE' id='"+this._rootTupleUName+"~"+REMOVE_MENU+"~' toggled='false' />";
			
			var allNone:String="<node type='separator' />";
			//allNone=allNone+"<node label='All' groupName='allnone' id='"+this._rootTupleUName+"~"+ALL_MENU+"~' type='radio' toggled='true' />";
			//allNone=allNone+"<node label='None' groupName='allnone' id='"+this._rootTupleUName+"~"+NONE_MENU+"~' type='radio' toggled='false' />";
			allNone=allNone+"<node label='None' groupName='allnone' id='"+this._rootTupleUName+"~"+NONE_MENU+"~' type='check' toggled='false' />";
			allNone=allNone+"<node type='separator' />";
			
			if (hasMembers){
				root=root+allNone;
				
				for each (var o:Object in childrenTuples){
					root=root+createMenuEntry(o);			
				}
			}
			root=root+"</root>";
			
			var xmlMen:XML=new XML(root);
		
			return createMenu(xmlMen);
		}
		private function createMenu(xml:XML):Menu{
			var menu:Menu=new Menu();
			menu.id=this._rootTupleUName;
			menu.labelField="@label";
			menu.dataProvider=xml;
			menu.showRoot=false;
			return menu;
		}
		private function menuClose(menuEvent:Object):void{
																					
			if (_flagForRemoval){
				removeMe(menuEvent);		
			}
			if (_changed){
				dispatchEvent(new TupleSelectorEvent(TupleSelectorEvent.CHANGED));
			}
		}
		
		private function removeMe(event:Object):void{										
			if (_flagForRemoval){															logger.logDebug("removeMe");
				try{
					_selections.removeAll();
					parent.removeChild(this);
				}catch(err:Error){
					logger.logError(err.message);
				}
				dispatchEvent(new TupleSelectorEvent(TupleSelectorEvent.REMOVED));
			}
		}
	
		public function change(arrayOf:Array,value:Boolean):void{
			for (var i:int=0;i<arrayOf.length;i++){
				changeSelection(arrayOf[i],value);	
			}
		} 
		private function saveMenuNodeChanges(nodes:XMLList):void{
			this.popUp=createMenu(XML("<root>"+nodes.toXMLString()+"</root>"));
		
		}
		private function changeSelection(name:String,value:Boolean):void{
			var menuXML:XML=XML(Menu(super.popUp).dataProvider);
		//												logger.logDebug(menuXML.toXMLString());
			var members:XMLList=menuXML..node;
			for each (var menuNode:XML in members){
				if (menuNode.@member=="yes"){
					//this is a member 	
																								
					if (menuNode.@tupleName==name || menuNode.@label==name){		
											logger.logDebug(name+" changeSelection node found making:"+value);			
						if (value){
							menuNode.@toggled="true"
						}else{
							menuNode.@toggled="false"
						}
					}
				}
			}																					
			saveMenuNodeChanges(members);
			updateSelections();  //redundant but cleaner
		}
		public function setDefault():void{
			//if the selectors are empty
			//then add the all or whatever element
			//is relevant to the selectors
			//Ticket 79, 72
			if (_selections.length==0) _selections.addItem(this._olapElement);
		}
		private function getMenuMembers():XMLList{
			var menuXML:*=Menu(super.popUp).dataProvider;
			var members:XMLList;
			if (menuXML is XMLListCollection){
				try{
					members=XML(XMLListCollection(menuXML).toXMLString())..node;
				}catch(err:Error){
					members=XMLListCollection(menuXML).source;
				}
			}
			if (menuXML is XML){
				members=XML(Menu(super.popUp).dataProvider)..node;
			}
			return members;
		}
		private function updateSelections():void{
			//basically iterate through the menu options
			//find each member option
			//check if it is checked
			//if it is add the tuple to the selections array
			_selections.removeAll();				
			var members:XMLList=getMenuMembers();								
			for each (var menuNode:XML in members){
				if (menuNode.@member=="yes"){
								
											//this is a member 
					if((menuNode.@toggled!=null)&& (menuNode.@toggled=="true")){
						//so a member and checked need to add this
						//to the selection as a tuple
						//create a member as the selections must contain
						//OLAP elements not just strings of unique names as in ver 1.1
						var m:Member=new Member(menuNode.@label,menuNode.@tupleName);
						_selections.addItem(m);									logger.logDebug("updateSelections--added:"+m.uniqueName);
					}
				}
			}
		}
		public function checkAllSelections():void{
			//basically iterate through the menu options
			//find each member option
			//make it checked
			//add it to the selections array as well (prevents multiple loops
			var members:XMLList=getMenuMembers();
			for each (var menuNode:XML in members){
				if (menuNode.@toggled){
					//this is a member 
					menuNode.@toggled="true"
				}
			}
			saveMenuNodeChanges(members);
			updateSelections();  //redundant but cleaner
		}
		public function clearAllSelections():void{
			//basically iterate through the menu options
			//find each member option
			//make it checked
			//add it to the selections array as well (prevents multiple loops	
			var members:XMLList=getMenuMembers();										logger.logDebug("clearAllSelections");
			for each (var menuNode:XML in members){
				if (menuNode.@toggled){
					//this is a member 
					menuNode.@toggled="false"
				}
			}
			//This is different than checkall as if none are selected
			//what should occur?
			//Right now try to query without keeping the selector active
			//kind of like a bucket of possible selections or a working area 
			saveMenuNodeChanges(members);
			updateSelections();
		}
		private var _changed:Boolean=false;
		private function selectorMenuItemClick(event:MenuEvent):void{
			var i:int=0;
			var id:String=event.item.@id;
			
			if(id){
				//expect this:
		    	//<node label="Store Type" id="[Store Type]~child~[Store Type].[Store Type]" type="check" toggled="false"/>
		    
				var tokenStart:int=id.indexOf("~");
				var tokenEnd:int=id.lastIndexOf("~");
				var action:String=id.substr(tokenStart+1,(tokenEnd-tokenStart)-1);
				var uniqueName:String=id.substr(0,tokenStart);
																				logger.logDebug("selectorMenuItemClick:"+action+" "+uniqueName);
				switch(action){
					case (REMOVE_MENU):
							
						FlagForRemove();	//flag to remove
						//this.addEventListener(DropdownEvent.CLOSE,menuClose);
						
						break;
					case (ALL_MENU):
						checkAllSelections();
						_changed=true;
						break;
						
				    case (CHILD_ACTION):
				    	var checked:Boolean=event.item.@toggled=="true";
				    	updateSelections();
				    	_changed=true;
				    	break;
				    	
				    case (NONE_MENU):
				    	_changed=false;// NONE should not trigger a change
				    				   // This is a bit of a mis-behavior
				    				   //but the thought is that ALL and NONE
				    				   //are actions to help the user choose specific
				    				   //members WITHIN the selector
				    				   //NOT to define the membership of the tuples in
				    				   //the query
				    	clearAllSelections();
				    	break;
				    
					default:
						break;
				}
		  }
		}
		
	}
}