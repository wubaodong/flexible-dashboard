package org.integratedsemantics.flexibledashboardair.app
{
	import com.esria.samples.dashboard.events.LayoutChangeEvent;
	import com.esria.samples.dashboard.managers.PodLayoutManager;
	import com.esria.samples.dashboard.managers.StateManager;
	import com.esria.samples.dashboard.view.ChartContent;
	import com.esria.samples.dashboard.view.FormContent;
	import com.esria.samples.dashboard.view.ListContent;
	import com.esria.samples.dashboard.view.PieChartContent;
	import com.esria.samples.dashboard.view.Pod;
	import com.esria.samples.dashboard.view.PodContentBase;
	
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import flexlib.mdi.containers.MDICanvas;
	
	import mx.containers.ViewStack;
	import mx.controls.Alert;
	import mx.events.IndexChangedEvent;
	import mx.events.ItemClickEvent;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import org.integratedsemantics.flexibledashboard.blazeds.BlazeDsPod;
	import org.integratedsemantics.flexibledashboard.calendar.CalendarPod;
	import org.integratedsemantics.flexibledashboard.flex.FlexAppPod;
	import org.integratedsemantics.flexibledashboard.jasperreports.ReportPod;
	import org.integratedsemantics.flexibledashboard.olap.OlapGridPod;
	import org.integratedsemantics.flexibledashboard.pentaho.PentahoPod;
	import org.integratedsemantics.flexibledashboardair.birt.BirtReportViewerAirPod;
	import org.integratedsemantics.flexibledashboardair.browser.BrowserPod;
	import org.integratedsemantics.flexibledashboardair.html.GoogleGadgetPod;
	import org.integratedsemantics.flexibledashboardair.html.HtmlPod;
	import org.integratedsemantics.flexibledashboardair.liferay.LiferayHtmlPod;
	import org.integratedsemantics.flexibledashboardair.localfiles.LocalFilesPod;
	
	import spark.components.TabBar;
	import spark.components.WindowedApplication;
	import spark.events.IndexChangeEvent;
	

	public class FlexibleDashboardAirAppBase extends spark.components.WindowedApplication
	{
		//public var modeViewStack:ViewStack;
		
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
		

		public function FlexibleDashboardAirAppBase()
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
			httpService.url = "data/flexibleDashboardAirPods.xml";
			httpService.resultFormat = "e4x";
			httpService.addEventListener(FaultEvent.FAULT, onFaultHttpService);
			httpService.addEventListener(ResultEvent.RESULT, onResultHttpService);
			httpService.send();			
		}
		
		protected function onFaultHttpService(e:FaultEvent):void
		{
			Alert.show("Unable to load data/flexibleDashboardAirPods.xml.");
		}
		
		protected function onResultHttpService(e:ResultEvent):void
		{
			var viewXMLList:XMLList = e.result.view;
			var len:Number = viewXMLList.length();
			var containerWindowManagerHash:Object = new Object();
			for (var i:Number = 0; i < len; i++) // Loop through the view nodes.
			{
				// Create a canvas for each view node.
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
				//manager.addEventListener(LayoutChangeEvent.UPDATE, StateManager.setPodLayout);
				
				// Store the pod xml data. Used when view is first made visible.
				podDataDictionary[manager] = viewXMLList[i].pod;
				podLayoutManagers.push(manager);
			}
			
			var index:Number = StateManager.getViewIndex();
			// Make sure the index is not out of range.
			// This can happen if a tab view was saved but then tabs were subsequently removed from the XML.
			index = Math.min(tabBar.numChildren - 1, index);
			onChangeTabBar(new IndexChangeEvent(IndexChangeEvent.CHANGE, false, false, -1, index));
			tabBar.selectedIndex = index;
		}
		
		protected function onChangeTabBar(e:IndexChangeEvent):void
		{
			var index:Number = e.newIndex;
			StateManager.setViewIndex(index); // Save the view index.
			
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
			var podLen:Number = podXMLList.length();
			var unsavedPodCount:Number = 0;
			for (var j:Number = 0; j < podLen; j++)
			{
				// Figure out which type of pod content to use.
				var podContent:PodContentBase = null;
				if (podXMLList[j].@type == "chart")
					podContent = new ChartContent();
				else if (podXMLList[j].@type == "form")
					podContent = new FormContent();
				else if (podXMLList[j].@type == "list")
					podContent = new ListContent();
				else if (podXMLList[j].@type == "pieChart")
					podContent = new PieChartContent();						
				else if (podXMLList[j].@type == "report")
				{
					podContent = new ReportPod();						
				}  											
				else if (podXMLList[j].@type == "pentaho")
				{
					podContent = new PentahoPod();						
				}  											
                else if (podXMLList[j].@type == "blazeds")
                {
                    podContent = new BlazeDsPod();                      
                }   
				else if (podXMLList[j].@type == "html")
				{
					podContent = new HtmlPod();						
				}  											
				else if (podXMLList[j].@type == "liferay")
				{
					podContent = new LiferayHtmlPod();						
				}  											
				else if (podXMLList[j].@type == "localfiles")
				{
					podContent = new LocalFilesPod();						
				}  											
                else if (podXMLList[j].@type == "googlegadget")
                {
                    podContent = new GoogleGadgetPod();                      
                }                                           
                else if (podXMLList[j].@type == "browser")
                {
                    podContent = new BrowserPod();                      
                }                                           
                else if (podXMLList[j].@type == "flexApp")
                {
                    podContent = new FlexAppPod();                      
                }                                           
				else if (podXMLList[j].@type == "calendar")
				{
					podContent = new CalendarPod();						
				}  											
                else if (podXMLList[j].@type == "olap-grid")
                {
                    podContent = new OlapGridPod();                     
                }  
                else if (podXMLList[j].@type == "birt-report")
                {
                    podContent = new BirtReportViewerAirPod();                     
                }               
				
				if (podContent != null)
				{
					var viewId:String = manager.id;
					var podId:String = podXMLList[j].@id;
					
					// Get the saved value for the pod content viewStack.
					if (StateManager.getPodViewIndex(viewId, podId) != -1)
						podXMLList[j].@selectedViewIndex = StateManager.getPodViewIndex(viewId, podId);
					
					podContent.properties = podXMLList[j];
					var pod:Pod = new Pod();
					pod.id = podId;
					pod.title = podXMLList[j].@title;

					//flex4spark pod.addChild(podContent);
					pod.addElement(podContent);
					
					var index:Number;
					
					// todo: either add back restoring state at startup or eliminate state storage
					//if (StateManager.isPodMinimized(viewId, podId))
					//{
					//	index = StateManager.getMinimizedPodIndex(viewId, podId);
					//	manager.addMinimizedItemAt(pod, index);
					//}
					//else
					//{
						index = StateManager.getPodIndex(viewId, podId);
						
						// If the index hasn't been saved move the pod to the last position.
						if (index == -1)
						{
							index = podLen + unsavedPodCount;
							unsavedPodCount += 1;
						}
												
						//manager.addItemAt(pod, index, StateManager.isPodMaximized(viewId, podId));	
						manager.addItemAt(pod, index, false);												
					//}
					
					pod.addEventListener(IndexChangedEvent.CHANGE, onChangePodView);
					
					podHash[pod] = manager;
				}
			}
			
			// Delete the saved data.
			delete podDataDictionary[manager];
			
            // Listen for the last pod to complete so the layout from the ContainerWindowManager is done correctly. 
            //mdi pod.addEventListener(FlexEvent.UPDATE_COMPLETE, onCreationCompletePod);   
            var argsArray:Array = new Array();
            argsArray.push(manager); 
            callLater(onCreationCompletePod, argsArray);
		}
		
		// Pod has been created so update the respective PodLayoutManager.
		// mdi protected function onCreationCompletePod(e:FlexEvent):void
        protected function onCreationCompletePod(manager:PodLayoutManager):void
		{
			//mdi e.currentTarget.removeEventListener(FlexEvent.UPDATE_COMPLETE, onCreationCompletePod);
			// mdi var manager:PodLayoutManager = PodLayoutManager(podHash[e.currentTarget]);
			manager.removeNullItems();
			//mdi manager.updateLayout(false);
			manager.tile();
		}
		
		// Saves the pod content ViewStack state.
		protected function onChangePodView(e:IndexChangedEvent):void
		{
			var pod:Pod = Pod(e.currentTarget);
			var viewId:String = PodLayoutManager(podHash[pod]).id;
			StateManager.setPodViewIndex(viewId, pod.id, e.newIndex);
		}
		
		// mdi
		protected function tile():void
		{
		    var index:int = viewStack.selectedIndex;
		    var mgr:PodLayoutManager = podLayoutManagers[index];
		    mgr.tile();  
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