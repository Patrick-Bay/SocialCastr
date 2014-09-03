package socialcastr.ui {
	
	import flash.display.MovieClip;
	
	import socialcastr.events.SocialCastrErrorEvent;
	import socialcastr.interfaces.ui.IPanel;
	import socialcastr.interfaces.ui.IPanelContent;
	
	import swag.core.SwagDispatcher;
	
	/* 
	 * Base class for any panel content movie clip.
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
	dynamic public class PanelContent extends MovieClip implements IPanelContent {
		
		private var _parentPanel:IPanel;
		private var _panelData:XML;
		
		public function PanelContent(parentPanelRef:Panel) {
			this.parentPanel=parentPanelRef;
			super();
		}//constructor
		
		public function initialize():void {
			//In short: override this method!
			var error:SocialCastrErrorEvent = new SocialCastrErrorEvent(SocialCastrErrorEvent.APPERRORNONFATAL);
			error.description="PanelConent ("+this+").initialize: The default \"initialize\" routine indicates that this PanelContent ";
			error.description+="instance may not have initialized / started correctly.";
			error.remedy="Ensure that the PanelContent class \""+this+"\" includes an \"override public function initialize():void\" method ";
			error.remedy+="and ensure that the method does NOT call \"super();\".";
			SwagDispatcher.dispatchEvent(error, this);
		}//initialize
		
		public function destroy():void {
			
		}//destroy			
		
		public function get panelID():String {
			if (this._parentPanel==null){
				return (null);
			}//if
			return (this._parentPanel.panelID);
		}//get panelID
		
		public function set parentPanel(panelSet:IPanel) {			
			this._parentPanel=panelSet;
		}//set parentPanel
		
		public function get parentPanel():IPanel {
			return (this._parentPanel);
		}//get parentPanel
		
		public function set panelData(dataSet:XML) {
			this._panelData=dataSet;
		}//set panelData
		
		public function get panelData():XML {
			return (this._panelData);
		}//get paneldata
		
		public function onShow(direction:String=null):void {
			//Override as required
		}//onShow
		
		public function onShowDone(direction:String=null):void {
			//Override as required
		}//onShowDone
		
		public function onHide(direction:String=null):void {
			//Override as required
		}//onHide
		
		public function onHideDone(direction:String=null):void {
			//Override as required
		}//onHideDone
		
		
	}//PanelContent class
	
}//package