package socialcastr.ui.panels {
	
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.events.AnnounceChannelEvent;
	import socialcastr.interfaces.ui.IPanelContent;
	import socialcastr.ui.Panel;
	import socialcastr.ui.PanelContent;
	import socialcastr.ui.components.Tooltip;
	
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
	public class TextChatPanel extends PanelContent implements IPanelContent {
		
		public function TextChatPanel(parentPanelRef:Panel)	{
			References.textChatChannel=this;
			super(parentPanelRef);
		}//constructor
		
		private function populateFields():void {
			this.populateFields();
			this.addListeners();
		}//populateFields
		
		public function startChat():void {
			
		}//startChat
		
		public function onAnnounceChannelConnect(eventObj:AnnounceChannelEvent):void {			
			this.startChat();
		}//onAnnounceChannelConnect
		
		private function addListeners():void {
			
		}//addListeners
		
		private function removeListeners():void {
			
		}//removeListeners
		
		override public function initialize():void {
			if ((Settings.getSCID()==null) || (Settings.getSCID()=="") || (Settings.getCCID()==null) || (Settings.getCCID()=="")) {
				SwagDispatcher.addEventListener(AnnounceChannelEvent.ONCONNECT, this.onAnnounceChannelConnect, this);
			} else {
				if (References.announceChannel.connected) {
					this.startChat();
				} else {
					SwagDispatcher.addEventListener(AnnounceChannelEvent.ONCONNECT, this.onAnnounceChannelConnect, this);	
				}//else
			}//else			
		}//initialize
		
	}//TextChatPanel class
	
}//package