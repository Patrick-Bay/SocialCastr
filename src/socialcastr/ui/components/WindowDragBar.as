package socialcastr.ui.components {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.events.ApplicationEvent;
	import socialcastr.events.MovieClipButtonEvent;
	import socialcastr.events.PanelEvent;
	import socialcastr.ui.components.Tooltip;
	import socialcastr.ui.input.MovieClipButton;
	
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.core.instances.SwagMovieClip;
		
	/**
	 * An AIR-only class to supply window drag capabilities. Very rudimentary to use:
	 * 
	 * 1. Create a window drag bar in Flash or similar design tool as a Flash Movie Clip.
	 * 2. Assign this class to it.
	 *  
	 * The MIT License (MIT)
	 * 
	 * Copyright (c) 2014 Patrick Bay
	 * 
	 * Permission is hereby granted, free of charge, to any person obtaining a copy
	 * of this software and associated documentation files (the "Software"), to deal
	 * in the Software without restriction, including without limitation the rights
	 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	 * copies of the Software, and to permit persons to whom the Software is
	 * furnished to do so, subject to the following conditions:
	 * 
	 * The above copyright notice and this permission notice shall be included in
	 * all copies or substantial portions of the Software.
	 * 
	 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	 * THE SOFTWARE. 
	 */
	public class WindowDragBar extends MovieClip {
	
		private var _clip:SwagMovieClip;
		private var _overBar:Boolean=false;
		
		public function WindowDragBar()	{
			this.visible=false;
			this.alpha=0;
			References.desktopChromeElements.push(this);
			this.addListeners();
			super();
		}//constructor
		
		public function onPanelUpdate(eventObj:PanelEvent):void {
			this._clip.swapWithTop();
		}//onPanelUpdate
		
		private function onMousePress(eventObj:MouseEvent):void {
			if (!this._overBar) {
				return;
			}//if
			try {
				this.stage.nativeWindow.startMove();
			} catch (e:*) {
				trace ("WindowDragBar.onMousePress(): tried accessing the stage.nativeWindow object and it doesn't exist. Wrong runtime!");
				this.destroy();
			}//catch
		}//onMousePress
		
		private function onMouseRelease(eventObj:MouseEvent):void {
			if (!this._overBar) {
				return;
			}//if
			Settings.windowLocation=new Point(this.stage.nativeWindow.x, this.stage.nativeWindow.y);
		}//onMouseRelease
		
		private function onMouseMotion(eventObj:MouseEvent):void {
			if (this.hitTestPoint(eventObj.stageX, eventObj.stageY, true)) {
				Mouse.cursor=MouseCursor.BUTTON;
				this._overBar=true;
			} else {
				Mouse.cursor=MouseCursor.AUTO;
				this._overBar=false;
			}//else
		}//onMouseMotion
		
		public function monitorUIVisibility(eventObj:Event):void {
			if (References.main!=null) {
				this.alpha=References.main.alpha;
				this.visible=References.main.visible;
			}//if
		}//monitorUIVisibility		
		
		public function addListeners():void {
			//this.addEventListener(Event.ENTER_FRAME, this.monitorUIVisibility);
			this.stage.addEventListener(MouseEvent.MOUSE_DOWN, this.onMousePress);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, this.onMouseRelease);
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMotion);
			this._clip=new SwagMovieClip(this);			
			SwagDispatcher.addEventListener(PanelEvent.ONSHOW, this.onPanelUpdate, this, null);
			SwagDispatcher.addEventListener(PanelEvent.ONHIDE, this.onPanelUpdate, this, null);
			this.buttonMode=true;
			this.useHandCursor=true;
		}//addListeners
		
		private function destroy():void {
			this.stage.removeEventListener(MouseEvent.MOUSE_DOWN, this.onMousePress);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, this.onMouseRelease);
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMotion);
			this.removeEventListener(Event.ENTER_FRAME, this.monitorUIVisibility);
			SwagDispatcher.removeEventListener(PanelEvent.ONSHOW, this.onPanelUpdate, null);
			SwagDispatcher.removeEventListener(PanelEvent.ONHIDE, this.onPanelUpdate, null);
			this.buttonMode=false;
			this.useHandCursor=false;
			if (this._clip!=null) {
				this._clip.target=null;
				this._clip=null;
			}//if
			this.visible=false;
			this.alpha=0;
			this.parent.removeChild(this);
		}//destroy
		
		
	}//WindowDragBar class
	
}//package