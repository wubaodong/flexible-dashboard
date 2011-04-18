package org.integratedsemantics.flexibledashboard.app
{
	import com.esria.samples.dashboard.events.LayoutChangeEvent;
	import com.esria.samples.dashboard.managers.PodLayoutManager;
	import com.esria.samples.dashboard.view.ChartContent;
	import com.esria.samples.dashboard.view.FormContent;
	import com.esria.samples.dashboard.view.IPodContentBase;
	import com.esria.samples.dashboard.view.ListContent;
	import com.esria.samples.dashboard.view.PieChartContent;
	import com.esria.samples.dashboard.view.Pod;
	import com.esria.samples.dashboard.view.PodContentBase;
	
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import flexlib.mdi.containers.MDICanvas;
	import flexlib.mdi.containers.MDIWindow;
	import flexlib.mdi.managers.MDIManager;
	
	import mx.charts.chartClasses.DataTip;
	import mx.containers.ViewStack;
	import mx.controls.Alert;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.events.IndexChangedEvent;
	import mx.events.ModuleEvent;
	import mx.modules.IModuleInfo;
	import mx.modules.ModuleManager;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import org.integratedsemantics.flexibledashboard.birt.BirtReportViewerPod;
	import org.integratedsemantics.flexibledashboard.blazeds.BlazeDsPod;
	import org.integratedsemantics.flexibledashboard.calendar.CalendarPod;
	import org.integratedsemantics.flexibledashboard.flex.FlexAppPod;
	import org.integratedsemantics.flexibledashboard.html.IFramePod;
	import org.integratedsemantics.flexibledashboard.jasperreports.ReportPod;
	import org.integratedsemantics.flexibledashboard.olap.OlapGridPod;
	import org.integratedsemantics.flexibledashboard.pentaho.PentahoPod;
	
	import spark.components.Application;
	import spark.components.TabBar;
	import spark.events.IndexChangeEvent;

	public class FlexibleDashboardAppBase extends Application
	{
		[Bindable]
		public var viewStack:ViewStack;
		
		public var tabBar:TabBar;
		
        // view modes
        //public static const MAIN_VIEW_MODE_INDEX:int = 0;
		public static const MAIN_VIEW_STATE:String = "MainViewState";

		// Array of PodLayoutManagers
		protected var podLayoutManagers:Array = new Array();
		
		// Stores the xml data keyed off of a PodLayoutManager.
		protected var podDataDictionary:Dictionary = new Dictionary();
		
		// Stores PodLayoutManagers keyed off of a Pod.
		// Used for podLayoutManager calls after pods have been created for the first time.
		// Also, used for look-ups when saving pod content ViewStack changes.
		protected var podHash:Object = new Object();
		
		private var _moduleConfigList:Dictionary = new Dictionary();
		private var _moduleLayoutMgrList:Dictionary = new Dictionary();

		private var numPodsDoneInView:Number;
		private var numPodsInView:Number;  
		
		// todo: dummies not to get compiler warnings about syles for code in modules
		private var dataTipDummy:DataTip = new DataTip();
		
		private var viewIndex:int = 0;
		
		
		public function FlexibleDashboardAppBase()
		{
			super();
		}
					
        protected function onApplicationComplete(event:Event):void
        {
            //modeViewStack.selectedIndex = MAIN_VIEW_MODE_INDEX; 
			this.currentState = MAIN_VIEW_STATE;
			
            onPortalCreationComplete();                              	
        }
					
		protected function onPortalCreationComplete():void
		{
			// Load pods.xml, which contains the pod layout.
			var httpService:HTTPService = new HTTPService();
			httpService.url = "data/flexibleDashboardPods.xml";
			httpService.resultFormat = "e4x";
			httpService.addEventListener(FaultEvent.FAULT, onFaultHttpService);
			httpService.addEventListener(ResultEvent.RESULT, onResultHttpService);
			httpService.send();
		}
		
		protected function onFaultHttpService(e:FaultEvent):void
		{
			Alert.show("Unable to load data/flexibleDashboardPods.xml.");
		}
		
		protected function onResultHttpService(e:ResultEvent):void
		{
			var viewXMLList:XMLList = e.result.view;
			var len:Number = viewXMLList.length();
			var containerWindowManagerHash:Object = new Object();
			for (var i:Number = 0; i < len; i++) // Loop through the view nodes.
			{
				// Create a canvas and mgr for each view node.
                var canvas:MDICanvas = new MDICanvas();	
				var manager:PodLayoutManager = new PodLayoutManager(canvas);
				canvas.windowManager = manager;
				
				canvas.label = viewXMLList[i].@label;
				canvas.percentWidth = 100;
				canvas.percentHeight = 100;
				canvas.windowManager.tilePadding = 10;

				viewStack.addChild(canvas);
								
				// setup manager for view.
				manager.id = viewXMLList[i].@id;
				
				// todo: should listen to other events instead that mdimgr sends, layoutchangeevent no longer sent 				
				//todo manager.addEventListener(LayoutChangeEvent.UPDATE, StateManager.setPodLayout);
				
				// Store the pod xml data. Used when view is first made visible.
				podDataDictionary[manager] = viewXMLList[i].pod;
				podLayoutManagers.push(manager);
			}
						
			var index:Number = this.viewIndex;
			// Make sure the index is not out of range.
			// This can happen if a tab view was saved but then tabs were subsequently removed from the XML.
			index = Math.min(tabBar.numChildren - 1, index);
			onChangeTabBar(new IndexChangeEvent(IndexChangeEvent.CHANGE, false, false, -1, index));
			tabBar.selectedIndex = index;
			
			//testMdiManager();						
		}
		
		protected function onChangeTabBar(e:IndexChangeEvent):void
		{
			var index:Number = e.newIndex;
			viewIndex = index;
			
			viewStack.selectedIndex = index;
			
			// If data exists then add the pods. After the pods have been added the data is cleared.
			var podLayoutManager:PodLayoutManager = podLayoutManagers[index];
			if (podDataDictionary[podLayoutManager] != null)
				addPods(podLayoutManagers[index]);
		}
		
		// Adds the pods to a view.
		protected function addPods(manager:PodLayoutManager):void
		{
			// Loop through the pod nodes for each view node.
			var podXMLList:XMLList = podDataDictionary[manager];
			
			numPodsDoneInView = 0;
			numPodsInView =  podXMLList.length();
			
			for (var i:Number = 0; i < numPodsInView; i++)
			{
				// load flex module for pod
				var info:IModuleInfo = ModuleManager.getModule(podXMLList[i].@module);
				_moduleConfigList[info] = podXMLList[i];
				_moduleLayoutMgrList[info] = manager;			
				info.addEventListener(ModuleEvent.READY, handleModuleReady);
				info.addEventListener(ModuleEvent.ERROR, handleModuleError);
				info.load(null, null, null, moduleFactory);				
			}
			
			// Delete the saved data.
			delete podDataDictionary[manager];			
		}
		
		private function handleModuleReady(event:ModuleEvent):void
		{
			var info:IModuleInfo = event.module;
			
			var podContent:IPodContentBase = info.factory.create() as IPodContentBase;					
			
			var podConfig:XML = _moduleConfigList[info] as XML;
			var manager:PodLayoutManager = _moduleLayoutMgrList[info];			
			cleanupInfo(info);
						
			var viewId:String = manager.id;
			var podId:String = podConfig.@id;
			
			podContent.properties = podConfig;
			var pod:Pod = new Pod();
			pod.id = podId;
			pod.title = podConfig.@title;
			
			pod.addElement(podContent);
			
			manager.addItemAt(pod, -1, false);						
			
			podHash[pod] = manager;		
			
			numPodsDoneInView++;
			if (numPodsDoneInView == numPodsInView)
			{
				// all pods complete so now the layout can be done correctly. 
				layoutAfterCreationComplete(manager);				
			}						
		}
		
		private function handleModuleError(event:ModuleEvent):void
		{
			Alert.show(event.errorText);
		}

		private function cleanupInfo(info:IModuleInfo):void 
		{
			delete _moduleConfigList[info];
			delete _moduleLayoutMgrList[info];
			info.removeEventListener(ModuleEvent.READY, handleModuleReady);
			info.removeEventListener(ModuleEvent.ERROR, handleModuleError);
		}
		
		// Pod has been created so update the respective PodLayoutManager.
        protected function layoutAfterCreationComplete(manager:PodLayoutManager):void
		{
			manager.removeNullItems();
			manager.tile(false, 10);
			manager.updateLayout(false);
		}
		
		// mdi
		protected function tile():void
		{
		    var index:int = viewStack.selectedIndex;
		    var mgr:PodLayoutManager = podLayoutManagers[index];
		    mgr.tile(false, 10);  
		}
        
        // mdi
        protected function cascade():void
        {
            var index:int = viewStack.selectedIndex;
            var mgr:PodLayoutManager = podLayoutManagers[index];
            mgr.cascade();   
        }
		
		private function testMdiManager():void
		{
			// test mdi without podlayout
			var canvas:MDICanvas = new MDICanvas();	
			var mdiManager:MDIManager = new MDIManager(canvas);
			canvas.windowManager = mdiManager;
			canvas.label = "test";
			canvas.width = 1000;
			canvas.height = 900;
			canvas.windowManager.tilePadding = 10;
			viewStack.addChild(canvas);
			var w1:MDIWindow = new MDIWindow();
			w1.windowManager = mdiManager;
			mdiManager.add(w1);
			var w2:MDIWindow = new MDIWindow();
			w2.windowManager = mdiManager;
			mdiManager.add(w2);		
			//mdiManager.cascade();
			mdiManager.tile(false, 10);		
		}
				
	}
}