package socialcastr.ui.components {
	
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.events.AnnounceChannelEvent;
	import socialcastr.events.ChannelListEvent;
	import socialcastr.ui.PanelContent;
	import socialcastr.ui.components.ChannelListItem;
	import socialcastr.ui.components.ChannelListScrollbarThumb;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.instances.SwagMovieClip;
	
	/**
	 * Creats a list of <code>ChannelListItem</code> instances, providing them with centralized information and
	 * support for alternative scrolling mechanisms such asth scroll bar and mouse wheel.
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
	public class ChannelList extends SwagMovieClip {		
		
		private static var _channelLists:Vector.<ChannelList>=new Vector.<ChannelList>();

		private var _listItems:Vector.<ChannelListItem>=new Vector.<ChannelListItem>();
		private var _visibleListItems:Vector.<ChannelListItem>=new Vector.<ChannelListItem>();
		private var _currentScrollFrame:Vector.<ChannelListItem>=new Vector.<ChannelListItem>();
		private var _listContainer:MovieClip=null;
		private var _scrollThumb:ChannelListScrollbarThumb=null;
		private var _currentSnapIndex:int=0;
		private var _listScrolling:Boolean=false;
		private var _listMask:Shape=null;
		private var _listX:Number=new Number(0);
		private var _listY:Number=new Number(0);
		private var _listWindowWidth:Number=new Number(375);
		private var _listWindowHeight:Number=new Number(400);
		private var _lastMotionDirection:String=new String();
		
		//List-specific references (managed by ChannelListItem class)
		private var _currentTopListItem:ChannelListItem=null;				
		
		public function ChannelList() {
			this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			this.addEventListener(Event.REMOVED_FROM_STAGE, this.destroy);
			_channelLists.push(this);
			super();
		}//constructor
		
		/** 
		 * @private 		 
		 */
		private function alignToPanel():void {
			if (this.parent==null) {
				return;
			}//if
			this.x=this._listX;
			this.y=this._listY;		
		}//aligntToPanel
		
		/** 
		 * @private 		 
		 */
		private function onMouseWheel(eventObj:MouseEvent):void {
			if (this.currentTopListItem!=null) {
				var targetPosition:int=int(Math.round((eventObj.delta)*-1))+this.currentTopListItem.index;
				this.currentTopListItem.scrollToPosition(targetPosition);
			}//if
		}//onMouseWheel
		
		public function updateOnScroll(... args):void {
			if (this._scrollThumb!=null) {
				this._scrollThumb.updatePosition();
			}//if
			var eventObj:ChannelListEvent=new ChannelListEvent(ChannelListEvent.LISTSCROLLING);
			SwagDispatcher.dispatchEvent(eventObj, this);
		}//updateOnScroll
		
		public function updateOnListChange(... args):void {
			if (this._scrollThumb!=null) {
				this._scrollThumb.updateHeight();
			}//if
			var eventObj:ChannelListEvent=new ChannelListEvent(ChannelListEvent.LISTCHANGED);
			SwagDispatcher.dispatchEvent(eventObj, this);
		}//updateOnListChange
		
		/**
		 * Creates a new <code>ChannelListItem</code> using the data provided in the supplied announce channel event.
		 *  
		 * @param itemData An <code>AnnounceChannelEvent</code> containing information for the new <code>ChannelListItem</code>
		 * instance. If <em>null</em>, omitted, or otherwise invalid, the item is immediately removed from memory. 
		 * 
		 */
		public function addListItem(itemData:AnnounceChannelEvent):void {
			var listItem:ChannelListItem=new ChannelListItem(this);
			listItem.create(itemData);
			this.listContainer.addChild(listItem);
			this.updateOnListChange();
		}//addListItem
		
		/**
		 * Scrolls the list to a specific location based on a percentage (rather than index),
		 * from 0 to 1. 
		 * 
		 * @param percent The percentage to scroll the list to, with 0 being the tp and 0 being the bottom.
		 * 
		 */
		public function scrollToPercent(percent:Number):void {
			var itemIndex:int=int(Math.round(this.listItems.length*percent));
			if (this.currentTopListItem!=null) {
				this.currentTopListItem.scrollToPosition(itemIndex);
			}//if
		}//scrollToPercent
		
		public function stopScrolling():void {
			this.currentSnapIndex=this.currentTopListItem.index;
		}//stopScrolling
		
		/** 
		 * @private 		 
		 */
		private function get listMask():Shape {
			if (this._listMask==null) {
				this._listMask=new Shape();
				this._listMask.graphics.moveTo(0,0);
				this._listMask.graphics.lineStyle(0, 0x000000, 0, true);
				this._listMask.graphics.beginFill(0x00FF00, 0);
				this._listMask.graphics.lineTo(this._listWindowWidth, 0);
				this._listMask.graphics.lineTo(this._listWindowWidth, this._listWindowHeight);
				this._listMask.graphics.lineTo(0, this._listWindowHeight);
				this._listMask.graphics.lineTo(0, 0);
				this._listMask.graphics.endFill();
			}//if
			return (this._listMask);
		}//get listMask
		
		/**
		 * @param itemSet The current <code>ChannelList</code> item that currently appears at the top of the
		 * list. Note that this is not necessarily the first item in the list. If an attempt is made to
		 * set this value by a list item not belonging to this list, it is ignored.	 
		 */
		public function set currentTopListItem(itemSet:ChannelListItem):void {
			try {
				if (itemSet.parentList==this) {
					this._currentTopListItem=itemSet;
				}//if
			} catch (e:*) {				
			}//if
		}//set currentTopListItem
		
		public function get currentTopListItem():ChannelListItem {
			if (this._currentTopListItem==null) {
				try {
					this._currentTopListItem=this.listItems[0] as ChannelListItem;
				} catch (e:*) {					
				}//catch
			}//if
			return (this._currentTopListItem);
		}//get currentTopListItem
		
		/**
		 * @return The final item currently visible list. This is determined dynamically from the current top list item
		 * so no setter is available.		 
		 */
		public function get currentBottomListItem():ChannelListItem {
			if (this.currentTopListItem!=null) {
				var currentItem:ChannelListItem=this.currentTopListItem;
				while (currentItem.visible) {
					if (currentItem.nextItem!=null) {
						currentItem=currentItem.nextItem;
					} else {
						return (currentItem.lastItem);
					}//else
				}//while
				return (currentItem.previousItem);
			}//if
			return (null);
		}//get currentBottomListItem
		
		/**		 
		 * @return The containing movie clip instance into which all the <code>ChannelListItem</code> instances are generated. 
		 */
		public function get listContainer():MovieClip {
			if (this._listContainer==null) {
				this._listContainer=new MovieClip();				
			}//if
			if (!this.contains(this._listContainer)) {
				this.addChild(this._listContainer);
			}//if
			return (this._listContainer);
		}//get listContainer
		
		public function get listWidth():Number {
			var widthValue:Number=new Number(0);
			for (var count:uint=0; count<this.listItems.length; count++) {
				var currentItem:ChannelListItem=this.listItems[count] as ChannelListItem;
				if (currentItem.width>widthValue) {
					widthValue=currentItem.width;
				}//if
			}//for
			return (widthValue);
		}//get listWidth
		
		public function get listHeight():Number {
			var heightValue:Number=new Number(0);
			for (var count:uint=0; count<this.listItems.length; count++) {
				var currentItem:ChannelListItem=this.listItems[count] as ChannelListItem;
				heightValue+=currentItem.height;
			}//for
			return (heightValue);
		}//get listHeight
		
		public function set lastMotionDirection(directionSet:String):void {
			this._lastMotionDirection=directionSet;
		}//get lastMotionDirection
		
		public function get lastMotionDirection():String {
			return (this._lastMotionDirection);
		}//get lastMotionDirection
		
		/**
		 * 
		 * @return The percentage of the whole list currently visible (0 to 1). This
		 * value can be used to determine the height of scroll bar thumbs, for example. 
		 * 
		 */
		public function get listVisiblePercent():Number {
			var percentVal:Number=new Number();
			percentVal=this.listHeight/this.listWindowHeight;
			return (percentVal);
		}//get listVisiblePercent
		
		/**
		 * 
		 * @return The percentage of the the list position. In other
		 * words, when the list is at the beginning the percent is 0,
		 * when at the end it's 1.
		 * 
		 */
		public function get listScrollPercent():Number {
			var percentVal:Number=new Number(0);
			for (var count:uint=0; count<this.listItems.length; count++) {
				var currentItem:ChannelListItem=this.listItems[count] as ChannelListItem;
				if (currentItem==this.currentTopListItem) {
					percentVal=count/this.listItems.length;
					return (percentVal);
				}//if
			}//for
			return (percentVal);
		}//get listScrollPercent
		
		/**
		 * @return The height of the list's visible area (window), in pixels. Note that the list may be larger or smaller than this.	 
		 */
		public function get listWindowHeight():Number {
			return (this._listWindowHeight);
		}//get listWindowHeight
		
		/**
		 * @return The width of the list's visible area (window), in pixels. Note that the list may be larger or smaller than this.	 
		 */
		public function get listWindowWidth():Number {
			return (this._listWindowWidth);
		}//get listWindowWidth
		
		/** 
		 * @private 		 
		 */
		private function parseListDimensionData():void {
			var panelNode:XML=Settings.getPanelDefinitionByID("channel_list", false);
			if (!SwagDataTools.isXML(panelNode)) {
				return;
			}//if
			var listNode:XML=panelNode.list[0] as XML;
			if (!SwagDataTools.isXML(listNode)) {
				return;
			}//if
			if (SwagDataTools.isXML(listNode.@x)) {
				var tempNum:Number=new Number(listNode.@x);
				if (!isNaN(tempNum)) {
					this._listX=tempNum;
				}//if
			}//if
			if (SwagDataTools.isXML(listNode.@y)) {
				tempNum=new Number(listNode.@y);
				if (!isNaN(tempNum)) {
					this._listY=tempNum;
				}//if
			}//if
			if (SwagDataTools.isXML(listNode.@width)) {
				tempNum=new Number(listNode.@width);
				if (!isNaN(tempNum)) {
					this._listWindowWidth=tempNum;
				}//if
			}//if
			if (SwagDataTools.isXML(listNode.@height)) {
				tempNum=new Number(listNode.@height);
				if (!isNaN(tempNum)) {
					this._listWindowHeight=tempNum;
				}//if
			}//if
		}//parseListDimensionData
		
		/** 
		 * @private 		 
		 */
		private function setDefaults(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			this.parseListDimensionData();
			this.addChild(this.listMask);
			this.listContainer.mask=this.listMask;
			this.alignToPanel();
			this._scrollThumb=new ChannelListScrollbarThumb(this);		
			this.addChild(this._scrollThumb);
			this.stage.addEventListener(MouseEvent.MOUSE_WHEEL, this.onMouseWheel);			
		}//setDefaults
		
		/**
		 * Causes the lists' internal list of items to be updated whenever one (or more) is removed or added.
		 * This method is typically invoked by the list's <code>ChannelListItem</code> instances whenever they are
		 * added or removed. Calling this method too often causes significant slow-downs.		 
		 */
		public function updateListItems():void {
			_listItems=ChannelListItem.getItemsForList(this);
		}//updateListItems
		
		/**
		 * @return The list of <code>ChannelListItem</code> instances associated with this list. Note that it is possible
		 * for this list to be out-of-date momentarily if it's being references while a new items is being added or removed.
		 * If this occurs, incoke the <code>updateListItems</code> method to ensure the list is up to date.		 
		 */
		public function get listItems():Vector.<ChannelListItem> {
			if (_listItems==null) {
				_listItems=new Vector.<ChannelListItem>();
			}//if
			return (_listItems);
		}//get listItems
		
		/**
		 * @return The list of all the visible <code>ChannelListItem</code> items associated with this list.
		 */
		public function get visibleListItems():Vector.<ChannelListItem> {
			if (_visibleListItems==null) {
				_visibleListItems=new Vector.<ChannelListItem>();
			}//if
			return (_visibleListItems);
		}//get visibleListItems
		
		/**
		 * @return A list of items currently being displayed in the list window. Note that this
		 * is not necessarily the whole list of items associated with the list.		 
		 */
		public function get currentScrollFrame():Vector.<ChannelListItem> {
			return (this._currentScrollFrame);
		}//get currentScrollFrame
				
		
		/**
		 * @return Returns a list of all the current <code>ChannelList</code> instances currently in memory and on the display stack.		 
		 */
		public static function get channelLists():Vector.<ChannelList> {
			if (_channelLists==null) {
				_channelLists=new Vector.<ChannelList>();
			}//if
			return (_channelLists);
		}//get channelLists
		
		public function set currentSnapIndex(indexSet:int):void {
			this._currentSnapIndex=indexSet;
		}//set currentSnapIndex
		
		public function get currentSnapIndex():int {
			return (this._currentSnapIndex);
		}//get currentSnapIndex
		
		public function set listScrolling(scrollSet:Boolean):void {
			this._listScrolling=scrollSet;
		}//set listScrolling
		
		public function get listScrolling():Boolean {
			return (this._listScrolling);
		}//get listScrolling
		
		/**
		 * Destroys the channel list and all associated channel list items, removing them all from memory and the display stack.
		 *  
		 * @param args Any parameters are valid.
		 * 
		 */
		public function destroy(... args):void {
			this.removeEventListener(Event.REMOVED_FROM_STAGE, this.destroy);
			var ownListItems:Vector.<ChannelListItem>=ChannelListItem.getItemsForList(this);
			for (var count:uint=0; count<ownListItems.length; count++) {
				var currentListItem:ChannelListItem=ownListItems[count] as ChannelListItem;
				currentListItem.destroy();
			}//for
			ownListItems=null;
			var compactList:Vector.<ChannelList>=new Vector.<ChannelList>;
			for (count=0; count<channelLists.length; count++) {
				var currentItem:ChannelList=channelLists[count] as ChannelList;
				if (currentItem!=this) {
					compactList.push(currentItem);
				}//if
			}//for
			if (this.parent!=null) {
				if (this.parent.contains(this)) {
					this.parent.removeChild(this);
				}//if
			}//if
			_channelLists=compactList;
		}//destroy
		
	}//ChannelList class
	
}//package