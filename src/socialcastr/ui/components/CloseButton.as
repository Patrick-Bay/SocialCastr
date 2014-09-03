package socialcastr.ui.components {
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import socialcastr.References;
	import socialcastr.events.ApplicationEvent;
	import socialcastr.events.MovieClipButtonEvent;
	import socialcastr.events.PanelEvent;
	import socialcastr.ui.components.Tooltip;
	import socialcastr.ui.input.MovieClipButton;
	
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.core.instances.SwagMovieClip;
		
	
	/**
	 * An AIR-only class to provide application-closing services to SocialCastr.
	 * 
	 * See MovieClipButton for details on button structure.
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
	public class CloseButton extends MovieClipButton {
		
		private var _clip:SwagMovieClip;
		
		public function CloseButton() {	
			this.visible=false;
			this.alpha=0;
			this._clip=new SwagMovieClip(this);
			References.desktopChromeElements.push(this);
			//this.addEventListener(Event.ENTER_FRAME, this.monitorUIVisibility);
			SwagDispatcher.addEventListener(PanelEvent.ONSHOW, this.onPanelUpdate, this, null);
			SwagDispatcher.addEventListener(PanelEvent.ONHIDE, this.onPanelUpdate, this, null);
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onClick, this, this);
		}//constructor
		
		public function onPanelUpdate(eventObj:PanelEvent):void {
			this._clip.swapWithTop();
		}//onPanelUpdate
		
		public function monitorUIVisibility(eventObj:Event):void {
			if (References.main!=null) {
				this.alpha=References.main.alpha;
				this.visible=References.main.visible;
			}//if
		}//monitorUIVisibility
		
		public function onClick(eventObj:MovieClipButtonEvent):void {
			SwagDispatcher.dispatchEvent(new ApplicationEvent(ApplicationEvent.SHUTDOWN), this);
		}//onClick		
			
		override public function setDefaults(eventObj:Event):void {			
			var tooltip:Tooltip=new Tooltip(this, "Close", true);
			super.setDefaults(eventObj);
		}//setDefaults
		
	}//CloseButton class
	
}//package