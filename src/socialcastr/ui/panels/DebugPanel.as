package socialcastr.ui.panels {
	
	import fl.controls.Button;
	import fl.controls.TextArea;
	
	import flash.events.MouseEvent;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.interfaces.ui.IPanel;
	import socialcastr.interfaces.ui.IPanelContent;
	import socialcastr.ui.Panel;
	import socialcastr.ui.PanelContent;
	import socialcastr.ui.panels.NotificationPanel;
	
	import swag.core.SwagDispatcher;
	import swag.events.SwagErrorEvent;
	
	/**
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
	public class DebugPanel extends PanelContent implements IPanelContent {
		
		public var debugText:TextArea;
		public var resetSettingsButton:Button;
		private var _suspendedPanels:Array;
		
		public function DebugPanel(parentPanelRef:Panel) {
			References.debugPanel=this;
			super(parentPanelRef);
		}//constructor
		
		override public function initialize():void {
			this.debug(Settings.applicationName+" v"+Settings.version.major+"."+Settings.version.minor);
			if (this.stage==null) {
				this.debug("DebugPanel active, no UI (trace only).");
			} else {
				this.debug("DebugPanel active, UI and trace.");
			}//else
			if (this.resetSettingsButton!=null) {
				this.resetSettingsButton.addEventListener(MouseEvent.CLICK, this.onResetClick);
			}//if
			SwagDispatcher.addEventListener(SwagErrorEvent.ERROR, this.onSwagErrorEvent);
			SwagDispatcher.addEventListener(SwagErrorEvent.DATAEMPTYERROR, this.onSwagErrorEvent);
			SwagDispatcher.addEventListener(SwagErrorEvent.DATAFORMATERROR, this.onSwagErrorEvent);
			SwagDispatcher.addEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, this.onSwagErrorEvent);
			SwagDispatcher.addEventListener(SwagErrorEvent.UNSUPPORTEDOPERATIONERROR, this.onSwagErrorEvent);
		}//initialize
		
		private function onResetClick(eventObj:MouseEvent):void {
			Settings.resetSettings();	
			//var notification:NotificationPanel=References.panelManager.togglePanel("notification", false) as NotificationPanel;
			//notification.updateMessageText("Close the application now to start a fresh session.");
		}//onResetClick
		
		public function onSwagErrorEvent(eventObj:SwagErrorEvent):void {
			this.debug("SwAG Error ("+String(eventObj.code)+") in "+eventObj.source);
			this.debug("   "+eventObj.description);
			this.debug("   "+eventObj.remedy);
		}//onSwagError
		
		public function debug (textSet:String):void {
			if (this.debugText!=null) {
				this.debugText.appendText(textSet+"\n");
				this.debugText.verticalScrollPosition=this.debugText.maxVerticalScrollPosition;
			}//if
			trace (textSet);
		}//set text
		
		
	}//DebugPanel class
	
}//package
