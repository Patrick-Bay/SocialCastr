package socialcastr.ui.components {
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import socialcastr.events.AnnounceChannelEvent;
	import socialcastr.events.ChannelListEvent;
	import socialcastr.ui.components.ChannelList;
	import socialcastr.ui.components.ChannelListItem;
	import socialcastr.ui.input.MovieClipButton;
	
	import swag.core.SwagDispatcher;
	
	/**
	 * Scrollbar thumb component for the <code>ChannelList</code> class. The current version of this component is assumed
	 * to exist alone (no up / down arrow buttons), and must be associated with a <code>ChannelList</code> instance to operate
	 * correctly.
	 * This class should be associated with a library item, preferably using 9-slice scaling since no graphical adjustments
	 * are made in this version.
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
	public class ChannelListScrollbarThumb extends MovieClipButton {		
		
		private var _parentList:ChannelList=null;
		private var _startScrollY:Number=new Number(0);
		private var _startMouseY:Number=new Number(0);
		private var _mouseDown:Boolean=false;
		
		public function ChannelListScrollbarThumb(parentList:ChannelList)	{
			this._parentList=parentList;
			super();
		}//constructor
		
		private function onThumbPress(eventObj:MouseEvent):void {		
			this._mouseDown=true;
			this._startScrollY=this.y;
			this._startMouseY=eventObj.stageY;
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onThumbMove);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, this.onThumbRelease);	
		}//onThumbPress
		
		private function onThumbMove(eventObj:MouseEvent):void {
			this.y=this._startScrollY-(this._startMouseY-eventObj.stageY);
			if (this.y<0) {
				this.y=0;
			}//if
			if (this.y>(this._parentList.listWindowHeight-this.height)) {
				this.y=this._parentList.listWindowHeight-this.height;
			}//if
			var percent:Number=this.y/(this._parentList.listWindowHeight-this.height);
			this._parentList.scrollToPercent(percent);
		}//onThumbMove
		
		private function onThumbRelease(eventObj:MouseEvent):void {			
			this._mouseDown=false;
			this._parentList.stopScrolling();
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onThumbMove);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, this.onThumbRelease);
		}//onThumbRelease
		
		public function updateHeight():void {
			this.height=this._parentList.listWindowHeight-(this._parentList.listWindowHeight*this._parentList.listVisiblePercent);
			this.x=this._parentList.listWindowWidth-this.width;
			if (this._parentList.listWindowHeight>=this._parentList.listWindowHeight) {
				this.visible=false;
			} else {
				this.visible=true;
			}//else
		}//updateHeight
		
		public function updatePosition():void {	
			this.y=(this._parentList.listWindowHeight-this.height)*this._parentList.listScrollPercent;
			this.x=this._parentList.listWindowWidth-this.width;
		}//updatePosition		
		
		override public function setDefaults(eventObj:Event):void {
			super.setDefaults(eventObj);
			if (this._parentList==null) {
				this.destroy();
			} else {				
				this.onButtonDown=this.onThumbPress;
				this.updateHeight();
				this.updatePosition();
			}//else
		}//setDefaults
		
		override public function destroy(... args):void {
			this.removeListeners();
			this.onButtonDown=null;
			this.onButtonUp=null;			
			super.destroy.call(super, args);
		}//destroy
		
	}//ChannelListScrollbarThumb class
	
}//package