package socialcastr.ui.panels {
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.None;
	import fl.transitions.easing.Regular;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.core.AnnounceChannel;
	import socialcastr.core.Timeline;
	import socialcastr.core.timeline.SimpleVideoFadeEffect;
	import socialcastr.core.timeline.StreamControlEffect;
	import socialcastr.core.timeline.TimelineInvokeConstants;
	import socialcastr.events.AnnounceChannelEvent;
	import socialcastr.events.LoadingIndicatorEvent;
	import socialcastr.events.TimelineEvent;
	import socialcastr.ui.Panel;
	import socialcastr.ui.PanelContent;
	import socialcastr.ui.components.VideoDisplayComponent;
	import socialcastr.ui.input.MovieClipButton;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.core.instances.SwagLoader;
	import swag.events.SwagCloudEvent;
	import swag.events.SwagErrorEvent;
	import swag.events.SwagLoaderEvent;
	
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
	public class ChannelPlayerPanel extends PanelContent {
		
		public const group_prefix="SocialCastr.AV:";
		
		private var _channelInfo:Object=null;
		private var _channelPeerID:String=new String();
		private var _underlayContainer:MovieClip;
		private var _overlayContainer:MovieClip;
		private var _overlayImage:Bitmap;
		private var _underlayImage:Bitmap;
		private var _autoStartChannel:Boolean=true;
		private var _underlayTween:Tween=null;
		private var _videoTween:Tween=null;
		private var _overlayTween:Tween=null;
		private var _channelSCID:String=null; //Assigned only if playing channel by SCID, otherwise always null.
		private var _scanTimeout:Number=10;
		private var _timeoutTimer:Timer;
		private var _streamControl:StreamControlEffect;
		private var _scanningImageTween:Tween=null;
		private var _timeoutImageTween:Tween=null;
		private var _scanningImageLoader:SwagLoader;
		private var _timeoutImageLoader:SwagLoader;
		private var _scanningImage:DisplayObject;
		private var _timeoutImage:DisplayObject;
		private var _liveTimeline:Timeline=null;
		private var _tempFadeEffect:SimpleVideoFadeEffect=null;
		
		private var _video:VideoDisplayComponent;
		
		public function ChannelPlayerPanel(parentPanelRef:Panel)	{
			super(parentPanelRef);
		}//constructor
		
		/**
		 * Begins playback of a specific channel. First a request is made for each of the channel assets. Once 
		 * all requests are fulfilled (or no assets are left to load), channel playback begins.
		 *  
		 * @param channelInfo An object containing the channel information. Typically this is the same as the data object
		 * that is be received by the <code>Announce</code> channel whenever a new channel is announced.
		 * @param channelPeerID The peerd ID associated with the channel, as reported by the <code>SwagCloud</code>
		 * instance associated with the <code>Announce</code> channel.
		 * 
		 * @return <em>True</em> if the playback sequence could be started, <em>false</em> otherwise. Note that this
		 * does not mean that the channel is playing, only that the requests for assets, etc., have been started.
		 * 
		 */
		public function playChannel(channelInfo:Object, channelPeerID:String):Boolean {
			SwagDispatcher.removeEventListener(AnnounceChannelEvent.ONAVCHANNELDISCONNECT, this.onChannelDisconnect, this);
			if ((!channelInfo.videoBroadcast) && (!channelInfo.audioBroadcast)) {
				//Nothing's broadcasting. We shouldn't have gotten this message.
				References.panelManager.togglePanel(this.panelID, false);
				return (false);
			}//if			
			SwagDispatcher.addEventListener(AnnounceChannelEvent.ONAVCHANNELDISCONNECT, this.onChannelDisconnect, this);			
			if (this._video!=null) {				
				this._video.destroy();
				this.removeChild(this._video);
				this._video=null;
			}//if
			if (this._underlayContainer!=null) {
				this.removeChild(this._underlayContainer);
				this._underlayContainer=null;
			}//if			
			if (this._overlayContainer!=null) {
				this.removeChild(this._overlayContainer);
				this._overlayContainer=null;
			}//if
			this._channelInfo=channelInfo;
			this._channelPeerID=channelPeerID;
			References.debug("ChannelPlayerPanel got live timeline: "+this._channelInfo.liveTimeline);
			if (SwagDataTools.isXML(this.panelData.remote)) {
				this._video=new VideoDisplayComponent(this.panelData.remote[0] as XML);			
				this.addChild(this.underlayContainer);
				this.addChild(this._video);
				this.addChild(this.overlayContainer);
				this.requestLayerImages(true);				
				return (true);			
			}//if
			return (false);
		}//playChannel
		
		/**
		 * Begins playback of a channel based on the supplied SocialCastr ID (SCID). This is a two step process involving
		 * first a request to the Announce Channel (with a timeout), and hopefully a response from
		 *  
		 * @param SCID The SocialCastr ID string to being scanning and (if all goes well), playback on.
		 * 
		 */
		public function playChannelBySCID(SCID:String):void {
			if ((SCID==null) || (SCID=="")) {
				return;
			}//if
			SwagDispatcher.addEventListener(AnnounceChannelEvent.ONAVCHANNELINFO, this.onPlayChannelBySCIDResponse, this);
			this._channelSCID=SCID;
			//Ensure the following images are loaded first. playChannelBySCID is called again when they end.
			if (this.loadScanningImage()) {	
				return;
			}//if	
			if (this.loadTimeoutImage()) {
				return;
			}//if
			References.announceChannel.requestAVChannels(false, false, SCID);	
			var timeoutSetting:String=Settings.getWebParameter("scid_scan_timeout", true, false);
			if ((isNaN(Number(timeoutSetting))==false) && (Number(timeoutSetting)>0)) {
				this._scanTimeout=new Number(timeoutSetting);
			}//if
			this._timeoutTimer=new Timer((this._scanTimeout*1000), 1);
			this._timeoutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, this.onScanTimeout);
			this._timeoutTimer.start();
		}//playChannelBySCID
		
		private function onScanTimeout(eventObj:TimerEvent):void {
			this._timeoutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, this.onScanTimeout);
			SwagDispatcher.removeEventListener(AnnounceChannelEvent.ONAVCHANNELINFO, this.onPlayChannelBySCIDResponse);
			this._timeoutTimer.stop();
			this._timeoutTimer=null;
			this.hideScanningImage();
			this.showTimeoutImage();
		}//onScanTimeout
		
		private function stopTimeoutTimer():void {
			this._timeoutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, this.onScanTimeout);
			SwagDispatcher.removeEventListener(AnnounceChannelEvent.ONAVCHANNELINFO, this.onPlayChannelBySCIDResponse);
			this._timeoutTimer.stop();
			this._timeoutTimer=null;
			this.hideTimeoutImage();
		}//stopTimeoutTimer
		
		public function loadScanningImage():Boolean {
			var imageURL:String=Settings.getWebParameter("scanning_image");
			if ((imageURL==null) || (imageURL=="")) {
				return (false);
			}//if
			if (this._scanningImageLoader!=null) {
				return (false);
			}//if
			this._scanningImageLoader=new SwagLoader();
			SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, this.onLoadScanningImage, this, this._scanningImageLoader);
			SwagDispatcher.addEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, this.onLoadScanningImageError, this, this._scanningImageLoader);
			this._scanningImageLoader.load(imageURL, Bitmap);
			return (true);
		}//loadScanningImage		
		
		public function onLoadScanningImage(eventObj:SwagLoaderEvent):void {
			try {
				SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onLoadScanningImage, this._scanningImageLoader);
				SwagDispatcher.removeEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, this.onLoadScanningImageError, this._scanningImageLoader);	
				this._scanningImage=eventObj.source.loadedData;
				this.addChild(this._scanningImage);
				this._scanningImage.visible=false;
				this._scanningImage.alpha=0;
				this.showScanningImage();
			} catch (e:*) {
				References.debug("ChannelPlayerPanel: Error trying to add scanning image to display - "+e.toString());
			} finally {
				this.playChannelBySCID(this._channelSCID);
			}//finally
		}//onLoadScanningImage
		
		public function onLoadScanningImageError(eventObj:SwagErrorEvent):void {
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onLoadScanningImage, this._scanningImageLoader);
			SwagDispatcher.removeEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, this.onLoadScanningImageError, this._scanningImageLoader);
			References.debug("ChannelPlayerPanel: Couldn't load \"scanning_image\" image: "+Settings.getWebParameter("scanning_image", true, false));
			this.playChannelBySCID(this._channelSCID);
		}//onLoadScanningImageError
		
		private function showScanningImage():void {
			if (this._scanningImageTween!=null) {
				this._scanningImageTween.stop();
				this._scanningImageTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideScanningImage);
				this._scanningImageTween=null;
			}//if
			if (this._scanningImage==null) {
				return;
			}//if
			if ((this._scanningImage.alpha==1) && (this._scanningImage.visible==true)) {
				return;
			}//if
			this._scanningImage.x=350-(this._scanningImage.width/2);
			this._scanningImage.y=250-(this._scanningImage.height/2);
			this._scanningImage.visible=true;
			this._scanningImageTween=new Tween(this._scanningImage, "alpha", None.easeNone, this._scanningImage.alpha, 1, 0.5, true);
		}//showScanningImage
		
		private function hideScanningImage():void {
			if (this._scanningImageTween!=null) {
				this._scanningImageTween.stop();
				this._scanningImageTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideScanningImage);				
				this._scanningImageTween=null;
			}//if
			if (this._scanningImage==null) {
				return;
			}//if
			if (this.contains(this._scanningImage)==false) {
				return;
			}//if
			if ((this._scanningImage.alpha==0) || (this._scanningImage.visible==false)) {
				return;
			}//if			
			this._scanningImage.visible=true;
			this._scanningImageTween=new Tween(this._scanningImage, "alpha", None.easeNone, this._scanningImage.alpha, 1, 0.5, true);
			this._scanningImageTween.addEventListener(TweenEvent.MOTION_FINISH, this.onHideScanningImage);
		}//hideScanningImage
		
		private function onHideScanningImage(eventObj:TweenEvent):void {
			this._scanningImage.visible=false;
		}//onHideScanningImage
		
		private function loadTimeoutImage():Boolean {
			var imageURL:String=Settings.getWebParameter("scan_timeout_image", true, false);
			if (this._timeoutImageLoader!=null) {
				return (true);
			}//if
			if (imageURL==null) {
				var TOImageClass:Class=SwagSystem.getDefinition("ChannelNotAvailable_image");
				if (TOImageClass!=null) {
					this._timeoutImage=new TOImageClass() as MovieClip;
					this.addChild(this._timeoutImage);
					this._timeoutImage.visible=false;
					this._timeoutImage.alpha=0;
				}//if
				return (false);
			}//if
			this._timeoutImageLoader=new SwagLoader();
			SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, this.onLoadTimeoutImage, this, this._timeoutImageLoader);
			SwagDispatcher.addEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, this.onLoadTimeoutImageError, this, this._timeoutImageLoader);
			this._timeoutImageLoader.load(imageURL, Bitmap);
			return (false);
		}//loadTimeoutImage
		
		public function onLoadTimeoutImage(eventObj:SwagLoaderEvent):void {
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onLoadTimeoutImage, this._timeoutImageLoader);
			SwagDispatcher.removeEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, this.onLoadTimeoutImageError, this._timeoutImageLoader);
			this._timeoutImage=eventObj.source.loadedData;
			this.addChild(this._timeoutImage);
			this._timeoutImage.visible=false;
			this._timeoutImage.alpha=0;			
			this.addChild(this._timeoutImage);
			this.playChannelBySCID(this._channelSCID);
		}//onLoadTimeoutImage
		
		public function onLoadTimeoutImageError(eventObj:SwagErrorEvent):void {
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onLoadTimeoutImage, this._timeoutImageLoader);
			SwagDispatcher.removeEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, this.onLoadTimeoutImageError, this._timeoutImageLoader);
			References.debug("ChannelPlayerPanel: Couldn't load \"scan_timeout_image\" image: "+Settings.getWebParameter("scan_timeout_image", true, false));
			this.playChannelBySCID(this._channelSCID);
		}//onLoadTimeoutImageError
		
		private function showTimeoutImage():void {
			if (this._timeoutImageTween!=null) {
				this._timeoutImageTween.stop();
				this._timeoutImageTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideTimeoutImage);
				this._timeoutImageTween=null;
			}//if
			if (this._timeoutImage==null) {
				return;
			}//if			
			if (this.contains(this._timeoutImage)==false) {
				return;
			}//if
			this._timeoutImage.x=350-(this._timeoutImage.width/2);
			this._timeoutImage.y=250-(this._timeoutImage.height/2);
			if ((this._timeoutImage.alpha==1) && (this._timeoutImage.visible==true)) {
				return;
			}//if			
			this._timeoutImage.visible=true;
			this._timeoutImageTween=new Tween(this._timeoutImage, "alpha", None.easeNone, this._timeoutImage.alpha, 1, 0.5, true);
		}//showTimeoutImage
		
		private function hideTimeoutImage():void {
			if (this._timeoutImageTween!=null) {
				this._timeoutImageTween.stop();
				this._timeoutImageTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideTimeoutImage);				
				this._timeoutImageTween=null;
			}//if
			if (this._timeoutImage==null) {
				return;
			}//if
			if (this.contains(this._timeoutImage)==false) {
				return;
			}//if
			if ((this._timeoutImage.alpha==0) || (this._timeoutImage.visible==false)) {
				return;
			}//if			
			this._timeoutImage.visible=true;
			this._timeoutImageTween=new Tween(this._timeoutImage, "alpha", None.easeNone, this._timeoutImage.alpha, 1, 0.5, true);
			this._timeoutImageTween.addEventListener(TweenEvent.MOTION_FINISH, this.onHideTimeoutImage);
		}//hideTimeoutImage
		
		private function onHideTimeoutImage(eventObj:TweenEvent):void {
			this._timeoutImage.visible=false;
		}//onHideTimeoutImage
		
		public function onPlayChannelBySCIDResponse (eventObj:AnnounceChannelEvent):void {
			try {
				if (eventObj.channelInfo.SCID!=this._channelSCID) {
					return;
				}//if
			} catch (e:*) {
				return;
			}//catch
			this.stopTimeoutTimer();
			SwagDispatcher.removeEventListener(AnnounceChannelEvent.ONAVCHANNELINFO, this.onPlayChannelBySCIDResponse);
			this.hideScanningImage();
			this.hideTimeoutImage();
			this.playChannel(eventObj.channelInfo, eventObj.cloudEvent.remotePeerID);
		}//onPlayChannelBySCIDResponse
		
		public function onPlayChannelSCIDTimeout (eventObj:AnnounceChannelEvent):void {
			this.hideScanningImage();
			this.showTimeoutImage();
		}//onPlayChannelSCIDTimeout
		
		override public function onHide(direction:String=null):void {
			if (this._video!=null) {
				this._video.pauseStream();
			}//if
		}//onHide
		
		override public function onShow(direction:String=null):void {
			if (this._video!=null) {
				this._video.resumeStream();
			}//if
		}//onShow
		
		public function onChannelDisconnect(eventObj:AnnounceChannelEvent):void {						
			if (eventObj.cloudEvent.remotePeerID==this._channelPeerID) {				
				References.debug("ChannelPlayerPanel: Peer \""+this._channelPeerID+"\" has disconnected. Stopping playback and returning back to list.");
				SwagDispatcher.removeEventListener(AnnounceChannelEvent.ONAVCHANNELDISCONNECT, this.onChannelDisconnect, this);
				this._video.destroy();
				this._video=null;
				this._channelInfo=null;
				this._channelPeerID=null;
				if (this._underlayImage!=null) {
					if (this._underlayContainer.contains(this._underlayImage)) {
						this._underlayContainer.removeChild(this._underlayImage);
					}//if
					this._underlayImage=null;					
				}//if
				if (this.contains(this._underlayContainer)) {
					this.removeChild(this._underlayContainer);
					this._underlayContainer=null;
				}//if				
				if (this._overlayImage!=null) {
					if (this._overlayContainer.contains(this._overlayImage)) {
						this._overlayContainer.removeChild(this._overlayImage);
					}//if
					this._overlayImage=null;					
				}//if
				if (this.contains(this._overlayContainer)) {
					this.removeChild(this._overlayContainer);
					this._overlayContainer=null;
				}//if				
				this._autoStartChannel=false;
				if (this._underlayTween!=null) {
					this._underlayTween.stop();
					this._underlayTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onUnderlayImageShown);
					this._underlayTween=null;
				}//if
				if (this._overlayTween!=null) {
					this._overlayTween.stop();
					this._overlayTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onOverlayImageShown);
					this._overlayTween=null;
				}//if
				//References.panelManager.resumeSuspendedPanels("fromLeft");
				References.panelManager.togglePanel("channel_list", true);
			}//if
		}//onChannelDisconnect
		
		private function arrangeLayers():void {
			return;
			if (this.contains(this.underlayContainer)) {
				this.setChildIndex(this.underlayContainer, 1);
			}//if
			if (this.contains(this._video)) {
				this.setChildIndex(this._video, 2);
			}//if
			if (this.contains(this.overlayContainer)) {
				this.setChildIndex(this.overlayContainer, 3);
			}//if
		}//arrangeLayers
		
		private function requestLayerImages(autoStart:Boolean=false):void {
			this._autoStartChannel=autoStart;
			this.requestUnderlayImage();	
		}//requestLayerImages
		
		private function requestUnderlayImage():void {			
			if ((this._channelInfo!=null) && (this.stage!=null)) {
				if (this._underlayImage!=null) {
					if (this.underlayContainer.contains(this._underlayImage)) {
						this.underlayContainer.removeChild(this._underlayImage);
					}//if
				}//if
				if (References.announceChannel!=null) {
					var event:LoadingIndicatorEvent=new LoadingIndicatorEvent(LoadingIndicatorEvent.SHOW);
					SwagDispatcher.dispatchEvent(event, this);
					event=new LoadingIndicatorEvent(LoadingIndicatorEvent.UPDATE);
					event.updateText="(1 of 3) Loading...";			
					SwagDispatcher.dispatchEvent(event, this);
					event=new LoadingIndicatorEvent(LoadingIndicatorEvent.START);
					SwagDispatcher.dispatchEvent(event, this);
					if (this._channelInfo.channelUnderlay) {
						References.debug("ChannelPlayerPanel: Now requesting underlay image \""+this._channelInfo.channelUnderlayID+"\" for \""+this._channelInfo.channelID+"\".");
						References.announceChannel.requestShare(this._channelInfo.channelID, this._channelInfo.channelUnderlayID, this.onUnderlayImageReceived);
					} else {
						References.debug("ChannelPlayerPanel: No underlay image supplied for \""+this._channelInfo.channelID+"\".");
						this.requestOverlayImage();
					}//else
				}//if
			}//if
		}//requestUnderlayImage
		
		private function requestOverlayImage():void {
			if ((this._channelInfo!=null) && (this.stage!=null)) {
				if (this._overlayImage!=null) {
					if (this.overlayContainer.contains(this._overlayImage)) {
						this.overlayContainer.removeChild(this._overlayImage);
					}//if
				}//if
				if (References.announceChannel!=null) {
					var event:LoadingIndicatorEvent=new LoadingIndicatorEvent(LoadingIndicatorEvent.SHOW);
					SwagDispatcher.dispatchEvent(event, this);
					event=new LoadingIndicatorEvent(LoadingIndicatorEvent.UPDATE);
					event.updateText="(2 of 3) Loading...";
					SwagDispatcher.dispatchEvent(event, this);
					event=new LoadingIndicatorEvent(LoadingIndicatorEvent.START);
					SwagDispatcher.dispatchEvent(event, this);
					if (this._channelInfo.channelOverlay) {
						References.debug("ChannelPlayerPanel: Now requesting overlay image \""+this._channelInfo.channelOverlayID+"\" for \""+this._channelInfo.channelID+"\".");
						References.announceChannel.requestShare(this._channelInfo.channelID, this._channelInfo.channelOverlayID, this.onOverlayImageReceived);
					} else {
						References.debug("ChannelPlayerPanel: No overlay image supplied for \""+this._channelInfo.channelID+"\".");
						if (this._autoStartChannel) {
							this.setupVideoPlayback();
						}//if
					}//else
				}//if
			}//if
		}//requestOverlayImage	
		
		public function onUnderlayImageProgress(eventObj:SwagCloudEvent):void {		
			var event:LoadingIndicatorEvent=new LoadingIndicatorEvent(LoadingIndicatorEvent.UPDATE);
			var percentLoaded:Number=Math.round((eventObj.cloudShare.numberOfReceivedChunks/eventObj.cloudShare.numberOfChunks)*100);
			event.updateText="(1 of 3) "+String(percentLoaded)+"%";			
			SwagDispatcher.dispatchEvent(event, this);
		}//onUnderlayImageProgress
		
		public function onUnderlayImageReceived(eventObj:SwagCloudEvent):void {			
			References.debug("ChannelPlayerPanel: Underlay image data loaded in "+String(eventObj.cloudShare.data.length)+" bytes.");
			References.debug("ChannelPlayerPanel:    Received "+String(eventObj.cloudShare.numberOfChunks)+" chunks from peers as a "+eventObj.cloudShare.encoding+"-encoded object.");
			SwagDataTools.byteArrayToDisplayObject(eventObj.cloudShare.data, this.onUnderlayImageProcessed)
		}//onUnderlayImageReceived
		
		public function onOverlayImageProgress(eventObj:SwagCloudEvent):void {		
			var event:LoadingIndicatorEvent=new LoadingIndicatorEvent(LoadingIndicatorEvent.UPDATE);
			var percentLoaded:Number=Math.round((eventObj.cloudShare.numberOfReceivedChunks/eventObj.cloudShare.numberOfChunks)*100);
			event.updateText="(2 of 3) "+String(percentLoaded)+"%";		
			SwagDispatcher.dispatchEvent(event, this);
		}//onOverlayImageProgress
		
		public function onOverlayImageReceived(eventObj:SwagCloudEvent):void {
			References.debug("ChannelPlayerPanel: Overlay image data loaded in "+String(eventObj.cloudShare.data.length)+" bytes.");
			References.debug("ChannelPlayerPanel:    Received "+String(eventObj.cloudShare.numberOfChunks)+" chunks from peers as a "+eventObj.cloudShare.encoding+"-encoded object.");
			SwagDataTools.byteArrayToDisplayObject(eventObj.cloudShare.data, this.onOverlayImageProcessed);			
		}//onOverlayImageReceived
		
		public function  onUnderlayImageProcessed(eventObj:Event):void {
			eventObj.target.removeEventListener(Event.INIT, this.onOverlayImageProcessed);
			this._underlayImage=eventObj.target.content;
			References.debug("ChannelPlayerPanel: Underlay image decoded to "+String(this._underlayImage.loaderInfo.bytesTotal)+" bytes. Image dimensions "+String(this._underlayImage.bitmapData.width)+"x"+String(this._underlayImage.bitmapData.height)+" pixels.");
			this._underlayImage.alpha=0;
			this._underlayImage.visible=false;
			this.underlayContainer.addChild(this._underlayImage);
			if (this._underlayTween!=null) {
				this._underlayTween.stop();
				this._underlayTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onUnderlayImageShown);
				this._underlayTween=null;
			}//if
			this._underlayImage.visible=true;
			this._underlayTween=new Tween(this._underlayImage, "alpha", Regular.easeOut, 0, 1, 0.5, true);
			this._underlayTween.addEventListener(TweenEvent.MOTION_FINISH, this.onUnderlayImageShown);
			this._underlayTween.start();
		}//onUnderlayImageProcessed
		
		private function onUnderlayImageShown(eventObj:TweenEvent):void {
			this._underlayTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onUnderlayImageShown);
			this.requestOverlayImage();
		}//onUnderlayImageShown
		
		public function onOverlayImageProcessed(eventObj:Event):void {
			eventObj.target.removeEventListener(Event.INIT, this.onOverlayImageProcessed);
			this._overlayImage=eventObj.target.content;
			References.debug("ChannelPlayerPanel: Overlay image decoded to "+String(this._overlayImage.loaderInfo.bytesTotal)+" bytes. Image dimensions "+String(this._overlayImage.bitmapData.width)+"x"+String(this._overlayImage.bitmapData.height)+" pixels.");
			this._overlayImage.alpha=0;
			this._overlayImage.visible=false;
			this.overlayContainer.addChild(this._overlayImage);	
			if (this._overlayTween!=null) {
				this._overlayTween.stop();
				this._overlayTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onOverlayImageShown);
				this._overlayTween=null;
			}//if
			this._overlayImage.visible=true;
			this._overlayTween=new Tween(this._overlayImage, "alpha", Regular.easeOut, 0, 1, 0.5, true);
			this._overlayTween.addEventListener(TweenEvent.MOTION_FINISH, this.onOverlayImageShown);
			this._overlayTween.start();
		}//onOverlayImageProcessed
		
		private function onOverlayImageShown(eventObj:TweenEvent):void {
			this._underlayTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onUnderlayImageShown);
			if (this._autoStartChannel) {
				this.setupVideoPlayback();
			}//if
		}//onOverlayImageShown
		
		public function setupVideoPlayback():void {
			//Check to see if live timeline is present. If so, it will control playback otherwise
			//connect and start streaming automatically
			var liveTimeline:Boolean=false;
			try {
				if (this._channelInfo.liveTimeline!=null) {
					liveTimeline=true;
				}//if
			} catch (e:*) {				
			}//catch
			if (liveTimeline) {	
				if (this._tempFadeEffect!=null) {
					this._tempFadeEffect.destroy();
					this._tempFadeEffect=null;
				}
				this._tempFadeEffect=new SimpleVideoFadeEffect(this._video);
				var beaconSampleRate:int=100;
				try {
					if (this._channelInfo.liveTimeline!=null) {	
						beaconSampleRate=this._channelInfo.liveTimelineSampleRate;
						this._liveTimeline=new Timeline(this._video, beaconSampleRate, this._channelInfo.liveTimeline);
					} else {
						this._liveTimeline=new Timeline(this._video, beaconSampleRate, null);	
					}//else
				} catch (e:*) {
					this._liveTimeline=new Timeline(this._video, beaconSampleRate, null);
				} finally {
					//Stream control MUST be created before starting the timeline!
					this._streamControl=new StreamControlEffect(this);
					if (SwagDataTools.isXML(this._channelInfo.liveTimeline.@channel)) {
						References.announceChannel.registerLiveTimelineChannel(this._liveTimeline, this._channelInfo.liveTimeline.@channel);
					}//if
					this._liveTimeline.start();
				}//finally				
			} else {
				this.startVideoPlayBack();
				this.startAudioPlayback();
			}//else
		}//setupVideoPlayback		
		
		public function startVideoPlayBack(eventObj:TimelineEvent=null):void {
			var event:LoadingIndicatorEvent=new LoadingIndicatorEvent(LoadingIndicatorEvent.SHOW);
			SwagDispatcher.dispatchEvent(event, this);
			event=new LoadingIndicatorEvent(LoadingIndicatorEvent.UPDATE);
			event.updateText="(3 of 3) Playing...";			
			SwagDispatcher.dispatchEvent(event, this);
			event=new LoadingIndicatorEvent(LoadingIndicatorEvent.START);
			SwagDispatcher.dispatchEvent(event, this);	
			if (eventObj==null) {
				if (this._channelInfo.videoBroadcast) {
					var channelID:String=this.group_prefix+this._channelInfo.channelName;				
					References.debug ("ChannelPlayerPanel: Beginning video stream \""+channelID+"\"");
					this._video.attachRemoteStream(channelID, channelID, null, false);
					this._video.createDisplay(false);	
					this._video.onConnectStream=this.onBeginPlayback;
				}//if
			} else {
				var IDNode:XML=eventObj.payload.id[0] as XML;
				channelID=this.group_prefix+String(IDNode.children().toString());
				this._video.createDisplay(false);
				this._video.onConnectStream=this.onBeginPlayback;				
				if (eventObj.invoke==TimelineInvokeConstants.VIDEO_START_LIVESTREAM) {					
					this._video.attachRemoteStream(channelID, channelID, null, false);	
					References.debug ("ChannelPlayerPanel: Beginning live video stream \""+channelID+"\"");
				} else if (eventObj.invoke==TimelineInvokeConstants.VIDEO_START_RECSTREAM) {
					this._video.attachRemoteDistributedStream(channelID, channelID, null, false);
					References.debug ("ChannelPlayerPanel: Beginning distributed video stream \""+channelID+"\"");
				}//else
			}//else
		}//startVideoPlayback
				
		
		public function startAudioPlayback(eventObj:TimelineEvent=null):void {
			//Automatically included in stream so there's not much to do. 
			if (this._channelInfo.audioBroadcast) {
				var channelID:String=this.group_prefix+this._channelInfo.channelName;				
				References.debug ("ChannelPlayerPanel: Beginning audio stream \""+channelID+"\"");			
			}//if			
		}//startAudioPlayback
		
		public function onBeginPlayback():void {			
			var event:LoadingIndicatorEvent=new LoadingIndicatorEvent(LoadingIndicatorEvent.HIDE);
			SwagDispatcher.dispatchEvent(event, this);
			event=new LoadingIndicatorEvent(LoadingIndicatorEvent.UPDATE);
			event.updateText="CHANNEL IS PLAYING";			
			SwagDispatcher.dispatchEvent(event, this);
			event=new LoadingIndicatorEvent(LoadingIndicatorEvent.STOP);
			SwagDispatcher.dispatchEvent(event, this);
		}//onBeginPlayback
		
		public function get underlayContainer():MovieClip {
			if (this._underlayContainer==null) {
				this._underlayContainer=new MovieClip();
			}//if			
			return (this._underlayContainer);
		}//get underlayContainer
		
		public function get overlayContainer():MovieClip {
			if (this._overlayContainer==null) {
				this._overlayContainer=new MovieClip();
			}//if			
			return (this._overlayContainer);
		}//get overlayContainer
		
		override public function initialize():void {
			var autoPlaySCID:String=Settings.getWebParameter("play_scid", true, false);
			if (autoPlaySCID!=null) {
				this.playChannelBySCID(autoPlaySCID);
			}//if
		}//initialize
		
	}//ChannelPlayerPanel class
	
}//package