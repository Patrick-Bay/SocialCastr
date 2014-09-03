package socialcastr.ui.components {
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.Bounce;
	import fl.transitions.easing.None;
	import fl.transitions.easing.Regular;
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.BlurFilter;
	import flash.text.TextField;
	import flash.ui.Mouse;
	import flash.utils.Timer;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.events.AnnounceChannelEvent;
	import socialcastr.events.ChannelListEvent;
	import socialcastr.ui.components.ChannelList;
	import socialcastr.ui.panels.ChannelListPanel;
	import socialcastr.ui.panels.ChannelPlayerPanel;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.instances.SwagMovieClip;
	import swag.events.SwagCloudEvent;
	import swag.events.SwagMovieClipEvent;
		
	/**
	 * Contains and controls a list item associated with a specific channel. A channel list item typically appears as 
	 * part of a scrollable list and therefore includes many self-controlling list features and relative references such
	 * that the parent list (the <code>ChannelList</code> instance), only needs to provide a display mask if desired.
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
	public class ChannelListItem extends SwagMovieClip {
		
		public const iconLeftMargin:Number=10;
		public const iconTopMargin:Number=10;
		/**
		 * Updates at this rate to determine the delta, or distance dragged. If below the threshhold, it's considered a click,
		 * otherwise it's considered to be an attempt to scroll the list.
		 * These values can be made set-able as list "sensitivity" parameters,
		 */		
		public const dragSamplingRate:Number=95; //ms
		public const dragSpeedThreshhold:Number=20; //item is accelerating (dragging) if moved this fast (pixels per dragSamplingRate)
		public const dragDistanceThreshhold:Number=10; //item is dragging if moved this far 
		
		public var loadingPlaceholder:MovieClip;
		public var background:MovieClip;		
		public var channelName:TextField;
		public var channelDescription:TextField;
				
		//Stores reference to *all* list items. Check the parentList property to see which list each item belongs to.
		private static var _allListItems:Vector.<ChannelListItem>=new Vector.<ChannelListItem>();				
		private var _channelInfo:Object=null;		
		private var _channelPeerID:String=new String();
		private var _channelIcon:Bitmap=null;
		private var _parentList:ChannelList=null;
		private var _backgroundPlayback:SwagMovieClip;
		private var _mouseDown:Boolean=false;
		private var _mouseOver:Boolean=false;
		private var _dragSampleTimer:Timer;
		private var _dragSampleDelta:Number=new Number(0);		
		private var _dragCounter:Number=new Number(0);
		private var _dragSampleY:Number=new Number(0);
		private var _dragStartY:Number=new Number(0);
		private var _startPositionY:Number=new Number(0);
		private var _accelerationActive:Boolean=false; //True if drag is fast enough to be considered acceleration
		private var _accelerationFactor:Number=new Number(0); //Updated based on the acceleration sampler. The larger the number, the more
		//items we need to scroll.
		private var _dragActive:Boolean=false; //True if drag is fast enough to be considered acceleration
		private var _iconTween:Tween=null;
		private var _snapTween:Tween=null;
		private var _blurFilter:BlurFilter=null;
		private var _snapOutTween:Tween=null;
		private var _destroyTween:Tween;
		
		public function ChannelListItem(parentList:ChannelList) {			
			if (parentList!=null) {
				this._parentList=parentList;
				_allListItems.push(this);
				this.parentList.updateListItems();
				this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
				this.addEventListener(Event.REMOVED_FROM_STAGE, this.destroy);
			} else {
				References.debug("ChannelListItem: Attempted to create new channel list item with no parent list. Skipping.");
				this.destroy();				
			}//else			
			super();
		}//constructor
		
		/**
		 * Creates the list item directly from an <code>AnnouceChannelEvent</code> object. Although this function isn't set to be a listener 
		 * by this class, it can be externally, or it can be passed the event object from any other listener method.
		 * <strong>Note that the item is not autmatically added to the <code>parentList</code>'s display list.</strong>
		 *   
		 * @param eventObj A <code>AnnouceChannelEvent</code> reference.
		 * 
		 */
		public function create(eventObj:AnnounceChannelEvent):void {			
			if (eventObj!=null) {
				if (SwagDataTools.hasData(eventObj.channelInfo)) {
					this._channelInfo=eventObj.channelInfo;
				}//if
				if (SwagDataTools.hasData(eventObj.cloudEvent)) {
					if (SwagDataTools.hasData(eventObj.cloudEvent.remotePeerID)) {
						this._channelPeerID=eventObj.cloudEvent.remotePeerID;
					} else {
						References.debug("ChannelListItem: Attempted to create new channel list item with no remote peer ID. Skipping.");
						this.destroy();
						return;
					}//elese
				} else {
					References.debug("ChannelListItem: Attempted to create new channel list item with no remote peer ID. Skipping.");
					this.destroy();
					return;
				}//else
			}//if				
			if ((this._channelInfo!=null) && (this.stage!=null)) {				
				if (References.announceChannel!=null) {
					if (this._channelInfo.channelIcon) {
						References.debug("ChannelListItem: Now requesting channel icon \""+this._channelInfo.channelIconID+"\" for \""+this._channelInfo.channelID+"\".");
						References.announceChannel.requestShare(this._channelInfo.channelID, this._channelInfo.channelIconID, this.onChannelIconComplete, this.onChannelIconProgress);
					} else {
						References.debug("ChannelListItem: No channel icon supplied for \""+this._channelInfo.channelID+"\".");
						this.hideLoadingPlaceholder();
					}//else
				}//if
			}//if
			if (this.channelName!=null) {
				this.channelName.text=String(this._channelInfo.channelName);				
			}//if
			if (this.channelDescription!=null) {
				this.channelDescription.text=String(this._channelInfo.channelDescription);
			}//if
			this.cacheAsBitmap=true;				
			this.addListeners();			
		}//create
		
		/**
		 * Invoked every time a data chunk is gathered while the channel icon is bing received.
		 *  
		 * @param eventObj A <code>SwagCloudEvent</code> object.
		 * 
		 */
		public function onChannelIconProgress(eventObj:SwagCloudEvent):void {
		}//onChannelIconProgress
						
		/**		 
		 * @private		 
		 */
		private function onMousePress(eventObj:MouseEvent):void {		
			if (this.currentTopListItem!=null) {
				this.currentTopListItem.stopDragSampler();				
				this.currentTopListItem.stopSnapTween()
			}//if
			this.stopDragSampler();
			this._mouseDown=true;
			this._backgroundPlayback.playToNextLabel("down");
			this._dragSampleDelta=0;
			this._accelerationFactor=0;
			this._dragSampleY=this.stage.mouseY;
			this._dragStartY=this.stage.mouseY;
			this._accelerationActive=false;
			this._dragActive=false;
			this._startPositionY=this.y;			
			this.startDragSampler();
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMotion);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, this.onMouseRelease);	
		}//onMousePress
		
		/**		 
		 * @private		 
		 */
		private function onMouseRelease(eventObj:MouseEvent):void {
			if (this.currentTopListItem!=null) {	
				this.currentTopListItem.stopDragSampler();				
				this.currentTopListItem.stopSnapTween()
			}//if
			this.stopDragSampler();
			this._mouseDown=false;
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMotion);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, this.onMouseRelease);			
			if (this._mouseOver) {
				this._backgroundPlayback.playToNextLabel("over");
			}//if						
			if (this._accelerationActive) {
				//Accelerating so snap to nearest available item up or down in the list based on the acceleration factor
				this._accelerationActive=false;
				var snapNumItems:int=int(Math.round(this._accelerationFactor/2));				
				var currentItem:ChannelListItem=this;
				if (snapNumItems>0) {
					//Accelerated motion downwards...
					while (snapNumItems>0) {						
						if (currentItem.nextItem!=null) {
							currentItem=currentItem.nextItem;
							snapNumItems--;
						} else {	
							this.currentTopListItem.scrollToPosition(currentItem.index);
							return;
						}//else
					}//while
					this.currentTopListItem.scrollToPosition(currentItem.index);
				} else {
					//Accelerated motion upwards...
					while (snapNumItems<0) {
						if (currentItem.previousItem!=null) {
							currentItem=currentItem.previousItem;
							snapNumItems++;
						} else {
							this.currentTopListItem.scrollToPosition(currentItem.index);
							return;
						}//else
					}//while
					this.currentTopListItem.scrollToPosition(currentItem.index);
				}//else
			} else if (this._dragActive) {
				//Dragging so snap to nearest available slot position
				this.snapToPosition();
				this._dragActive=false;
			} else {
				//Not accelerating and didn't move far enough to be considered a drag motion...so start playback!
				var channelPlayer:ChannelPlayerPanel=References.panelManager.togglePanel("channel_player", true).content as ChannelPlayerPanel;			
				channelPlayer.playChannel(this._channelInfo, this._channelPeerID);
			}//else
		}//onMouseRelease
		
		/**		 
		 * @private		 
		 */
		private function onMouseMotionOver(eventObj:MouseEvent):void {
			this._mouseOver=true;
			if (this._backgroundPlayback==null) {
				this._backgroundPlayback=new SwagMovieClip(this);
			}//if
			this._backgroundPlayback.playToNextLabel("over");
		}//onMouseMotionOver
		
		/**		 
		 * @private		 
		 */
		private function onMouseMotionOut(eventObj:MouseEvent):void {			
			this._mouseOver=false;
			this._backgroundPlayback.playToNextLabel("out");
		}//onMouseMotionOut
		
		/**		 
		 * @private		 
		 */
		private function onMouseMotion(eventObj:MouseEvent):void {			
			if (this._mouseDown) {				
				this.y=this._startPositionY+((this._dragStartY-this.stage.mouseY)*-1);				
				//Align icons in both directions
				this.updateAlign(true,true);
				this._parentList.updateOnScroll();
			}//if
		}//onMouseMotion
		
		/**		 
		 * @private		 
		 */
		private function sampleMouseDelta(eventObj:TimerEvent):void {						
			this._dragSampleDelta=this._dragSampleY-this.stage.mouseY;
			this._dragCounter+=Math.abs(this._dragSampleDelta);
			if (Math.abs(this._dragSampleDelta)>=this.dragSpeedThreshhold) {				
				this._accelerationActive=true;
				this._accelerationFactor=this._dragSampleDelta/this.dragSpeedThreshhold;
			} else {				
				this._accelerationActive=false;	
				this._accelerationFactor=0;
			}//else			
			if (this._dragCounter>=this.dragDistanceThreshhold) {
				this._dragActive=true;
			} else {
				this._dragActive=false;
			}//else
			this._dragSampleY=this.stage.mouseY;			
		}//sampleMouseDelta
				
		/**
		 * Scrolls the associated list downward 1 or more items.
		 *  
		 * @param numItems The number of items to scroll the list downward by. If omitted, the default is 1.
		 * 
		 */
		public function scrollToNextItem():void {			
			if (this.nextItem!=null) {
				this.nextItem.snapToTopOfList();
			} else {
				this.clearAllAnimations();
				this.stopDragSampler();
				this.stopSnapTween();
				this.parentList.listScrolling=false;
			}//else
		}//scrollToNextItem
		
		/**
		 * Scrolls the associated list upwards 1 or more items.
		 *  
		 * @param numItems The number of items to scroll the list upward by. If omitted, the default is 1.
		 * 
		 */
		public function scrollToPreviousItem(numItems:int=1):void {
			if (this.previousItem!=null) {
				this.previousItem.snapToTopOfList();
			} else {
				this.clearAllAnimations();
				this.stopDragSampler();
				this.stopSnapTween();
				this.parentList.listScrolling=false;
			}//else
		}//scrollToPreviousItem
		
		public function scrollToPosition(index:int):void {			
			this.parentList.currentSnapIndex=index;			
			if (this.parentList.listScrolling) {
				return;
			}//if			
			this.parentList.listScrolling=true;
			this.stopSnapTween();
			this.stopDragSampler();
			this.stopDrag();
			this.visible=true;
			if (this.currentTopListItem.index<this.parentList.currentSnapIndex) {
				this.currentTopListItem.scrollToNextItem();
			} else if (this.currentTopListItem.index>this.parentList.currentSnapIndex) {
				this.currentTopListItem.scrollToPreviousItem();
			} else {
				this.snapToPosition();
				this.parentList.listScrolling=false;
			}//else
			this.currentTopListItem=this;	
		}//scrollToPosition
			
		/**
		 * Returns a list of items associated with a particular <code>ChannelList</code> instance.
		 *  
		 * @param parentListRef A reference to the parent <code>ChannelList</code> for which to retrieve the list of items for.
		 * 
		 * @return The list of items associated with the parent <code>ChannelList</code> instance. If the <code>parentListRef</code>
		 * reference was <em>null</em>, an empty list will be returned.
		 * 
		 */
		public static function getItemsForList(parentListRef:ChannelList):Vector.<ChannelListItem> {
			var returnVector:Vector.<ChannelListItem>=new Vector.<ChannelListItem>();
			if (parentListRef==null) {
				return (returnVector);
			}//if
			for (var count:uint=0; count<_allListItems.length; count++) {
				var currentItem:ChannelListItem=_allListItems[count] as ChannelListItem;
				if (currentItem.parentList==parentListRef) {
					returnVector.push(currentItem);
				}//if
			}//for
			return (returnVector);
		}//getItemsForList
		
		/**
		 * Returns the first item (not necessarily the top item), associated with a particular <code>ChannelList</code> instance.
		 *  
		 * @param parentListRef A reference to the parent <code>ChannelList</code> for which to retrieve the first item for.
		 * 
		 * @return The first item associated with the parent <code>ChannelList</code> instance. If the <code>parentListRef</code>
		 * reference was <em>null</em>, invalid, or no first item exists for the list, <em>null</em> is returned.
		 * 
		 */
		public static function getFirstItemForList(parentListRef:ChannelList):ChannelListItem {		
			if (parentListRef==null) {
				return (null);
			}//if
			for (var count:uint=0; count<_allListItems.length; count++) {
				var currentItem:ChannelListItem=_allListItems[count] as ChannelListItem;
				if (currentItem.parentList==parentListRef) {
					return(currentItem);
				}//if
			}//for
			return (null);
		}//getFirstItemForList
		
		/**
		 * Snaps the associated list into position by determining if the top-most list item is either mostly in the list
		 * or mostly out. If mostly in, the list is snapped to that item, if mostly out, the list is snapped to the next
		 * item (unless none exists). 
		 */
		public function snapToPosition():void {
			this.parentList.currentSnapIndex=this.index;			
			if (this.currentTopListItem!=null) {
				this.currentTopListItem.stopDragSampler();				
				this.currentTopListItem.stopSnapTween()
			}//if
			this.currentTopListItem=this;
			if (!this._accelerationActive) {				
				this._snapTween=new Tween(this, "y", Regular.easeOut, this.y, this.nearestSnapDistance, 0.2, true);
				this._snapTween.addEventListener(TweenEvent.MOTION_CHANGE, this.onSnapTweenUpdate);
				this._snapTween.addEventListener(TweenEvent.MOTION_FINISH, this.onSnapTweenComplete);				
			}//if
		}//snapToPosition
		
		/**
		 * Snaps the current item to the top of the list. This also sets the <code>currentTopListItem</code>
		 * property to reference this list item instance.		 
		 * 
		 * @param movingUpward If <em>true</em>, items above the current item will be snapped to remove any gaps in the
		 * list. If <em>false</em>, the list is moving downward and any items below the current one will be moved.
		 */
		public function snapToTopOfList():void {		
			this.parentList.listScrolling=true;
			this.stopSnapTween();
			this.stopDragSampler();
			this.stopDrag();
			this.visible=true;
			this.currentTopListItem=this; //And now this is the top of the list
			if (Math.abs(this.index-this.parentList.currentSnapIndex)>1) {
				this.onSnapTweenUpdate();
				this.addEventListener(Event.ENTER_FRAME, this.onSnapTweenComplete);
			} else {
				this._snapTween=new Tween(this, "y", Regular.easeOut, this.y, 0, 0.1, true);
				this._snapTween.addEventListener(TweenEvent.MOTION_CHANGE, this.onSnapTweenUpdate);
				this._snapTween.addEventListener(TweenEvent.MOTION_FINISH, this.onSnapTweenComplete);
			}//else
		}//snapToTopOfList	
		
		/**		 
		 * @private		 
		 */
		private function snapAllItemsAbove(startIndex:int=-1):void {
			if (startIndex<0) {
				return;
			}//if
			for (var count:uint=0; count<this.listItems.length; count++) {
				var currentItem:ChannelListItem=this.listItems[count] as ChannelListItem;
				if ((currentItem.index<startIndex) && (currentItem.visible)) {
					currentItem.snapAboveList();
				}//if
			}//for
		}//snapAllItemsAbove
		
		/**		 
		 * @private		 
		 */
		private function snapAllItemsBelow(startIndex:int=-1):void {
			if (startIndex<0) {
				return;
			}//if
			for (var count:uint=0; count<this.listItems.length; count++) {
				var currentItem:ChannelListItem=this.listItems[count] as ChannelListItem;
				if (currentItem.index>startIndex) {
					currentItem.snapBelowList();
				}//if
			}//for
		}//snapAllItemsBelow
		
		/**
		 * Snaps the current item above the list, essentially making it disappear. This method is
		 * only typically used when the list has scrolled by more than one item.
		 */
		public function snapAboveList():void {
			this.stopDragSampler();
			this.stopSnapTween()		
			var targetPosition:Number=this.height*-1;			
			this._snapTween=new Tween(this, "y", Regular.easeOut, this.y, targetPosition, 0.2, true);
			this._snapTween.addEventListener(TweenEvent.MOTION_CHANGE, this.onRemoveTweenUpdate);
			this._snapTween.addEventListener(TweenEvent.MOTION_FINISH, this.onRemoveTweenUpdate);
		}//snapAboveList
		
		/**
		* Snaps the current item below the list, essentially making it disappear. This method is
		* only typically used when the list has scrolled by more than one item.
		*/
		public function snapBelowList():void {
			this.stopDragSampler();
			this.stopSnapTween();
			var targetPosition:Number=this.parentList.listWindowHeight;
			this._snapTween=new Tween(this, "y", Regular.easeOut, this.y, targetPosition, 0.2, true);
			this._snapTween.addEventListener(TweenEvent.MOTION_CHANGE, this.onRemoveTweenUpdate);
			this._snapTween.addEventListener(TweenEvent.MOTION_FINISH, this.onRemoveTweenUpdate);
		}//snapBelowList
		
		/**
		 * @private
		 */
		private function onRemoveTweenUpdate(eventObj:TweenEvent):void {			
			this.updateAlign(true,true,true);			
		}//onRemoveTweenUpdate
		
		/**
		 * @private
		 */
		private function onSnapTweenUpdate(... args):void {			
			this.updateAlign(true,true);
			this.parentList.updateOnScroll();		
		}//onSnapTweenUpdate
		
		/**
		 * @private
		 */
		private function onSnapTweenComplete(... args):void {	
			this.removeEventListener(Event.ENTER_FRAME, this.onSnapTweenComplete);
			this.stopSnapTween();
			this.parentList.listScrolling=false;
			if (this.currentTopListItem.index!=this.parentList.currentSnapIndex) {
				this.scrollToPosition(this.parentList.currentSnapIndex);
			}//if			
		}//onSnapTweenComplete
		
		/**
		 * Stops and removes from memory the current snap tween for the list item, if one exists. 		 
		 */
		public function stopSnapTween():void {			
			if (this._snapTween!=null) {
				this._snapTween.stop();
				this._snapTween.removeEventListener(TweenEvent.MOTION_CHANGE, this.onSnapTweenUpdate);			
				this._snapTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onSnapTweenComplete);
				this._snapTween=null;
			}//if	
		}//stopSnapTween
		
		/**
		 * @private
		 */
		private function get nearestSnapDistance():Number {			
			var distance:Number=new Number(0);
			for (var count:uint=0; count<this.listItems.length; count++) {
				var currentItem:ChannelListItem=this.listItems[count] as ChannelListItem;
				var currentY:Number=currentItem.y+(currentItem.height/2);
				if (currentY>0) {
					distance=this.y+(currentItem.y*-1);		
					return (distance);
				}//if
			}//for				
			return (distance);
		}//get nearestSnapDistance
		
		/**
		 * Invoked by the announce channel when the associated channel icon has been fully loaded.
		 * The data must pass through the additional step of being converted to a display object by the <code>Loader</code>
		 * class, which is completed in the follow-up <code>onChannelIconLoadComplete</code> method.
		 * 
		 * @param eventObj A <code>SwagCloudEvent</code> event object.
		 * 
		 */		
		public function onChannelIconComplete(eventObj:SwagCloudEvent):void {
			References.debug("ChannelListItem: Icon data loaded in "+String(eventObj.cloudShare.data.length)+" bytes.");
			References.debug("ChannelListItem:    Received "+String(eventObj.cloudShare.numberOfChunks)+" chunks from peers as a "+eventObj.cloudShare.encoding+"-encoded object.");
			SwagDataTools.byteArrayToDisplayObject(eventObj.cloudShare.data, this.onChannelIconLoadComplete)
		}//onChannelIconComplete
		
		/**		 
		 * @private		 
		 */
		private function onChannelIconLoadComplete(eventObj:Event):void {
			eventObj.target.removeEventListener(Event.INIT, this.onChannelIconLoadComplete);
			this._channelIcon=eventObj.target.content;
			References.debug("ChannelListItem: Icon decoded. Image dimensions "+String(this._channelIcon.bitmapData.width)+"x"+String(this._channelIcon.bitmapData.height)+" pixels.");
			this._channelIcon.visible=false;
			this._channelIcon.alpha=0;
			this.addChild(this._channelIcon);
			this.alignIcon();
			this._channelIcon.visible=true;
			if (this._iconTween!=null) {
				this._iconTween.stop();
				this._iconTween=null;
			}//if
			this._iconTween=new Tween(this._channelIcon, "alpha", Regular.easeOut, 0, 1, 0.4, true);
			this.hideLoadingPlaceholder();
		}//onChannelIconLoadComplete
		
		/**
		 * Aligns the item relative to its nearest neighbours in the associated channel list.
		 *  
		 * @param alignToNext If <em>true</em>, the item is aligned to the next item in the list rather than the previous item in the list (<em>false</em>).
		 * 
		 */
		public function alignItem(alignToNext:Boolean=false):void {
			//var storedPosition:Number=this.y;
			//First align item to next or previous item...			
			if (alignToNext) {
				if (this.nextItem!=null) {
					this.y=this.nextItem.y-this.height;
				}//if
			} else {
				if (this.previousItem!=null) {
					this.y=this.previousItem.y+this.previousItem.height;
				}//if
			}//else			
			//...now check to see if we're still in the display bounds or if we need to snap to display edge (keeps the list dimensions manageable).
			if ((this.y+this.height)<0) {				
				this.visible=false;			
				this.y=0-this.height;				
			} else if (this.y>this._parentList.listWindowHeight) {				
				this.visible=false;							
				this.y=this._parentList.listWindowHeight;
			} else {				
				this.visible=true;					
			}//else
			/*
			var positionDelta:Number=Math.abs(this.y-storedPosition);
			if ((positionDelta>this.height) && (this.visible)) {
				var blurAmount:Number=positionDelta/10;
				if (this._blurFilter==null) {
					this._blurFilter=new BlurFilter(0,blurAmount,1);
				} else {
					this._blurFilter.blurY=blurAmount;
				}//else
				this.filters=[this._blurFilter];
			} else {
				this.filters=[];
				this._blurFilter=null;
			}//else
			*/
		}//alignItem
			
		
		/**
		 * Aligns a group of channel list items.
		 *  
		 * @param parentList The parent <code>ChannelList</code> reference for which to align items for. If omitted or <em>null</em>,
		 * all list items for all lists are aligned.
		 * 
		 */
		public static function alignItems(parentList:ChannelList=null):void {
			if (parentList==null) {
				var itemList:Vector.<ChannelListItem>=_allListItems;	
			} else {
				itemList=getItemsForList(parentList);
			}//else			
			for (var count:uint=0; count<itemList.length; count++) {
				var currentItem:ChannelListItem=itemList[count] as ChannelListItem;
				currentItem.alignItem();
			}//for
		}//alignItems
		
		/**		 
		 * @return The first <code>ChannelListItem</code> in the current list. Note that this is
		 * not necessarily the top item being displayed.		 
		 */
		public function get firstItem():ChannelListItem {
			if (this.listItems.length==0) {
				return (null);
			}//if
			return (this.listItems[0] as ChannelListItem);
		}//get firstItem
		
		/** 
		 * @return The item currently being displayed at the top of the list. Note that this is not
		 * necessarily the first item in the list. Attempting to set this value from a list item
		 * that doesn't belong to this list will not do anything.
		 */
		public function get currentTopListItem():ChannelListItem {
			try {
				if (this.parentList.currentTopListItem==null) {
					//Important, otherwise it might never be assigned and the list won't scroll properly.
					this.parentList.currentTopListItem=this.listItems[0] as ChannelListItem;
				}//if
				return (this.parentList.currentTopListItem);
			} catch (e:*) {
				return (null);
			}//catch
			return (null);
		}//get currentTopListItem
		
		/** 
		 * @param itemSet A reference to the current item currently at the top of the list.
		 */
		public function set currentTopListItem(itemSet:ChannelListItem):void {
			try {
				this.parentList.currentTopListItem=itemSet;
			} catch (e:*) {				
			}//catch
		}//set this.currentTopListItem
		
		/**		 
		 * @return The previous <code>ChannelListItem</code> in the current list, or
		 * <em>null</em> if this is the first item in the list.
		 */
		public function get previousItem():ChannelListItem {
			for (var count:uint=0; count<this.listItems.length; count++) {
				var currentItem:ChannelListItem=this.listItems[count] as ChannelListItem;
				if ((currentItem==this) && (count!=0)) {
					return (this.listItems[count-1] as ChannelListItem);
				}//if
			}//for
			return (null);
		}//get previousItem
		
		/**		 
		 * @return The next <code>ChannelListItem</code> in the current list, or
		 * <em>null</em> if this is the first item in the list.
		 */
		public function get nextItem():ChannelListItem {
			for (var count:uint=0; count<this.listItems.length; count++) {
				var currentItem:ChannelListItem=this.listItems[count] as ChannelListItem;
				if (currentItem==this) {
					if (count==(this.listItems.length-1)) {
						return (null);
					} else {
						return (this.listItems[count+1] as ChannelListItem);
					}//else
				}//if
			}//for
			return (null);
		}//get nextItem
		
		/**		 
		 * @return The last <code>ChannelListItem</code> in the current list.
		 */
		public function get lastItem():ChannelListItem {
			if (this.listItems.length==0) {
				return (null);
			}//if
			return (this.listItems[this.listItems.length-1] as ChannelListItem);
		}//get previousItem		
	
		
		/**		 
		 * @return All of the list items, in the order in which they were created, associated with the current
		 * <code>parentList</code> reference. Note that this differs from the <code>allListItems</code> property
		 * which returns items associated with all current lists.
		 */
		public function get listItems():Vector.<ChannelListItem> {
			var returnList:Vector.<ChannelListItem>=new Vector.<ChannelListItem>;			
			if (this.parentList==null) {
				return (returnList);
			}//if		
			return (this.parentList.listItems);
		}//get listItems		
		
		/**		 
		 * @return All of the <code>ChannelListItem</code> references currently on the display list. This vector
		 * includes items from all lists; the <code>parentList</code> property of each item can be used to
		 * distinguish which list each item belongs to. Any item with a <em>null</em> <code>parentList</code>
		 * property should be considered invalid and not processed.		 
		 */
		public function get allListItems():Vector.<ChannelListItem> {
			if (_allListItems==null) {
				_allListItems=new Vector.<ChannelListItem>();
			}//if			
			return (_allListItems);
		}//get allListItems		
						
		/**		 
		 * @return A reference to the parent <code>ChannelList</code> instance that generated this list item.
		 * If this reference is <em>null</em>, the list item should be considered invalid and not processed. 
		 */
		public function get parentList():ChannelList {
			return (this._parentList);
		}//get parentList		
		
		/**
		 * Updates alignment for the channel list item and also invokes alignment updates in neigbouring items.
		 *  
		 * @param updateNext If <em>true</em>, all subsequent items in the list will also be aligned by invoking this same method.
		 * @param updatePrevious If <em>true</em>, all previous items in the list will also be aligned by invoking the same method.
		 * @param omitCurrent If <em>true</em>, the current item will not be aligned. If <em>false</em>, it will be aligned.
		 * 
		 */
		public function updateAlign(updateNext:Boolean=false, updatePrevious:Boolean=false, omitCurrent:Boolean=true):void {					
			if (updateNext) {				
				if (!omitCurrent) {
					this.alignItem(false);
				}//if				
				if (this.nextItem!=null) {
					if (this.nextItem.visible || this.visible) {
						this.nextItem.updateAlign(true, false, false);						
					}//if					
				}//if	
			}//if
			if (updatePrevious) {				
				if (!omitCurrent) {					
					this.alignItem(true);
				}//if			
				if (this.previousItem!=null) {
					if (this.previousItem.visible || this.visible) {				
						this.previousItem.updateAlign(false, true, false);						
					}//if
				}//if				
			}//if
		}//updateAlign
		
		/**
		 * Aligns the channel icon to the list item with the spcified margins. 		 
		 */
		public function alignIcon():void {
			if (this._channelIcon==null) {
				return;
			}//if
			if (!this.contains(this._channelIcon)) {
				return;
			}//if
			this._channelIcon.x=((100-this._channelIcon.width))+this.iconLeftMargin;
			this._channelIcon.y=((100-this._channelIcon.height)/2)+this.iconTopMargin;						
		}//alignIcon
		
		/**
		 * @return <em>True</em> if the item is being dragged (has been pulled more than a certain distance). If this value
		 * is <em>true</em> then the item should not process a mouse release as an attempt to start playback.		 
		 */
		public function get isDragging():Boolean {
			return (this._dragActive);
		}//get isDragging
		
		/**
		 * @return <em>True</em> if the item is being accelerated (is being pulled at a certain speed). If this value
		 * is <em>true</em> then the item should not process a mouse release as an attempt to start playback and the list
		 * should instead be scrolled with acceleration.		 
		 */
		public function get isAccelerated():Boolean {
			return (this._accelerationActive);
		}//get isAccelerated
		
		/**
		 * @return The index value of the current <code>ChannelListItem</code> instance in the <code>_listItems</code> vector 
		 * <code>allListItems</code>. A return value of -1 indicates that this channel list item is an orphan and should be removed
		 * immediately.		 
		 */
		public function get index():int {
			for (var count:int=0; count<_allListItems.length; count++) {
				var currentItem:ChannelListItem=_allListItems[count] as ChannelListItem;
				if (currentItem==this) {
					return (count);
				}//if
			}//for
			return (-1);
		}//get index
		
		/**
		 * @private 		 
		 */
		private function hideLoadingPlaceholder():void {
			this.playToNextLabel("hide",false,false);
		}//hideLoadingPlaceholder
		
		/**
		 * @private 		 
		 */
		private function showLoadingPlaceholder():void {
			this.playToNextLabel("show",false,false);
		}//showLoadingPlaceholder
		
		/**
		 * @private 		 
		 */
		private function setDefaults(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			SwagDispatcher.addEventListener(AnnounceChannelEvent.ONAVCHANNELDISCONNECT, this.onItemDisconnect, this);
			this.gotoAndStop(1);
			this.background.gotoAndStop(1);
			this._backgroundPlayback=new SwagMovieClip(this.background);
			this.create(null);
			this.alignItem();
			this.parentList.updateOnListChange();
		}//setDefaults
		
		/**
		 * Responds to a broadcast from the AnnounceChannel that a channel has disconnected. The
		 * </code>AnnounceChannelEvent</code>'s <em>cloudEvent.remotePeerID</em> is the most
		 * reliable method of determining which peer has disconnected.
		 *  
		 * @param eventObj An <code>AnnounceChannelEvent</code> event object.
		 * 
		 */
		public function onItemDisconnect(eventObj:AnnounceChannelEvent):void {						
			if (eventObj.cloudEvent.remotePeerID==this._channelPeerID) {
				this.stopDragSampler();
				this.clearAllAnimations();
				if (this.channelName!=null) {
					this.channelName.text=String(this._channelInfo.channelName);				
				}//if
				if (this.channelDescription!=null) {
					this.channelDescription.text=String(this._channelInfo.channelDescription);
				}//if
				if (this._channelIcon!=null) {
					if (this.contains(this._channelIcon)) {
						this.removeChild(this._channelIcon);
					}//if
					this._channelIcon=null;
				}//if
				References.debug("ChannelListItem: Peer \""+this._channelPeerID+"\" has disconnected. Removing associated list item.");
				this.removeListeners();				
				SwagDispatcher.removeEventListener(SwagMovieClipEvent.END, this.onItemCloseAnimationPlayed, this);
				super.playRange("remove","onremove",false);
				SwagDispatcher.addEventListener(SwagMovieClipEvent.END, this.onItemCloseAnimationPlayed, this, this);
			}//if
		}//onItemDisconnect
		
		/**
		 * Invoked by the super <code>SwagMovieClip</code> instance when the item close animation has completed playing and
		 * the item is ready to be destroyed.
		 *  
		 * @param eventObj A <code>SwagMovieClipEvent</code> event object.
		 * 
		 */
		public function onItemCloseAnimationPlayed(eventObj:SwagMovieClipEvent):void {			
			SwagDispatcher.removeEventListener(SwagMovieClipEvent.END, this.onItemCloseAnimationPlayed, this);
			this.parentList.updateOnListChange();
			this.destroyWithShrink();
		}//onItemCloseAnimationPlayed
		
		/**
		 * @private 		 
		 */
		private function destroyWithShrink():void {
			this.removeListeners();
			this._destroyTween=new Tween(this, "height", Regular.easeIn, this.height, 0, 0.3, true);
			this._destroyTween.addEventListener(TweenEvent.MOTION_CHANGE, this.onShrinkAnimationPlaying);
			this._destroyTween.addEventListener(TweenEvent.MOTION_FINISH, this.onShrinkAnimationDone);
		}//destroyWithShrink
		
		/**
		 * @private 		 
		 */
		private function onShrinkAnimationPlaying(eventObj:TweenEvent):void {
			this.parentList.updateOnListChange();
			this.updateAlign(true, false);
		}//onShrinkAnimationPlaying
		
		/**
		 * @private 		 
		 */
		private function onShrinkAnimationDone(eventObj:TweenEvent):void {
			if (this._destroyTween!=null) {
				this._destroyTween.stop();
				this._destroyTween.removeEventListener(TweenEvent.MOTION_CHANGE, this.onShrinkAnimationPlaying);
				this._destroyTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShrinkAnimationDone);
				this._destroyTween=null;
			}//if
			this.parentList.updateOnListChange();
			this.destroy();
		}//onShrinkAnimationDone
		
		/**
		 * @private 		 
		 */
		private function startDragSampler():void {
			if (this.currentTopListItem!=null) {
				this.currentTopListItem.stopDragSampler();
			}//if
			//stopAllDragSamplers();
			this._dragSampleDelta=0;
			this._dragCounter=0;
			this._dragSampleY=this.stage.mouseY;
			this._dragStartY=this.stage.mouseY;
			this._startPositionY=this.y;
			this._dragSampleTimer=new Timer(this.dragSamplingRate, 0);
			this._dragSampleTimer.addEventListener(TimerEvent.TIMER, this.sampleMouseDelta);
			this._dragSampleTimer.start();
		}//startDragSampler
		
		/**
		 * Stops the drag sampler and returns <em>true</em> if the drag threshold was exceeded (i.e. the item
		 * was being dragged), or <em>false</em> (i.e. the item was clicked). 
		 * 
		 */
		public function stopDragSampler():void {		
			if (this._dragSampleTimer!=null) {
				this._dragSampleTimer.stop();
				this._dragSampleTimer.removeEventListener(TimerEvent.TIMER, this.sampleMouseDelta);
				this._dragSampleTimer=null;
			}//if	
		}//stopDragSampler
		
		/**
		 * Stops all drag sampling (which determines the <code>isDragging</code> property) for a group
		 * of list items.
		 *  
		 * @param parentList The parent <code>ChannelList</code> reference for which to stop drag samplers for.
		 * If omitted or <em>null</em>, all drag samplers for all list items are stopped.
		 * 
		 */
		public static function stopAllDragSamplers(parentList:ChannelList=null):void {
			if (parentList==null) {
				var itemList:Vector.<ChannelListItem>=_allListItems;	
			} else {
				itemList=getItemsForList(parentList);
			}//else			
			for (var count:uint=0; count<itemList.length; count++) {
				var currentItem:ChannelListItem=itemList[count] as ChannelListItem;
				if (currentItem!=null) {
					currentItem.stopDragSampler();
				}//if
			}//for
		}//stopAllDragSamplers
		
		/**
		 * Stops all snap tweens for a group of list items.
		 *  
		 * @param parentList The parent <code>ChannelList</code> reference for which to stop snap tween animations for.
		 * If omitted or <em>null</em>, all snap tween animations for all list items are stopped.
		 * 
		 */
		public static function stopAllSnapTweens(parentList:ChannelList=null):void {
			if (parentList==null) {
				var itemList:Vector.<ChannelListItem>=_allListItems;	
			} else {
				itemList=getItemsForList(parentList);
			}//else			
			for (var count:uint=0; count<itemList.length; count++) {
				var currentItem:ChannelListItem=itemList[count] as ChannelListItem;
				if (currentItem!=null) {					
					currentItem.stopSnapTween();
				}//if
			}//for
		}//stopAllSnapTweens
				
		/**
		 * Stops and clears from memory any animations currently being used by the list item. 		 
		 */
		public function clearAllAnimations():void {
			if (this._iconTween!=null) {
				this._iconTween.stop();
				this._iconTween=null;
			}//if
			if (this._destroyTween!=null) {
				this._destroyTween.stop();
				this._destroyTween.removeEventListener(TweenEvent.MOTION_CHANGE, this.onShrinkAnimationPlaying);
				this._destroyTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShrinkAnimationDone);
				this._destroyTween=null;
			}//if
			if (this._backgroundPlayback!=null) {
				this._backgroundPlayback.stop();
				this._backgroundPlayback.target=null;
				this._backgroundPlayback=null;
			}//if
			this.stopSnapTween();
		}//clearAllAnimations
		
		/**
		 * @private 		 
		 */
		private function addListeners():void {
			this.removeListeners();
			this.addEventListener(MouseEvent.MOUSE_DOWN, this.onMousePress);
			this.addEventListener(MouseEvent.MOUSE_OVER, this.onMouseMotionOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, this.onMouseMotionOut);				
			this.mouseChildren=false;
			this.useHandCursor=true;
			this.buttonMode=true;
		}//addListeners
		
		/**
		 * @private 		 
		 */
		private function removeListeners():void {
			this.removeEventListener(MouseEvent.MOUSE_DOWN, this.onMousePress);
			this.removeEventListener(MouseEvent.MOUSE_OVER, this.onMouseMotionOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT, this.onMouseMotionOut);			
			this.mouseChildren=false;
			this.useHandCursor=false;
			this.buttonMode=false;
		}//removeListeners
		
		/**
		 * Destroys the list item and removes it from memory, including any display list it's a part of.
		 *  
		 * @param args Any argument is valid.
		 * 
		 */
		public function destroy(... args):void {
			this.removeEventListener(Event.REMOVED_FROM_STAGE, this.destroy);
			var packedItems:Vector.<ChannelListItem>=new Vector.<ChannelListItem>();
			for (var count:uint=0; count<_allListItems.length; count++) {
				var currentItem:ChannelListItem=_allListItems[count] as ChannelListItem;
				if (currentItem!=this) {
					packedItems.push(currentItem);
				}//if
			}//for
			_allListItems=packedItems;
			this.parentList.updateListItems();
			SwagDispatcher.removeEventListener(AnnounceChannelEvent.ONAVCHANNELDISCONNECT, this.onItemDisconnect);
			SwagDispatcher.removeEventListener(SwagMovieClipEvent.END, this.onItemCloseAnimationPlayed, this);
			this.clearAllAnimations();
			this.stopDragSampler();
			this.filters=[];
			this._blurFilter=null;
			this._channelInfo=null;		
			this._channelPeerID=null;
			this._parentList=null;
			if (this._channelIcon!=null) {
				if (this.contains(this._channelIcon)) {
					this.removeChild(this._channelIcon);
				}//if
				this._channelIcon=null;
			}//if		
			this.updateAlign(true,true,true);
		}//destroy
		
	}//ChannelListItem class
	
}//package