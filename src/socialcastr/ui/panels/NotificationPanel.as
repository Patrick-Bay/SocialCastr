package socialcastr.ui.panels {
		
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.ByteArray;
	
	import socialcastr.References;
	import socialcastr.events.MovieClipButtonEvent;
	import socialcastr.interfaces.ui.IPanelContent;
	import socialcastr.ui.Panel;
	import socialcastr.events.PanelEvent;
	import socialcastr.ui.PanelContent;
	import socialcastr.ui.input.MovieClipButton;
	
	import swag.core.SwagDispatcher;
	
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
	public class NotificationPanel extends PanelContent implements IPanelContent {
		
		public var messageText:TextField;
		private var _messagetext:String=new String();
		private var _messageTextStartY:Number;
		public var okayButton:MovieClipButton;	
		
		public function NotificationPanel(parentPanelRef:Panel)		{
			super(parentPanelRef); 
		}//constructor
		
		public function onOkayClick(eventObj:MovieClipButtonEvent):void {
			Panel(this.parentPanel).setModalMode(false);			
			References.panelManager.togglePanel(this.panelID, false);
			//SwagDispatcher.addEventListener(PanelEvent.ONHIDE, this.destroy, this, this.parentPanel);			
		}//onOkayClick
				
		
		public function updateMessageText(newText:String):void {
			this._messagetext=newText;
			if (this.messageText!=null) {
				this.messageText.autoSize=TextFieldAutoSize.CENTER;
				this.messageText.multiline=true;
				this.messageText.wordWrap=true;
				this.messageText.text=this._messagetext;
			}//if			
		}//updateMessageText
		
			private function addListeners():void {
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onOkayClick, this, this.okayButton);			
		}//addListeners
		
		private function removeListeners():void {
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onOkayClick, this.okayButton);		
		}//removeListeners
		
		override public function initialize():void {	
			this.addListeners();
			this._messageTextStartY=this.messageText.y+this.messageText.height;
			if (this._messagetext!=null) {
				this.updateMessageText(this._messagetext);
			}//if			
		}//initialize
		
		override public function destroy():void {
			this.removeListeners();
			SwagDispatcher.removeEventListener(PanelEvent.ONHIDE, this.destroy, this.parentPanel);						
			super.destroy();
		}//destroy
		
	}//NotificationPanel class
	
}//package