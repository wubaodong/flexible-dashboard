package org.integratedsemantics.flexibledashboardairmobile.app
{
	import com.esria.samples.dashboard.managers.PodLayoutManager;
	import com.esria.samples.dashboard.view.ChartContent;
	import com.esria.samples.dashboard.view.FormContent;
	import com.esria.samples.dashboard.view.IPodContentBase;
	import com.esria.samples.dashboard.view.ListContent;
	import com.esria.samples.dashboard.view.PieChartContent;
	import com.esria.samples.dashboard.view.Pod;
	import com.esria.samples.dashboard.view.PodContentBase;
	
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	
	import flexlib.mdi.containers.MDICanvas;
	import flexlib.mdi.containers.MDIWindow;
	import flexlib.mdi.events.MDIWindowEvent;
	import flexlib.mdi.managers.MDIManager;
	
	import mx.charts.chartClasses.DataTip;
	import mx.containers.ViewStack;
	import mx.controls.Alert;
	import mx.events.ModuleEvent;
	import mx.modules.IModuleInfo;
	import mx.modules.Module;
	import mx.modules.ModuleManager;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import org.integratedsemantics.flexibledashboard.blazeds.BlazeDsPod;
	import org.integratedsemantics.flexibledashboard.calendar.CalendarPod;
	import org.integratedsemantics.flexibledashboard.data.RemoteObjectDataService;
	import org.integratedsemantics.flexibledashboard.data.SoapDataService;
	import org.integratedsemantics.flexibledashboard.data.XmlDataService;
	import org.integratedsemantics.flexibledashboard.grid.ChartGridPodNotModule;
	import org.integratedsemantics.flexibledashboard.grid.GridPodNotModule;
	import org.integratedsemantics.flexibledashboard.jasperreports.ReportPod;
	import org.integratedsemantics.flexibledashboard.olap.OlapGridPod;
	import org.integratedsemantics.flexibledashboard.pentaho.PentahoPod;
	import org.integratedsemantics.flexibledashboardairmobile.birt.BirtReportViewerAirPod;
	import org.integratedsemantics.flexibledashboardairmobile.browser.BrowserPod;
	import org.integratedsemantics.flexibledashboardairmobile.html.GoogleGadgetPod;
	import org.integratedsemantics.flexibledashboardairmobile.html.HtmlPod;
	import org.integratedsemantics.flexibledashboardairmobile.liferay.LiferayHtmlPod;
	import org.integratedsemantics.flexibledashboardairmobile.localfiles.LocalFilesPod;
	import org.springextensions.actionscript.context.support.FlexXMLApplicationContext;
	import org.springextensions.actionscript.module.ISASModule;
	
	import spark.components.Application;
	import spark.components.TabBar;
	import spark.events.IndexChangeEvent;
	

	public class FlexibleDashboardAirMobileAppBase extends Application
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
		
		//private var _moduleConfigList:Dictionary = new Dictionary();
		//private var _moduleLayoutMgrList:Dictionary = new Dictionary();

		private var numPodsDoneInView:Number;
		private var numPodsInView:Number;  
		
		// todo: dummies not to get compiler warnings about syles for code in modules
		private var dataTipDummy:DataTip = new DataTip();
		
		private var viewIndex:int = 0;

		// force compiler to include these classes
		private var remoteObjectDataService:RemoteObjectDataService;
		private var soapDataService:SoapDataService;
		private var xmlDataService:XmlDataService;
		
		private var _applicationContext:FlexXMLApplicationContext;	
		
		private var _includeClass:Array = [ChartContent,FormContent,ListContent,PieChartContent,BlazeDsPod,CalendarPod,ChartGridPodNotModule,GridPodNotModule,ReportPod,OlapGridPod,PentahoPod,
			                               BirtReportViewerAirPod,BrowserPod,GoogleGadgetPod,HtmlPod,LiferayHtmlPod,LocalFilesPod];				

		public function FlexibleDashboardAirMobileAppBase()
		{
			super();
		}
					
        protected function onApplicationComplete(event:Event):void
        {
            //modeViewStack.selectedIndex = MAIN_VIEW_MODE_INDEX; 
			this.currentState = MAIN_VIEW_STATE;
			
            //onPortalCreationComplete();  
			
			_applicationContext = new FlexXMLApplicationContext("spring-actionscript/application-context.xml");
			_applicationContext.addEventListener(Event.COMPLETE, onLoadContextComplete);
			_applicationContext.load();						
		}
		
		protected function onLoadContextComplete(event:Event):void
		{
			_applicationContext.removeEventListener(Event.COMPLETE, onLoadContextComplete);
			onPortalCreationComplete();                              	
		}
					
		protected function onPortalCreationComplete():void
		{
			// Load pods.xml, which contains the pod layout.
			var httpService:HTTPService = new HTTPService();
			httpService.url = "data/flexibleDashboardAirMobilePods.xml";
			httpService.resultFormat = "e4x";
			httpService.addEventListener(FaultEvent.FAULT, onFaultHttpService);
			httpService.addEventListener(ResultEvent.RESULT, onResultHttpService);
			httpService.send();			
		}
		
		protected function onFaultHttpService(e:FaultEvent):void
		{
			Alert.show("Unable to load data/flexibleDashboardAirMobilePods.xml.");
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
		}
		
		protected function onChangeTabBar(e:IndexChangeEvent):void
		{
			// make any WebViews hidden/snapshotted in current tab view
			var oldPodLayoutManager:PodLayoutManager = podLayoutManagers[viewIndex];			
			if ((oldPodLayoutManager != null) && (viewIndex != e.newIndex))	
			{
				for each(var win:MDIWindow in oldPodLayoutManager.windowList)
				{
					win.dispatchEvent(new MDIWindowEvent(MDIWindowEvent.FOCUS_END, win));
				}
			}			
			
			var index:Number = e.newIndex;
			viewIndex = index;
			viewStack.selectedIndex = index;
			
			// If data exists then add the pods. After the pods have been added the data is cleared.
			var podLayoutManager:PodLayoutManager = podLayoutManagers[index];
			if (podDataDictionary[podLayoutManager] != null)
			{
				addPods(podLayoutManagers[index]);
			}
		}
		
		// Adds the pods to a view.
		protected function addPods(manager:PodLayoutManager):void
		{
			// Loop through the pod nodes for each view node.
			var podXMLList:XMLList = podDataDictionary[manager];
					
			numPodsInView =  podXMLList.length();
						
			for (var i:Number = 0; i < numPodsInView; i++)
			{
				// new up Pod from fully qualified class name instead of load module so can work on iOS

				var className:String = podXMLList[i].@className;
				var definition:Class = getDefinitionByName(className) as Class; 
				var objInstance:Object = new definition();  	
				
				var podContent:PodContentBase = objInstance as PodContentBase;	
				
				podContent.applicationContext = this._applicationContext;
				
				var podConfig:XML = podXMLList[i] as XML;
				
				var viewId:String = manager.id;
				var podId:String = podConfig.@id;
				
				podContent.properties = podConfig;
				var pod:Pod = new Pod();
				pod.id = podId;
				pod.title = podConfig.@title;
				
				podContent.pod = pod;
				podContent.podManager = manager;
				
				pod.addElement(podContent);
				
				manager.addItemAt(pod, -1, false);						
				
				podHash[pod] = manager;						
			}
			
			// Delete the saved data.
			delete podDataDictionary[manager];			
			
			var argsArray:Array = new Array();
			// all pods complete so now the layout can be done correctly. 
			// todo: may need to add check / event for creation of all pods is really done
			argsArray.push(manager); 
			callLater(layoutAfterCreationComplete, argsArray);							
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
				
	}
}