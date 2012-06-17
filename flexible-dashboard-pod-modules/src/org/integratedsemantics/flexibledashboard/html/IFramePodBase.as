package org.integratedsemantics.flexibledashboard.html
{
	import com.esria.samples.dashboard.view.PodContentBase;
	import com.google.code.flexiframe.IFrame;
	
	import flash.events.Event;
	
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

	
	public class IFramePodBase extends PodContentBase
	{
		protected var html:IFrame;	
		protected var tileMode:Boolean = true;
		protected var cascadeMode:Boolean = false;
		protected var widthOffset:int = 10;		
		protected var heightOffset:int = 20;
		
		
		public function IFramePodBase()
		{
			super();
		}
		
		override protected function onCreationComplete(e:FlexEvent):void
		{
			super.onCreationComplete(e);
			
			html = new IFrame();
			html.id = properties.@id;
			html.label = properties.@title;    
			html.overlayDetection = true;
			html.percentHeight = 100;
			html.percentWidth = 100;
			html.verticalScrollPolicy = "off";
			html.horizontalScrollPolicy = "off";
			this.addElement(html);
			
			//html.debug = true;
			
			pod.addEventListener(MoveManager.DRAG_START, onDragStart);
			pod.addEventListener(MoveManager.DRAG_END, onDragEnd);
			
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
				html.visible = false;
				html.invalidateDisplayList();
			}
			else if ( (pod.windowState != MDIWindowState.MINIMIZED) && (cascadeMode == false) && (html.visible == false) )
			{
				// iframe may have been hidden when another windows was maximized
				html.visible = true;
				html.invalidateDisplayList();
			}			
		}
		
		protected function onMdiMaximize(event:MDIManagerEvent):void
		{
			var window:MDIWindow = event.window;
			if (this.pod != window)
			{
				// hide other iframes
				html.visible = false;
			}
		}
		
		protected function onMdiRestore(event:MDIManagerEvent):void
		{
			var window:MDIWindow = event.window;
			if (this.pod == window)
			{
				// show iframe in pod being restored
				html.visible = true;
				html.invalidateDisplayList();
			}
			else if ( (pod.windowState != MDIWindowState.MINIMIZED) && (cascadeMode == false) && (html.visible == false) )
			{
				// iframe may have been hidden when another windows was maximized
				html.visible = true;
				html.invalidateDisplayList();
			}
		}
		
		protected function onDragStart(event:Event):void
		{
			html.visible = false;
		}
		
		protected function onDragEnd(event:Event):void
		{
			html.visible = true;
			callLater(laterValidate);
		}
		
		protected function onResizerResizeStart(event:ResizeEvent):void
		{
			html.visible = false;
		}
		
		protected function onResizerResizeEnd(event:ResizeEvent):void
		{
			//html.width = Math.min(this.width, pod.contentGroup.width - widthOffset);
			//html.height = Math.min(this.height, pod.contentGroup.height - heightOffset);
			//html.width =  this.width;
			//html.height = this.height;
			html.width = pod.contentGroup.width - widthOffset;
			html.height = pod.contentGroup.height - heightOffset;
			
			html.visible = true;
			callLater(laterValidate);
		}
		
		protected function laterValidate():void
		{
			html.invalidateDisplayList();
		}
		
		protected function onEffectEnd(event:Event):void
		{
			html.width = pod.contentGroup.width - widthOffset;
			html.height = pod.contentGroup.height - heightOffset;
			
			callLater(laterValidate);
		}
		
		protected function onResize(event:ResizeEvent):void
		{
			//html.width = Math.min(this.width, pod.contentGroup.width - widthOffset);
			//html.height = Math.min(this.height, pod.contentGroup.height - heightOffset);
			//html.width =  this.width;
			//html.height = this.height;
			html.width = pod.contentGroup.width - widthOffset;
			html.height = pod.contentGroup.height - heightOffset;
			
			html.invalidateDisplayList();
		}		
		
		// cascaded to the top
		protected function onMdiFocusStart(event:MDIWindowEvent):void
		{
			var window:MDIWindow = event.window;
			if  ( (this.pod == window) && (cascadeMode == true) )
			{
				html.bringIFrameToFront();
				html.visible = true;
			}
		}
		
		// lost being cascaded on top			
		protected function onMdiFocusEnd(event:MDIWindowEvent):void
		{
			var window:MDIWindow = event.window;
			if  ( (this.pod == window) && (cascadeMode == true) )
			{
				html.visible = false;
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
			
			if ( (pod.windowState != MDIWindowState.MINIMIZED) && (html.visible == false) )
			{
				html.visible = true;
				callLater(laterValidate);				
			}
		}		
						
	}
}