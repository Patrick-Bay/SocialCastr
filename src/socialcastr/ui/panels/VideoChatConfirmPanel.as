package socialcastr.ui.panels {
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.None;
	
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	
	import socialcastr.References;
	import socialcastr.events.MovieClipButtonEvent;
	import socialcastr.events.VideoChatConfirmEvent;
	import socialcastr.interfaces.ui.IPanelContent;
	import socialcastr.ui.Panel;
	import socialcastr.ui.PanelContent;
	import socialcastr.ui.input.MovieClipButton;
	
	import swag.core.SwagDataTools;
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
	public class VideoChatConfirmPanel extends PanelContent implements IPanelContent {
		
		public var messageText:TextField;
		
		public var okayButton:MovieClipButton;
		public var refuseButton:MovieClipButton;
		public var userImage:MovieClip;
		public var userImageMask:MovieClip;
		
		private var _remoteUserImageLoader:Loader;
		
		private var _imagefadeTween:Tween;
		private var _loadingFadeTween:Tween;
		
		public var loadingArrow:MovieClip;
		
		public function VideoChatConfirmPanel(parentPanelRef:Panel)		{
			super(parentPanelRef); 
		}//constructor
		
		public function onOkayClick(eventObj:MovieClipButtonEvent):void {
			Panel(this.parentPanel).setModalMode(false);
			var event:VideoChatConfirmEvent=new VideoChatConfirmEvent(VideoChatConfirmEvent.ALLOW);
			SwagDispatcher.dispatchEvent(event, this);
			References.panelManager.togglePanel(this.parentPanel.panelID, false);			
		}//onOkayClick
		
		public function onRefuseClick(eventObj:MovieClipButtonEvent):void {
			Panel(this.parentPanel).setModalMode(false);
			var event:VideoChatConfirmEvent=new VideoChatConfirmEvent(VideoChatConfirmEvent.REFUSE);
			SwagDispatcher.dispatchEvent(event, this);
			References.panelManager.togglePanel(this.parentPanel.panelID, false);			
		}//onRefuseClick
		
		public function updateRemoteUserData(userData:Object):void {
			if (this.userImage!=null) {
				this._remoteUserImageLoader=null;
				this.removeChild(this.userImage);
				this.userImage=null;
			}//if
			if (userData.remoteUserImage!=null) {
				this._remoteUserImageLoader=new Loader();
				this._remoteUserImageLoader.contentLoaderInfo.addEventListener(Event.INIT, this.onUpdateRemoteUserImage);
				this._remoteUserImageLoader.loadBytes(userData.remoteUserImage);
			}//if
			var connectMessage:String=this.userConnectMessage;
			connectMessage=SwagDataTools.replaceString(connectMessage, userData.socialName, "%username%");
			connectMessage=SwagDataTools.replaceString(connectMessage, userData.groupName, "%group_name%");
			this.messageText.text=connectMessage;
		}//updateRemoteUserImage
		
		private function get userConnectMessage():String {
			var returnMessage:String=new String();
			if (SwagDataTools.isXML(this.panelData.message)) {
				var messageNode:XML=this.panelData.message[0] as XML;
				returnMessage=String(messageNode.children().toString());
			}//if
			return (returnMessage);
		}//get userConnectMessage
		
		public function updateMessageText(newText:String):void {
			this.messageText.text=newText;
		}//updateMessageText
		
		public function onUpdateRemoteUserImage(eventObj:Event):void {
			this._remoteUserImageLoader.contentLoaderInfo.removeEventListener(Event.INIT, this.onUpdateRemoteUserImage);
			this.userImage=new MovieClip();
			this.addChild(this.userImage);
			this.userImage.addChild(this._remoteUserImageLoader.content);
			//this.loadingArrow.visible=false;
			/*
			if (this._imagefadeTween!=null) {
				this._imagefadeTween.stop();
				this._imagefadeTween=null;
			}//if
			if (this._loadingFadeTween!=null) {
				this._loadingFadeTween.stop();
				this._loadingFadeTween=null;
			}//if
			this._imagefadeTween=new Tween(this.userImage, "alpha", None.easeNone, this.userImage.alpha, 1, 1, true);
			this._loadingFadeTween=new Tween(this.loadingArrow, "alpha", None.easeNone, this.loadingArrow.alpha, 0, 1, true);
			*/
			this.userImage.width=this.userImageMask.width;
			this.userImage.height=this.userImageMask.height;	
			this.userImage.x=this.userImageMask.x;
			this.userImage.y=this.userImageMask.y;
			this.userImage.mask=this.userImageMask;
		}//onUpdateRemoteUserImage
		
		private function addListeners():void {
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onOkayClick, this, this.okayButton);
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onRefuseClick, this, this.refuseButton);
		}//addListeners
		
		private function removeListeners():void {
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onOkayClick, this.okayButton);
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onRefuseClick, this.refuseButton);
		}//removeListeners
		
		override public function initialize():void {
			if (this.loadingArrow!=null) {
				this.loadingArrow.alpha=1;
			}//if
			this.addListeners();
		}//initialize
		
	}//VideoChatConfirmPanel class
	
}//package