package org.integratedsemantics.flexibledashboardairmobile.html
{
	import com.esria.samples.dashboard.view.PodContentBase;
	import com.flexcapacitor.controls.WebView;
	
	import flash.events.Event;
	import flash.events.FocusEvent;
	
	import flex.utils.spark.resize.MoveManager;
	import flex.utils.spark.resize.ResizeManager;
	
	import flexlib.mdi.containers.MDIWindow;
	import flexlib.mdi.containers.MDIWindowState;
	import flexlib.mdi.events.MDIManagerEvent;
	import flexlib.mdi.events.MDIWindowEvent;
	
	import mx.core.FlexGlobals;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	

	public class HtmlPodBase extends PodContentBase
	{
		protected var webview:WebView;		
		protected var tileMode:Boolean = true;
		protected var cascadeMode:Boolean = false;
		protected var widthOffset:int = 10;		
		protected var heightOffset:int = 20;

		
		public function HtmlPodBase()
		{
			super();
		}
						
		override protected function onCreationComplete(e:FlexEvent):void
		{
			super.onCreationComplete(e);
			
			webview = new WebView();
			webview.id = properties.@id;
			webview.percentHeight = 100;
			webview.percentWidth = 100;
			this.addElement(webview);
			
			podManager.addEventListener(MDIManagerEvent.WINDOW_DRAG_START, onDragStart);
			podManager.addEventListener(MDIManagerEvent.WINDOW_DRAG_END, onDragEnd);
			
			pod.addEventListener(ResizeManager.RESIZE_START, onResizerResizeStart);
			pod.addEventListener(ResizeManager.RESIZE_END, onResizerResizeEnd);
			pod.addEventListener(EffectEvent.EFFECT_END, onEffectEnd);
			pod.addEventListener(ResizeEvent.RESIZE, onResize);
			pod.addEventListener(MDIWindowEvent.FOCUS_START, onMdiFocusStart);
			pod.addEventListener(MDIWindowEvent.FOCUS_END, onMdiFocusEnd);
			podManager.addEventListener(MDIManagerEvent.CASCADE_START, onCascadeStart);
			podManager.addEventListener(MDIManagerEvent.TILE, onTile);			
			
			podManager.addEventListener(MDIManagerEvent.WINDOW_MINIMIZE, onMdiMinimize);			
			podManager.addEventListener(MDIManagerEvent.WINDOW_MAXIMIZE, onMdiMaximize);			
			podManager.addEventListener(MDIManagerEvent.WINDOW_RESTORE, onMdiRestore);			
			
		}  
		
		protected function onMdiMinimize(event:MDIManagerEvent):void
		{
			var window:MDIWindow = event.window;
			if (this.pod == window)
			{
				webview.snapshotMode = true;
				webview.visible = false;
			}
		}
		
		protected function onMdiMaximize(event:MDIManagerEvent):void
		{
			var window:MDIWindow = event.window;
			if (this.pod != window)
			{
				// snapshot other webviews
				webview.snapshotMode = true;				
			}
		}
		
		protected function onMdiRestore(event:MDIManagerEvent):void
		{
			var window:MDIWindow = event.window;
			if (this.pod == window)
			{
				// show webview not snapshot in pod being restored
				webview.snapshotMode = false;
				webview.visible = true;
				callLater(laterValidate);
			}
		}
		
		protected function onDragStart(event:MDIManagerEvent):void
		{
			webview.snapshotMode = true;
		}
		
		protected function onDragEnd(event:MDIManagerEvent):void
		{				
			var window:MDIWindow = event.window;
			if  ( (this.pod == window) && (pod.windowState != MDIWindowState.MINIMIZED) )
			{
				webview.snapshotMode = false;
				callLater(laterValidate);
			}
		}
		
		protected function onResizerResizeStart(event:ResizeEvent):void
		{
			webview.snapshotMode = true;				
			webview.visible = false;
		}
		
		protected function onResizerResizeEnd(event:ResizeEvent):void
		{
			webview.width = Math.max(pod.contentGroup.width - widthOffset, 0);
			webview.height = Math.max(pod.contentGroup.height - heightOffset, 0);			
			
			webview.snapshotMode = false;				
			webview.visible = true;
			callLater(laterValidate);
		}
		
		protected function laterValidate():void
		{
			webview.invalidateDisplayList();
		}
		
		protected function onEffectEnd(event:Event):void
		{
			webview.width = Math.max(pod.contentGroup.width - widthOffset, 0);
			webview.height = Math.max(pod.contentGroup.height - heightOffset, 0);			
			
			callLater(laterValidate);
		}
		
		protected function onResize(event:ResizeEvent):void
		{
			webview.width = Math.max(pod.contentGroup.width - widthOffset, 0);
			webview.height = Math.max(pod.contentGroup.height - heightOffset, 0);		
			callLater(laterValidate);
		}		
		
		// cascade mode: goto non snapshot when select pod and bring to front
		// tile mode: goto non snapshot when select
		protected function onMdiFocusStart(event:MDIWindowEvent):void
		{
			var window:MDIWindow = event.window;
			if  ( (this.pod == window) && (pod.windowState != MDIWindowState.MINIMIZED) )
			{
				webview.snapshotMode = false;
			}
		}
		
		// lost being cascaded on top			
		protected function onMdiFocusEnd(event:MDIWindowEvent):void
		{
			var window:MDIWindow = event.window;
			if  (this.pod == window)
			{
				webview.snapshotMode = true;					
			}
		}
		
		protected function onCascadeStart(event:Event):void
		{
			tileMode = false;
			cascadeMode = true;
		}
		
		protected function onTile(event:Event):void
		{
			tileMode = true;
			cascadeMode = false;
		}		
				
				
	}
}