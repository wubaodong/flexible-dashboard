/*
Copyright (c) 2007 FlexLib Contributors.  See:
    http://code.google.com/p/flexlib/wiki/ProjectContributors

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

package flexlib.mdi.containers
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import flex.utils.spark.resize.MoveManager;
	import flex.utils.spark.resize.ResizeHandleLines;
	import flex.utils.spark.resize.ResizeManager;
	
	import flexlib.mdi.events.MDIWindowEvent;
	import flexlib.mdi.managers.MDIManager;
	
	import mx.core.IVisualElementContainer;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	
	import spark.components.Button;
	import spark.components.HGroup;
	import spark.components.TitleWindow;
	import spark.components.ToggleButton;

	[SkinState("minimized")]
	
	//--------------------------------------
	//  Events
	//--------------------------------------

	/**
	 *  Dispatched when the minimize button is clicked.
	 *
	 *  @eventType flexlib.mdi.events.MDIWindowEvent.MINIMIZE
	 */
	[Event(name="minimize", type="flexlib.mdi.events.MDIWindowEvent")]

	/**
	 *  If the window is minimized, this event is dispatched when the titleBar is clicked.
	 * 	If the window is maxmimized, this event is dispatched upon clicking the restore button
	 *  or double clicking the titleBar.
	 *
	 *  @eventType flexlib.mdi.events.MDIWindowEvent.RESTORE
	 */
	[Event(name="restore", type="flexlib.mdi.events.MDIWindowEvent")]

	/**
	 *  Dispatched when the maximize button is clicked or when the window is in a
	 *  normal state (not minimized or maximized) and the titleBar is double clicked.
	 *
	 *  @eventType flexlib.mdi.events.MDIWindowEvent.MAXIMIZE
	 */
	[Event(name="maximize", type="flexlib.mdi.events.MDIWindowEvent")]

	/**
	 *  Dispatched when the close button is clicked.
	 *
	 *  @eventType flexlib.mdi.events.MDIWindowEvent.CLOSE
	 */
	[Event(name="closemdi", type="flexlib.mdi.events.MDIWindowEvent")]


	/**
	 * Central window class used in flexlib.mdi. Includes min/max/close buttons by default.
	 */
	public class MDIWindow extends TitleWindow
	{	
		[SkinPart(required="false")]
		public var controlsHolder:HGroup;
		
		[SkinPart(required="false")]
		public var minimizeButton:Button;
		
		[SkinPart(required="false")]
		public var maximizeRestoreButton:ToggleButton;		

		[SkinPart(required="false")]
		public var resizeHandle:ResizeHandleLines;
						
		/**
		 * Flag determining whether or not this window is resizable.
		 */
		public var resizable:Boolean = true;

		/**
		 * Flag determining whether or not this window is draggable.
		 */
		public var draggable:Boolean = true;

		/**
	     * Rectangle to represent window's size and position when resize begins
	     * or window's size/position is saved.
	     */
		public var savedWindowRect:Rectangle;

		/**
		 * Reference to MDIManager instance this window is managed by, if any.
	     */
		public var windowManager:MDIManager;

		public var resizeManager:ResizeManager;		
		public var moveManager:MoveManager;
		
		/**
		 * @private
		 * Internal storage for windowState property.
		 */
		private var _windowState:int;
		
		/**
		 * @private
		 * Internal storage of previous state, used in min/max/restore logic.
		 */
		private var _prevWindowState:int;
		
		/**
		 * @private
		 * Flag to determine whether or not window controls are visible.
		 */
		private var _showControls:Boolean = true;
		
		/**
		 * @private
		 * Storage var for hasFocus property.
		 */
		private var _hasFocus:Boolean;

		private static const DEFAULT_MINIMIZED_HEIGHT:Number = 22;

		
		/**
		 * Constructor
	     */
		public function MDIWindow()
		{
			super();
			minWidth = minHeight = 300;
			width = 400;
			height = 400;			
			windowState = MDIWindowState.NORMAL;
			doubleClickEnabled = true;

			resizable = true;
			setStyle("skinClass", MDIWindowSkin);
			
			addEventListener("creationComplete", onCreationComplete); 			
		}

		private function onCreationComplete(eventObj:Event):void
		{           
			addListeners();
			
			resizeManager = new ResizeManager(this, resizeHandle);
			moveManager = new MoveManager(this, UIComponent(moveArea));
			
			resizeHandle.visible = true;	
			resizeHandle.enabled = true;
			
			moveManager.constrainToParentBounds = true;
			resizeManager.constrainToParentBounds = true;		
			// have window content clipped when minimized
			contentGroup.clipAndEnableScrolling = true;	
            
            // fix problems with not getting custom context menus
            this.mouseEnabled = true;
            this.skin.mouseEnabled = true;
		}
		
		public function get hasFocus():Boolean
		{
			return _hasFocus;
		}
		
		/**
		 * Property is set by MDIManager when a window's focus changes. Triggers an update to the window's styleName.
		 */
		public function set hasFocus(value:Boolean):void
		{
			// guard against unnecessary processing
			if (_hasFocus == value)
			{
				return;
			}
			
			// set new value
			_hasFocus = value;
		}

		/**
		 * Add listeners for resize handles and window controls.
		 */
		private function addListeners():void
		{
			// titleBar 
			if (moveArea != null)
			{
				moveArea.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClickTitleBar, false, 0, true);
				moveArea.addEventListener(MouseEvent.CLICK, onClickTitleBar, false, 0, true);
			}			
			// minimize button handler			
			if (minimizeButton != null)
			{
				minimizeButton.addEventListener(MouseEvent.CLICK, onMinimizeButton, false, 0, true);				
			}
			// maximize/restore button handler
			if (maximizeRestoreButton != null)
			{
				maximizeRestoreButton.addEventListener(MouseEvent.CLICK, onMaximizeRestoreButton, false, 0, true);				
			}
			// close button handler
			addEventListener(CloseEvent.CLOSE, onCloseButton);			
			
			// clicking anywhere brings window to front
			addEventListener(MouseEvent.MOUSE_DOWN, bringToFrontProxy);			
		}

		/**
		 * Double click handler for titlebar
		 */
		protected function onDoubleClickTitleBar(event:MouseEvent):void
		{
			if (windowState == MDIWindowState.MINIMIZED)
			{
				unMinimize();
			}
			else
			{
				maximizeRestore();
			}
		}
		
		/**
		 * Click handler for titlebar
		 */
		protected function onClickTitleBar(event:MouseEvent):void
		{
			unMinimize();
		}

		/**
		 * Click handler for minimize button
		 */
		protected function onMinimizeButton(event:MouseEvent):void
		{
			minimize();
		}

		/**
		 * Click handler for maximize/restore button
		 */
		protected function onMaximizeRestoreButton(event:MouseEvent):void
		{
			maximizeRestore();
		}

		/**
		 * Close the window.
		 */	
		protected function onCloseButton(event:CloseEvent):void
		{
			var mdiWindowEvent:MDIWindowEvent = new MDIWindowEvent(MDIWindowEvent.CLOSE,this);
			dispatchEvent(mdiWindowEvent);
		}
		
		/**
		 *  Minimize the window.
		 */
		public function minimize():void
		{
			// if the panel is floating, save its state
			if (windowState == MDIWindowState.NORMAL)
			{
				savePanel();
			}
			
			var mdiWindowEvent:MDIWindowEvent = new MDIWindowEvent(MDIWindowEvent.MINIMIZE, this);
			dispatchEvent(mdiWindowEvent);

			windowState = MDIWindowState.MINIMIZED;
			height = this.minimizeHeight;					
			showControls = false;	
			invalidateSkinState();
			invalidateSize();
			
			resizable = false;
			draggable = false;			
			resizeManager.enabled = false;
			moveManager.enabled = false;
			resizeHandle.visible = false;	
			resizeHandle.enabled = false;						
		}

		/**
		 *  Called from maximize/restore button
		 *
		 */
		public function maximizeRestore():void
		{			
			if (windowState == MDIWindowState.NORMAL)
			{
				maximize();
			}
			else
			{
				restore();
			}
		}

		/**
		 * Restores the window to its last floating position.
		 */
		public function restore():void
		{
			dispatchEvent(new MDIWindowEvent(MDIWindowEvent.RESTORE, this));
			windowState = MDIWindowState.NORMAL;
			showControls = true;
			invalidateSkinState();	

			resizable = true;	
			draggable = true;				
			resizeManager.enabled = true;
			moveManager.enabled = true;
			resizeHandle.visible = true;	
			resizeHandle.enabled = true;				
		}

		/**
		 * Maximize the window.
		 */
		public function maximize():void
		{
			if (windowState == MDIWindowState.NORMAL)
			{
				savePanel();
			}

			if (parent != null)
			{
				// put on top of z order
				IVisualElementContainer(parent).setElementIndex(this, IVisualElementContainer(parent).numElements - 1);
			}
			
			dispatchEvent(new MDIWindowEvent(MDIWindowEvent.MAXIMIZE, this));
			
			
			windowState = MDIWindowState.MAXIMIZED;
			showControls = true;
			invalidateSkinState();
			resizable = false;
			draggable = false;
			if (resizeManager != null)
			{
				resizeManager.enabled = false;
			}
			if (moveManager != null)
			{
				moveManager.enabled = false;
			}
			resizeHandle.visible = false;	
			resizeHandle.enabled = false;	
			// set button select to get initial display of button correct
			// if start out with single window maximized
			maximizeRestoreButton.selected = true;		
		}
		
		/**
		 * Restore window to state it was in prior to being minimized.
		 */
		public function unMinimize():void
		{
			if (minimized)
			{
				restore();
				
				maximizeRestoreButton.selected = false;				
			}
		}		

		/**
		 * Save the panel's floating coordinates.
		 *
		 * @private
		 */
		private function savePanel():void
		{
			savedWindowRect = new Rectangle(this.x, this.y, this.width, this.height);
		}
	
		/**
		 * Called automatically by clicking on window this now delegates execution to the manager.
		 */
		private function bringToFrontProxy(event:Event):void
		{
			windowManager.bringToFront(this);
		}
		
		public function get showControls():Boolean
		{
			return _showControls;
		}

		public function set showControls(value:Boolean):void
		{
			if (value != _showControls)
			{
				if (controlsHolder != null)
				{
					_showControls = controlsHolder.visible = value;
				}
			}
		}

		public function get windowState():int
		{
			return _windowState;
		}

		public function set windowState(newState:int):void
		{
			_prevWindowState = _windowState;
			_windowState = newState;
		}

		public function get minimized():Boolean
		{
			return _windowState == MDIWindowState.MINIMIZED;
		}

		public function get maximized():Boolean
		{
			return _windowState == MDIWindowState.MAXIMIZED;
		}

		public function get minimizeHeight():Number
		{
			var minHeight:Number = DEFAULT_MINIMIZED_HEIGHT;
			if (moveArea != null)
			{
				minHeight = moveArea.height;
			}
			return minHeight;
		}

		override protected function getCurrentSkinState():String
		{ 
			var returnState:String = super.getCurrentSkinState();
			if (windowState == MDIWindowState.MINIMIZED)
			{
				returnState = "minimized";
			}
			return returnState;
		}			

	}
}