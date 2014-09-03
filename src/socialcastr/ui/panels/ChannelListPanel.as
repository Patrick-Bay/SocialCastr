package socialcastr.ui.panels {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.events.AnnounceChannelEvent;
	import socialcastr.interfaces.ui.IPanel;
	import socialcastr.ui.Panel;
	import socialcastr.ui.PanelContent;
	import socialcastr.ui.components.ChannelList;
	import socialcastr.ui.components.ChannelListItem;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.core.instances.SwagMovieClip;
	import swag.events.SwagMovieClipEvent;
	
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
	public class ChannelListPanel extends PanelContent {
		
		private var _channelList:ChannelList=null;
		
		public function ChannelListPanel(parentPanelRef:Panel) {
			super(parentPanelRef);
		}//constructor
		
		public function onReceivedNewListItem(eventObj:AnnounceChannelEvent):void {
			this.channelList.addListItem(eventObj);
		}//onReceivedNewListItem
		
		public function get channelList():ChannelList {
			if (this._channelList==null) {
				this._channelList=new ChannelList();				
			}//if
			if (!this.contains(this._channelList)) {
				this.addChild(this._channelList);
			}//if, this.
			return (this._channelList);
		}//get channelList
		
		public function onShareProgress():void {
			
		}///onShareProgress
		
		public function onShareComplete():void {
			
		}///onShareComplete
		
		override public function initialize():void {			
			if (References.announceChannel==null) {
				return;
			}//if
			SwagDispatcher.addEventListener(AnnounceChannelEvent.ONAVCHANNELINFO, this.onReceivedNewListItem, this); //Broadcast from peer
			SwagDispatcher.addEventListener(AnnounceChannelEvent.ONAVCHANNELCONNECT, this.onReceivedNewListItem, this);
			References.announceChannel.requestAVChannels(false, false);
		}//initialize
		
	}//ChannelList class
	
}//package