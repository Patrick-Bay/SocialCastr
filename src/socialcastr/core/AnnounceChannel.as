package socialcastr.core {
	
	/**
	 * 
	 * Main public channel (SwagCloud or NetGroup connection) used for announcing new broadcasts.
	 * <p>All public SocialCastr channels must use this class to announce their presence whenever requested.</p>
	 * <p>On the receiver end, this class is used to initiate a broadcast which receives responses from live streams (channel info). 
	 * Conversely, in broadcasters this class listens for channel info requests and responds to them.</p> 
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
	
	import flash.display.Bitmap;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.core.AnnounceChannelQueueItem;
	import socialcastr.core.Timeline;
	import socialcastr.core.TimelineElement;
	import socialcastr.events.AnnounceChannelEvent;
	import socialcastr.interfaces.core.IAnnounceChannel;
	import socialcastr.ui.panels.BroadcastPanel;
	import socialcastr.ui.panels.ChannelSetupPanel;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.events.SwagCloudEvent;
	import swag.network.SwagCloud;
	import swag.network.SwagCloudShare;

	/**
	 * Provides communication facilities with the main public SocialCastr Announce Channel.
	 * <p>As the name implies, the Announce Channel is a special <code>SwagCloud</code> connection that
	 * serves to publicly and globally announce new peers, channels, data shares, or any other information
	 * that needs to be shared and / or announced publicly.</p>
	 * <p>Because of its central role in the SocialCastr system, <code>AnnounceChannel</code> is considered
	 * a core class and should be updated with care.</p>
	 *  
	 * @author Patrick Bay
	 * 
	 */
	public class AnnounceChannel implements IAnnounceChannel {
				
		private static const _announceChannelName:String="SocialCastr.Public.Announce:";
		private static const _channelHash:String="4No+u[nN$3;Ch|@ZN>L 7";
		private static const _channelPassword:String="$oc,1@lcs+r~bUPLAk*EnN0unts}sH'n.e3L";
		private static const _dataSharePrefix:String="SocialCastr.Public.DataShare:";
		private static const _liveTimelinePrefix:String="SocialCastr.Public.LiveTimeline:";
		private static var _channel:SwagCloud=null;
		private static var _liveTimelines:Vector.<Timeline>=null;
		private static var _channelConnected:Boolean=false;
		private static var _channelConnecting:Boolean=false;
		private static var _autoAnnounceAVChannel:BroadcastPanel=null
		/**
		 * Used to share data in a unified way through the announce channel mechanism (although new groups are
		 * created for shares, making them technically separate). 
		 */		
		private static var _dataShares:Vector.<Object>=new Vector.<Object>();
		
		public function AnnounceChannel() {		
			References.announceChannel=this;
		}//constructor
		
		/**
		 * Initializes the announce channel by starting its connection process if one hasn't yet been started.
		 */
		public function initialize():void {
			if (!this.connected) {
				this.connectChannel();
			}//if
		}//initialize
		
		/**
		 * Requests a list of Audio/Visual channels currently being announced.
		 * <p>Subscribe to <code>socialcastr.events.AnnounceChannelEvent.ONAVCHANNELINFO</code> to be notified of
		 * results as they're received.</p>		 
		 *  
		 * @param audioOnly If <em>true</em>, only audio channels will be requested.
		 * @param videoOnly If <em>true</em>, only video channels will be requested.
		 * @param SCID Request channels matching only a specific SCID. If this value is <em>null</em> (default), or an empty
		 * string, all channels are requested.
		 * 
		 * @return <tm>True</em> if the request was successfully sent or queued, <em>false</em> otherwise (for example, if both
		 * <code>audioOnly</code> and <code>videoOnly</code> are set to <em>true</em>. 
		 * 
		 */
		public function requestAVChannels(audioOnly:Boolean=false, videoOnly:Boolean=false, SCID:String=null):Boolean {
			References.debug("AnnounceChannel: Requesting AV channel list with parameters: video only="+videoOnly+", audio only="+audioOnly);			
			if (this.connected) {
				AnnounceChannelQueueItem.executeNext();			
			} else {
				var newQueueItem:AnnounceChannelQueueItem=new AnnounceChannelQueueItem(this.requestAVChannels, this, audioOnly, videoOnly);
				References.debug("AnnounceChannel: Connection not present so queueing request action.");
				this.connectChannel();
				return (false);
			}//else
			if ((audioOnly==true) && (videoOnly==true)) {
				return (false);
			}//if	
			var requestObject:Object=new Object();
			requestObject.requestType="AVChannelInfoRequest";
			if ((SCID!=null) && (SCID!="")) {
				requestObject.SCID=SCID;
			}//if
			newQueueItem=new AnnounceChannelQueueItem(_channel.broadcast, _channel, requestObject, false);			
			if (connected) {
				AnnounceChannelQueueItem.executeNext();			
			} else {
				this.connectChannel();
			}//else
			return (true);
		}//requestAVChannels
		
		/**
		 * Announces a newly broadcasting AV channel to the world or to a single peer (typically as a response to a request).
		 *  
		 * @param sourceBroadcastPanel The <code>BroadcastPanel</code> instance that is now broadcasting and should be announced.
		 * @param peerID The optional peer ID to send the announcement to. If omitted, <em>null</em>, or an empty string, a broadcast is made.
		 * @param autoAnnounce If <em>true</em>, the sourceBroadcastPanel reference will be stored and the panel will automatically be
		 * re-announced whenever a new request is made so long as a broadcast is active. If this is <em>false</em>, the channel will
		 * only be announced when this method is invoked directly (on a timer, for example).
		 * @param includeSCID Used only if a valid <code>peerID</code> is supplied, this includes a SCID with the announce object (typically
		 * a response for a 
		 * 
		 */
		public function announceNewAVChannel(sourceBroadcastPanel:BroadcastPanel=null, peerID:String=null, autoAnnounce:Boolean=true, includeSCID:Boolean=false):void {
			References.debug("AnnounceChannel: Announcing AV channel.");
			if (this.connected) {
				AnnounceChannelQueueItem.executeNext();			
			} else {
				var newQueueItem:AnnounceChannelQueueItem=new AnnounceChannelQueueItem(this.announceNewAVChannel, this, sourceBroadcastPanel, peerID, autoAnnounce);
				References.debug("AnnounceChannel: Connection not present so queueing announce action.");
				this.connectChannel();
				return;
			}//else
			if (sourceBroadcastPanel==null) {					
				return;
			}//if		
			if (autoAnnounce) {
				autoAnnounceAVChannel=sourceBroadcastPanel;
			} else {
				autoAnnounceAVChannel=null;
			}//else
			var infoObject:Object=new Object();
			infoObject.requestType="AVChannelInfoReply";		
			infoObject.channelName=Settings.getPanelDataByID("channel_setup", "channelName", String);			
			infoObject.channelID=infoObject.channelName; //Currently the ID is the same thing as the name
			infoObject.channelDescription=Settings.getPanelDataByID("channel_setup", "channelDescription", String);
			var iconFileName:String=Settings.getPanelDataByID("channel_setup", "iconImage", String);
			if ((iconFileName!=null) && (iconFileName!="")) {
				infoObject.channelIcon=true;
			} else {
				infoObject.channelIcon=false;
			}//else		
			infoObject.channelIconID=iconFileName;
			var underlayImageName:String=Settings.getPanelDataByID("channel_setup", "backgroundImage", String);
			if ((underlayImageName!=null) && (underlayImageName!="")) {
				infoObject.channelUnderlay=true;
			} else {
				infoObject.channelUnderlay=false;
			}//else		
			infoObject.channelUnderlayID=underlayImageName;
			var overlayImageName:String=Settings.getPanelDataByID("channel_setup", "foregroundImage", String);
			if ((overlayImageName!=null) && (overlayImageName!="")) {
				infoObject.channelOverlay=true;
			} else {
				infoObject.channelOverlay=false;
			}//else					
			infoObject.channelOverlayID=overlayImageName;
			infoObject.videoBroadcast=sourceBroadcastPanel.videoBroadcastActive;
			infoObject.audioBroadcast=sourceBroadcastPanel.audioBroadcastActive;
			infoObject.liveTimeline=sourceBroadcastPanel.liveTimelineXML; //Existing (pre-recorded) live timeline elements.
			infoObject.liveTimelineChannel=_liveTimelinePrefix+Settings.getSCID(); //Channel across which live timeline elements are broadcast
			infoObject.liveTimelineSampleRate=sourceBroadcastPanel.liveTimeline.sampleRate; //Provides support for different startup sample rates			
			if ((peerID!=null) && (peerID!="")) {
				if (includeSCID) {
					infoObject.SCID=Settings.getSCID();
				}//if
				if (connected) {
					AnnounceChannelQueueItem.executeNext();
					References.debug("AnnounceChannel: Now sending channel info directly to peer \""+peerID+"\".");
					_channel.send(infoObject, peerID);								
				} else {
					newQueueItem=new AnnounceChannelQueueItem(_channel.send, _channel, infoObject, peerID);
					this.connectChannel();
				}//else
			} else {
				if (connected) {
					AnnounceChannelQueueItem.executeNext();
					References.debug("AnnounceChannel: Broadcasting channel info globally.");
					_channel.broadcast(infoObject, false);
				}  else {					
					newQueueItem=new AnnounceChannelQueueItem(_channel.broadcast, _channel, infoObject, false);
					this.connectChannel();
				}//else
			}//else
		}//announceNewAVChannel
		
		/** 
		 * @return A vector of all of the live timelines registered with the announce channel by the application.
		 */
		public function get liveTimelines():Vector.<Timeline> {
			if (_liveTimelines==null) {
				_liveTimelines=new Vector.<Timeline>();
			}//if
			return (_liveTimelines);
		}//get liveTimeliness
		
		/**
		 * Returns a reference to a specific <code>SwagCloud</code> instance associated with a <code>Timeline</code>,
		 * or <em>null</em> if none can be found.
		 *  
		 * @param cloudInstance The <code>SwagCloud</code> to match to an associated Timeline.
		 * 
		 * @return The <code>Timeline</code> instance associated with a <code>SwagCloud</code> instance,
		 * or <em>null</em> if no match can be found.
		 * 
		 */
		public function getTimelineForCloud(cloudInstance:SwagCloud):Timeline {
			if (cloudInstance==null) {
				return (null);
			}//if
			for (var count:uint=0; count<liveTimelines.length; count++) {
				var currentTimeline:Timeline=liveTimelines[count] as Timeline;
				if (currentTimeline.announceChannelCloud==cloudInstance) {
					return (currentTimeline);
				}//if
			}//for
			return (null);
		}//getTimelineForCloud
		
		/**
		 * Registers a Live Timeline with the Announce Channel if it hasn't already been registered.
		 * A live timeline should
		 *  
		 * @param timeline The <code>Timeline</code> object to register with the Announce Channel.
		 * @param compoundID An optional channel ID to use instead of an automatically generated (source) compound
		 * Live Timeline channel ID. If <em>null</em> or an empty string, the automatically generated compound ID is used.
		 * 
		 * @return The <code>SwagCloud</em> instance associated with the newly registered Timeline,
		 * or <em>null</em> if it couldn't be registered (already registered, for example). Alternately,
		 * the Timeline's <code>announceChannelCloud</code> property may be examined for this reference.
		 * 
		 */
		public function registerLiveTimelineChannel(timeline:Timeline, compoundID:String=null):SwagCloud {			
			if (timeline==null) {
				return (null);
			}//if			
			if (timeline.announceChannelCloud!=null) {
				return (null);
			}//if			
			for (var count:uint=0; count<liveTimelines.length; count++) {
				var currentTimeline:Timeline=liveTimelines[count] as Timeline;
				if (currentTimeline==timeline) {
					return (null);
				}//if
			}//for				
			liveTimelines.push(timeline);
			var timelineNum:String=String(liveTimelines.length);
			if ((compoundID==null) || (compoundID=="")) {
				var compoundGroup:String=_liveTimelinePrefix+Settings.getSCID()+":timeline_"+timelineNum;
				References.debug("AnnounceChannel: Registering new Live Timeline \""+compoundGroup+"\"");
			} else {
				compoundGroup=compoundID;
				References.debug("AnnounceChannel: Registering with Live Timeline \""+compoundGroup+"\"");
			}//else			
			timeline.announceChannelCloud=new SwagCloud();
			SwagDispatcher.addEventListener(SwagCloudEvent.BROADCAST, this.onTimelineChannelBroadcast, this, timeline.announceChannelCloud);
			SwagDispatcher.addEventListener(SwagCloudEvent.DIRECT, this.onTimelineChannelBroadcast, this, timeline.announceChannelCloud);
			SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECT, this.onRegisterLiveTimelineChannel, this, timeline.announceChannelCloud);
			SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECTFAIL, this.onRegisterFailLiveTimelineChannel, this, timeline.announceChannelCloud);
			SwagDispatcher.addEventListener(SwagCloudEvent.GROUPREJECT, this.onRegisterFailLiveTimelineChannel, this, timeline.announceChannelCloud);				
			timeline.announceChannelCloud.connectGroup(compoundGroup, true, compoundGroup);
			return (timeline.announceChannelCloud);
		}//registerLiveTimelineChannel	
		
		/**
		 * Event responder for broadcasts originating from any subscribed Live Timeline channel.
		 * <p>This method is a centralized location for all Live Timeline broadcasts and typically shouldn't be
		 * invoked directly. Instead, register a new <code>Timeline</code> object with the <code>registerLiveTimelineChannel</code>
		 * method to allow the announce channel to invoke it automatically on any broadcast.
		 * 
		 * @param eventObj A <code>SwagCloudEvent</code> event object.
		 * 
		 */
		public function onTimelineChannelBroadcast(eventObj:SwagCloudEvent):void {
			for (var count:uint=0; count<liveTimelines.length; count++) {
				var currentTimeline:Timeline=liveTimelines[count] as Timeline;
				if (currentTimeline!=null) {
					if (currentTimeline.announceChannelCloud==eventObj.source) {
						var elementData:*=eventObj.data;
						currentTimeline.incorporateElements(elementData);
						return;
					}//if
				}//if
			}//for
		}//onTimelineChannelBroadcast
		
		/**
		 * Attempts to broadcast all queued items in a <code>Timeline</code> through it's <code>SwagCloud</code> object.
		 * 
		 * @param timeline The <code>Timeline</code> containing queued items to attempt to broadcast.
		 * 
		 * @return <em>True</em> if the queued items were successfully sent, <em>false</em> if the broadcast failed
		 * or no items were queued for broadcast. 
		 * 
		 */
		public function broadcastLiveTimeline(timeline:Timeline):Boolean {				
			if (timeline==null) {
				return (false);
			}//if
			if (timeline.announceChannelCloud==null) {
				return (false);
			}//if
			if (timeline.announceChannelCloud.groupConnected==false) {
				return (false);
			}//if
			if (timeline.broadcastElementsQueue.length==0) {
				return (false);
			}//if			
			while (timeline.broadcastElementsQueue.length>0) {				
				try {
					var currentElement:TimelineElement=timeline.broadcastElementsQueue.pop();				
					if (currentElement!=null) {
						//Trigger in peers...						
						timeline.announceChannelCloud.broadcast(currentElement.elementData, true);
						//...and locally.
						currentElement.invoke();
					}//if
				} catch (e:*) {
					//Something strange happened to the queue if we ever get here.
					return (false);
				}//catch
			}//for
			return (true);
		}//broadcastLiveTimeline
		
		/**
		 * Event responder to handle connections to new Live Timeline channels. All timeline channels connect through
		 * this method if registered with the announce channel and so this method shouldn't be called directly. To
		 * be notified of timeline channel connections, subscribe to the SwAG event "AnnounceChannelEvent.ONLIVETIMELINEREG".
		 *  
		 * @param eventObj A <code>SwagCloudEvent</code> event object.
		 * 
		 */
		public function onRegisterLiveTimelineChannel(eventObj:SwagCloudEvent):void {
			var targetTimeline:Timeline=this.getTimelineForCloud(eventObj.source);
			var compoundGroup:String=SwagCloud(eventObj.source).groupName;
			References.debug("AnnounceChannel: Live Timeline successfully registered: \""+compoundGroup+"\"");
			SwagDispatcher.removeEventListener(SwagCloudEvent.BROADCAST, this.onTimelineChannelBroadcast, eventObj.source);
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onRegisterLiveTimelineChannel, eventObj.source);
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECTFAIL, this.onRegisterFailLiveTimelineChannel, eventObj.source);
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPREJECT, this.onRegisterFailLiveTimelineChannel, eventObj.source);			
			var event:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONLIVETIMELINEREG);
			event.timeline=targetTimeline;
			event.cloudEvent=eventObj;
			SwagDispatcher.dispatchEvent(event, this);
		}//onRegisterLiveTimelineChannel
		
		/**
		 * Event responder to handle connection failures to new Live Timeline channels. All timeline channel connection failures happen through
		 * this method if registered with the announce channel and so this method shouldn't be called directly. To
		 * be notified of timeline channel connection failures, subscribe to the SwAG event "AnnounceChannelEvent.ONLIVETIMELINEREGFAIL".
		 *  
		 * @param eventObj A <code>SwagCloudEvent</code> event object.
		 * 
		 */
		public function onRegisterFailLiveTimelineChannel(eventObj:SwagCloudEvent):void {
			var targetTimeline:Timeline=this.getTimelineForCloud(eventObj.source);
			var compoundGroup:String=SwagCloud(eventObj.source).groupName;
			References.debug("AnnounceChannel: Failed to connect Live Timeline: \""+compoundGroup+"\"");
			SwagDispatcher.removeEventListener(SwagCloudEvent.BROADCAST, this.onTimelineChannelBroadcast, eventObj.source);
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onRegisterLiveTimelineChannel, eventObj.source);
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECTFAIL, this.onRegisterFailLiveTimelineChannel, eventObj.source);
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPREJECT, this.onRegisterFailLiveTimelineChannel, eventObj.source);			
			var event:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONLIVETIMELINEREGFAIL);
			event.timeline=targetTimeline;
			event.cloudEvent=eventObj;
			SwagDispatcher.dispatchEvent(event, this);
		}//onRegisterFailLiveTimelineChannel
		
		/**
		 * Announces that an AV channel is about to disconnect. Channel disconnections typically happen automatically so
		 * this method is somewhat redundant but it may be expanded at some point in the future to cause peers to disconnect
		 * from a channel without actually disconnecting the channel.
		 *  
		 * @param sourceBroadcastPanel A reference to the source broadcast panel hosting the stream to be closed.
		 * 
		 */
		public function announceCloseAVChannel(sourceBroadcastPanel:BroadcastPanel=null):void {
			References.debug("AnnounceChannel: Announcing pending disconnect to AV channel.");
			if (connected) {
				AnnounceChannelQueueItem.executeNext();			
			} else {
				References.debug("AnnounceChannel: Couldn't announce AV channel close because Announce channel is disconnected!");
				_channelConnected=false;
				return;
			}//else
			autoAnnounceAVChannel=null;
			var infoObject:Object=new Object();
			infoObject.requestType="AVChannelAnnounceClose";
			//Include complete information so that complete matching can be done on receiving end.
			infoObject.channelName=Settings.getPanelDataByID("channel_setup", "channelName", String);
			infoObject.channelID=infoObject.channelName;
			infoObject.SCID=Settings.getSCID();
			infoObject.channelDescription=Settings.getPanelDataByID("channel_setup", "channelDescription", String);
			var iconFileName:String=Settings.getPanelDataByID("channel_setup", "iconImage", String);
			if ((iconFileName!=null) && (iconFileName!="")) {
				infoObject.channelIcon=true;
			} else {
				infoObject.channelIcon=false;
			}//else		
			infoObject.channelIconID=iconFileName;
			var underlayImageName:String=Settings.getPanelDataByID("channel_setup", "backgroundImage", String);
			if ((underlayImageName!=null) && (underlayImageName!="")) {
				infoObject.channelUnderlay=true;
			} else {
				infoObject.channelUnderlay=false;
			}//else		
			infoObject.channelUnderlayID=underlayImageName;
			var overlayImageName:String=Settings.getPanelDataByID("channel_setup", "foregroundImage", String);
			if ((overlayImageName!=null) && (overlayImageName!="")) {
				infoObject.channelOverlay=true;
			} else {
				infoObject.channelOverlay=false;
			}//else		
			infoObject.channelOverlayID=overlayImageName;
			//All closed, so hard-coded false.
			infoObject.videoBroadcast=false;
			infoObject.audioBroadcast=false;			
			if (connected) {
				References.debug("AnnounceChannel: Signining off...");
				_channel.broadcast(infoObject, false);
			}  else {				
				References.debug("AnnounceChannel: Already disconnected!");
			}//else
		}//announceCloseAVChannel
		
		/**
		 * Responds to all public channel broadcasts.
		 * 
		 * <p>As the announce channel's workhorse, this method must be kept as optimized as possible.</p>
		 *  
		 * @param eventObj A <code>SwagCloudEvent</code> object received from the announce <code>SwagCloud</code> instance.
		 * 
		 */
		public function onChannelBroadcast(eventObj:SwagCloudEvent):void {			
			AnnounceChannelQueueItem.executeNext();
			try {
				var requestType:String=new String (eventObj.data.requestType);				
				switch (requestType) {
					case "AVChannelInfoRequest" : 
						this.onChannelInfoRequest(eventObj);
						break;
					case "AVChannelInfoReply" :					
						var broadcastObj:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONAVCHANNELINFO);
						broadcastObj.channelInfo=eventObj.data;
						broadcastObj.cloudEvent=eventObj;
						SwagDispatcher.dispatchEvent(broadcastObj, this);						
						break;			
					default : 
						References.debug("AnnounceChannel: Unrecognized AV channel request type \""+requestType+"\" received.");
						break;
				}//switch
			} catch (e:*) {
				References.debug("AnnounceChannel: Invalid AV channel request object received.");
			} finally {
				if (connected) {
					AnnounceChannelQueueItem.executeNext();			
				}//if
			}//finally	
		}//onChannelBroadcast
		
		/**
		 * Responds to all direct channel messages.
		 * 
		 * <p>These are different from broadcasts in that they are directed specifically to this peer.</p>
		 *  
		 * @param eventObj A <code>SwagCloudEvent</code> object received from the announce <code>SwagCloud</code> instance.
		 * 
		 */
		public function onDirectChannelMessage(eventObj:SwagCloudEvent):void {	
			References.debug("AnnounceChannel: Direct message received from peer \""+eventObj.remotePeerID+"\".");		
			AnnounceChannelQueueItem.executeNext();			
			try {
				var requestType:String=new String (eventObj.data.requestType);
				switch (requestType) {
					case "AVChannelInfoRequest" : 
						this.onChannelInfoRequest(eventObj);
						break;
					case "AVChannelInfoReply" :					
						var broadcastObj:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONAVCHANNELINFO);
						broadcastObj.channelInfo=eventObj.data;
						broadcastObj.cloudEvent=eventObj;
						SwagDispatcher.dispatchEvent(broadcastObj, this);
						break;				
					default:
						References.debug("AnnounceChannel: Unrecognized AV channel request response type \""+requestType+"\" received.");
						break;
				}//switch				
			} catch (e:*) {
				References.debug("AnnounceChannel: Invalid AV channel request object received.");
			} finally {
				AnnounceChannelQueueItem.executeNext();
			}//finally			
		}//onDirectChannelMessage
		
		/**
		 * Begin sharing a data item over the Announce Channel.
		 * 
		 * <p>This creates a <code>SwagCloud</code> instance that is used to begin sharing the data.</p>
		 * <p>The sharing channel created is controlled by the announce channel but is a separate <code>SwagCloud</code> instance.
		 * As such, care should be taken to destroy any references when a share is removed from memory.</p>
		 * <p>The share group name and password are creeated using: _dataSharePrefix+channelID+shareID</p>
		 * <p>A share may not begin immediately but rather is started asynchronously as soon as the associated group is connected.</p>
		 * 
		 * @param channelID The source channel ID for which to begin sharing.
		 * @param shareID The name of the share to begin sharing. This is a symbolic reference and can be anything (file name, alpha numeric sequence, etc.)
		 * @param shareData The data to share. Binary structures such as <code>ByteArray</code> are preferred, but any basic Flash data object
		 * (String, Boolean, uint, int, Number, Object, Class, MovieClip, Sprite, Bitmap, etc.), is valid. If using non-standard Flash types, they will need
		 * to be re-constructed on the receiving end.
		 * @param chunkBytes The bytes per distributed chunk. This value should reflect a balance between overhead (information attached to each chunk), and
		 * the size of the chunk. For example, setting this value to 1 creates single byte chunks with multiple bytes of informational payload attached. At
		 * the same time, very large chunk sizes mean very inefficient transfers (if the chunk is not received, it needs to be resent -- all of it).
		 * 
		 * @return The <code>SwagCloud</code> instance created for the data share, or <code>null</code> if one couldn't be creates.  
		 * 
		 */
		public function beginSharing(channelID:String=null, shareID:String=null, shareData:*=null, chunkBytes:uint=64000):SwagCloud {
			References.debug ("AnnounceChannel: Connecting peer to peer share of \""+shareID+"\" on channel \""+channelID+"\".");			
			if (this.connected) {
				AnnounceChannelQueueItem.executeNext();			
			} else {
				var newQueueItem:AnnounceChannelQueueItem=new AnnounceChannelQueueItem(this.beginSharing, this, channelID, shareID, shareData, chunkBytes);
				References.debug("AnnounceChannel: Connection not present so queueing share action.");
				this.connectChannel();
				return (null);
			}//else
			if ((channelID==null) || (channelID=="")) {
				return (null);
			}//if
			if ((shareID==null) || (shareID=="")) {
				return (null);
			}//if
			this.compactShareInfo();
			//Mimics the structure of the "requestShare" method... (they must match!)
			//var compoundID:String=_dataSharePrefix+channelID+":"+shareID;
			//Note that we're not using the SCID as an identifier instead of channel name to prevent collisions.
			var compoundID:String=_dataSharePrefix+Settings.getSCID()+":"+shareID;
			var shareChannel:SwagCloud=new SwagCloud();
			var shareObject:Object=new Object();
			shareObject.channel=shareChannel;
			shareObject.channelID=channelID;
			shareObject.SCID=Settings.getSCID();
			shareObject.shareID=shareID;
			shareObject.compoundID=compoundID;
			shareObject.fullShareID=compoundID;
			shareObject.onReceived=null;
			shareObject.onProgress=null;
			shareObject.data=shareData;
			shareObject.chunkBytes=chunkBytes;
			_dataShares.push(shareObject);
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onBeginSharingConnect, shareChannel);
			SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECT, this.onBeginSharingConnect, this, shareChannel);
			shareChannel.connectGroup(compoundID, true, compoundID);
			return (shareChannel);
		}//beginSharing
		
		/**
		 * Event responder to handle shared / distributed data connections. After a channel is connected, this
		 * method begins the share immediately and for this reason this method is not intended to be called directly.
		 *  
		 * @param eventObj A <code>SwagCloudEvent</code> object.
		 * 
		 */
		public function onBeginSharingConnect(eventObj:SwagCloudEvent):void {
			AnnounceChannelQueueItem.executeNext();
			var cloudInstance:SwagCloud=eventObj.source as SwagCloud;
			References.debug ("AnnounceChannel: Peer to peer sharing connection established.");
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onBeginSharingConnect, cloudInstance);		
			var shareInfo:Object=this.findShareInfo(cloudInstance);
			var share:SwagCloudShare=cloudInstance.distribute(shareInfo.data, shareInfo.chunkBytes);	
			var event:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONSHARECONNECT);
			event.cloudEvent=eventObj;
			SwagDispatcher.dispatchEvent(event, this);
		}//onBeginSharingConnect
		
		/**
		 * Request a data item currently being shared on the announce channel. 
		 *  
		 * @param channelID The source channel ID to request the data for.
		 * @param shareID The share ID to request. Note that the share may not exist so data may not ever be received.
		 * @param onShareReceived The function to invoke when all the shared data has been gathered. This function should have
		 * a <code>SwagCloudEvent</code> as the first parameter as though it's been invoked from the originating <code>SwagCloud</code>
		 * instance.
		 * @param onShareProgress The function to invoke as the shared data is being gathered. This function should have
		 * a <code>SwagCloudEvent</code> as the first parameter as though it's been invoked from the originating <code>SwagCloud</code>
		 * instance.
		 * 
		 * @return The <code>SwagCloud</code> instance created for the share request, or <em>null</em> if one couldn't be created (for example,
		 * the announce channel isn't connected).
		 * 
		 */
		public function requestShare(channelID:String=null, shareID:String=null, onShareReceived:Function=null, onShareProgress:Function=null):SwagCloud {
			References.debug ("AnnounceChannel: Requesting peer to peer share of \""+shareID+"\" on channel \""+channelID+"\".");
			if (connected) {
				AnnounceChannelQueueItem.executeNext();			
			} else {
				var newQueueItem:AnnounceChannelQueueItem=new AnnounceChannelQueueItem(this.requestShare, this, channelID, shareID, onShareReceived, onShareProgress);
				References.debug("AnnounceChannel: Connection not present so queueing share request action.");
				this.connectChannel();
				return (null);
			}//else
			if ((channelID==null) || (channelID=="")) {
				return (null);
			}//if
			if ((shareID==null) || (shareID=="")) {
				return (null);
			}//if					
			this.compactShareInfo();
			//Mimics the structure of the "beginSharing" method... (they must match!)
			//var compoundID:String=_dataSharePrefix+channelID+":"+shareID;
			//Note that we're now using the SCID to generate the compound ID to prevent collisions.
			var compoundID:String=_dataSharePrefix+Settings.getSCID()+":"+shareID;
			var shareChannel:SwagCloud=new SwagCloud();
			var shareObject:Object=new Object();
			shareObject.channel=shareChannel;
			shareObject.channelID=channelID;
			shareObject.SCID=Settings.getSCID();
			shareObject.shareID=shareID;
			shareObject.compoundID=compoundID;
			shareObject.fullShareID=compoundID;
			shareObject.onReceived=onShareReceived;
			shareObject.onProgress=onShareProgress;
			shareObject.data=null;
			shareObject.chunkBytes=0;
			_dataShares.push(shareObject);			
			SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECT, this.onRequestShareConnect, this, shareChannel);
			shareChannel.connectGroup(compoundID, true, compoundID);
			return (shareChannel);
		}//requestShare
		
		/**
		 * Event responder that automatically begins gathering shared data once a shared data connection has been established
		 * on a <code>SwagCloud</code> instance. This method is not intended to be called directly.
		 *   
		 * @param eventObj A <code>SwagCloudEvent</code> object.
		 * 
		 */
		public function onRequestShareConnect(eventObj:SwagCloudEvent):void {
			AnnounceChannelQueueItem.executeNext();			
			References.debug ("AnnounceChannel: Peer to peer sharing connection established. Gathering distributed / shared data.");
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onRequestShareConnect, eventObj.source);
			var cloudInstance:SwagCloud=eventObj.source as SwagCloud;
			var shareInfo:Object=this.findShareInfo(cloudInstance);
			if (shareInfo.onReceived!=null) {
				SwagDispatcher.addEventListener(SwagCloudEvent.GATHER, this.onRequestShareComplete, this, cloudInstance);
			}//if			
			if (shareInfo.onProgress!=null) {
				SwagDispatcher.addEventListener(SwagCloudEvent.CHUNK, this.onRequestShareProgress, this, cloudInstance);
			}//if
			var event:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONSHARECONNECT);
			event.cloudEvent=eventObj;
			SwagDispatcher.dispatchEvent(event, this);
			cloudInstance.gather();			
		}//onRequestShareConnect
		
		/**
		 * Event responder that responds to shared data gathering progress (like download progress) on a <code>SwagCloud</code> instance. 
		 * This method is not intended to be called directly.
		 *   
		 * @param eventObj A <code>SwagCloudEvent</code> object.
		 * 
		 */
		public function onRequestShareProgress(eventObj:SwagCloudEvent):void {
			AnnounceChannelQueueItem.executeNext();	
			var cloudInstance:SwagCloud=eventObj.source as SwagCloud;
			var shareInfo:Object=this.findShareInfo(cloudInstance);
			if (shareInfo.onProgress!=null) {
				shareInfo.onProgress(eventObj);
			}//if
			var event:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONSHAREPROGRESS);
			event.cloudEvent=eventObj;
			SwagDispatcher.dispatchEvent(event, this);
		}//onRequestShareProgress
		
		/**
		 * Event responder that responds to shared data gathering completion (like download progress) on a <code>SwagCloud</code> instance.
		 * 
		 * This method is not intended to be called directly.
		 *   
		 * @param eventObj A <code>SwagCloudEvent</code> object.
		 * 
		 */
		public function onRequestShareComplete(eventObj:SwagCloudEvent):void {
			AnnounceChannelQueueItem.executeNext();
			References.debug ("AnnounceChannel: Peer to peer data transfer complete ("+String(eventObj.cloudShare.data.length)+" bytes).");
			var cloudInstance:SwagCloud=eventObj.source as SwagCloud;
			var shareInfo:Object=this.findShareInfo(cloudInstance);
			SwagDispatcher.removeEventListener(SwagCloudEvent.GATHER, this.onRequestShareComplete, cloudInstance);
			SwagDispatcher.removeEventListener(SwagCloudEvent.CHUNK, this.onRequestShareProgress, cloudInstance);
			if (shareInfo.onProgress!=null) {
				shareInfo.onProgress(eventObj);
			}//if
			if (shareInfo.onReceived!=null) {
				shareInfo.onReceived(eventObj);
			}//if
			this.compactShareInfo(shareInfo);
			var event:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONSHAREGATHER);
			event.cloudEvent=eventObj;
			SwagDispatcher.dispatchEvent(event, this);
		}//onRequestShareComplete
		
		/** 
		 * @return A reference to the <code>BroadcastPanel</code> instance that will be automatically announced
		 * whenever a new peer requests it.
		 */
		public static function get autoAnnounceAVChannel():BroadcastPanel {
			return (_autoAnnounceAVChannel);
		}//get autoAnnounceAVChannel		
		
		public static function set autoAnnounceAVChannel(channelSet:BroadcastPanel):void {
			_autoAnnounceAVChannel=channelSet;
		}//set autoAnnounceAVChannel
		
		/**
		 * Stops auto-announcing the currently assigned <code>BroadcastPanel</code> instance.
		 */
		public static function stopAnnounceAVChannel():void {			
			_autoAnnounceAVChannel=null;
		}//stopAnnounceAVChannel		
		
		/**
		 * Stops sharing the specified shared data either as a sender or as a receiver.
		 *  
		 * @param channelID The target channel ID on which the channel is shared.
		 * @param shareID The target share ID to stop sharing.
		 * 
		 * @return <em>True</em> if an associated share was found and stopped, <em>false</em> otherwise. 
		 * 
		 */
		public function stopSharing(channelID:String=null, shareID:String=null):Boolean {
			if (!connected) {
				return (false);
			}//if
			References.debug ("AnnounceChanne: Stopping sharing of \""+shareID+"\" on channel \""+channelID+"\".");
			for (var count:uint=0; count<_dataShares.length; count++) {
				var currentShare:Object=_dataShares[count] as Object;
				if (currentShare!=null) {
					if ((currentShare.channelID==channelID) && (currentShare.shareID==shareID)) {
						var cloudInstance:SwagCloud=currentShare.channel as SwagCloud;
						SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onRequestShareConnect, cloudInstance);
						SwagDispatcher.removeEventListener(SwagCloudEvent.GATHER, this.onRequestShareComplete, cloudInstance);
						SwagDispatcher.removeEventListener(SwagCloudEvent.CHUNK, this.onRequestShareProgress, cloudInstance);
						SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onBeginSharingConnect, cloudInstance);
						cloudInstance.disconnectGroup();						
						this.compactShareInfo(currentShare);
						return (true);
					}//if
				}//if
			}//for
			return (false);
		}//stopSharing
		
		/**
		 * @private 
		 */
		private function findShareInfo(sourceChannel:SwagCloud):Object {
			if (sourceChannel==null) {
				return (null);
			}//if
			for (var count:uint=0; count<_dataShares.length; count++) {
				var currentShare:Object=_dataShares[count] as Object;
				if (currentShare!=null) {
					if (currentShare.channel==sourceChannel) {
						return (currentShare);
					}//if
				}//if
			}//for
			return (null);
		}//findShareInfo
		
		/**
		 * Compacts the internal list of shared data items, optionally removing items referenced by enclosing
		 * object or the <code>SwagCloud</code> instance. Both references may be used together and if they are omitted
		 * the <code>_dataShares</code> vector is simply compacted to remove any null or orphaned items.
		 *  
		 * @param removeData The enclosing data object (as stored in <code>_dataShares</code>) to optionally include
		 * in the removal.
		 * @param removeChannel The target channel or <code>SwagCloud</code> instance to include in the removal.
		 * 
		 */
		private function compactShareInfo(removeData:Object=null, removeChannel:SwagCloud=null):void {
			var _compactShares:Vector.<Object>=new Vector.<Object>();
			for (var count:uint=0; count<_dataShares.length; count++) {
				var currentShare:Object=_dataShares[count] as Object;
				if (currentShare!=null) {
					if (removeData!=null) { 
						if (removeData!=currentShare) {
							_compactShares.push(currentShare);
						}//if
					} else {
						if (removeChannel!=null) {
							if (removeChannel!=currentShare.channel) {
								_compactShares.push(currentShare);
							}//if
						} else {
							_compactShares.push(currentShare);
						}//else
					}//else
				}//if
			}//for
			_dataShares=_compactShares;
		}//compactShareInfo	
		
		/**
		 * Event responder listening for channel info requests broadcast over the announce channel.
		 * <p>If the <code>autoAnnounceAVChannel</code> isn't set, this method does nothing.
		 * 
		 * @param eventObj A <code>SwagCloudEvent</code> event object.
		 * 
		 */
		public function onChannelInfoRequest(eventObj:SwagCloudEvent):void {			
			if (autoAnnounceAVChannel!=null) {				
				if ((autoAnnounceAVChannel.audioBroadcastActive==false) && (autoAnnounceAVChannel.videoBroadcastActive==false)) {
					//No broadcast is currently active.
					return;
				}//if
				References.debug("AnnounceChannel.onChannelInfoRequest: Sending channel info to peer \""+eventObj.remotePeerID+"\"");
				try {
					if ((eventObj.data.SCID!="") && (eventObj.data.SCID!=null)) {
						this.announceNewAVChannel(autoAnnounceAVChannel, eventObj.remotePeerID, true, true);
					} else {
						this.announceNewAVChannel(autoAnnounceAVChannel, eventObj.remotePeerID);
					}//else
				} catch (e:*) {
					this.announceNewAVChannel(autoAnnounceAVChannel, eventObj.remotePeerID);
				}//catch
			}//if			
		}//onChannelInfoRequest	
		
		/**
		 * Event responder listening for a connection to the announce channel. This method
		 * is not intended to be called directly. Listen for the SwAG event "AnnounceChannelEvent.ONCONNECT"
		 * to be notified of this status.
		 * 
		 * @param eventObj A <code>SwagCloudEvent</code> event object.
		 * 
		 */
		public function onConnectChannel(eventObj:SwagCloudEvent):void {
			References.debug("AnnounceChannel: Connected.");			
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onConnectChannel, _channel);
			//Generate the SCID now that connection is established.
			References.debug("   >>> SCID: "+Settings.getSCID());
			//Set these first otherwise subsequent actions may loop forever!
			_channelConnected=true;			
			_channelConnecting=false;
			var broadcastObj:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONCONNECT);			
			SwagDispatcher.dispatchEvent(broadcastObj, this);		
			//Execute anything that's been queued up.
			while (AnnounceChannelQueueItem.executeNext(false)) {
			}//while			
		}//onConnectChannel
		
		/**
		 * Event responder listening for a connection failure to the announce channel. This method
		 * is not intended to be called directly. Listen for the SwAG event "AnnounceChannelEvent.ONAVCHANNELDISCONNECT"
		 * to be notified of this status.
		 * 
		 * @param eventObj A <code>SwagCloudEvent</code> event object.
		 * 
		 */
		public function onFailConnectAVChannel(eventObj:SwagCloudEvent):void {
			References.debug("AnnounceChannel: Connection to Announce Channel failed ["+eventObj.type+"].");						
			var broadcastObj:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONAVCHANNELDISCONNECT);
			this.removeChannelListeners();
			_channelConnected=false;			
			_channelConnecting=false;
			_channel=null;
			broadcastObj.channelInfo=null;
			broadcastObj.cloudEvent=eventObj;
			SwagDispatcher.dispatchEvent(broadcastObj, this);					
		}//onFailConnectAVChannel
		
		/**
		 * Event responder listening for a new peer connection to the announce channel, automatically
		 * sending the peer channel info for the <code>autoAnnounceAVChannel</code> instance, if set. This
		 * method is not intended to be called directly. Listen for the SwAG event "AnnounceChannelEvent.ONAVCHANNELCONNECT"
		 * to be notified of this status.
		 * 
		 * @param eventObj A <code>SwagCloudEvent</code> event object.
		 * 
		 */
		public function onConnectPeer(eventObj:SwagCloudEvent):void {			
			References.debug("AnnounceChannel: New peer CCID \""+eventObj.remotePeerID+"\" connected.");
			if (autoAnnounceAVChannel!=null) {
				this.announceNewAVChannel(autoAnnounceAVChannel, eventObj.remotePeerID);
			}//if
			if (!this.validateAVChannelData(eventObj.data)) {				
				return;
			}//if
			_channelConnecting=false;
			var broadcastObj:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONAVCHANNELCONNECT);
			broadcastObj.channelInfo=eventObj.data;
			broadcastObj.cloudEvent=eventObj;			
			SwagDispatcher.dispatchEvent(broadcastObj, this);
		}//onConnectPeer
		
		/**
		 * Event responder listening for a new peer connection disconnection from the announce channel. This
		 * method is not intended to be called directly. Listen for the SwAG event "AnnounceChannelEvent.ONAVCHANNELDISCONNECT"
		 * to be notified of this status.
		 * 
		 * @param eventObj A <code>SwagCloudEvent</code> event object.
		 * 
		 */
		public function onDisconnectPeer(eventObj:SwagCloudEvent):void {
			References.debug("AnnounceChannel: Peer CCID \""+eventObj.remotePeerID+"\" disconnected.");
			_channelConnecting=false;
			var broadcastObj:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONAVCHANNELDISCONNECT);
			broadcastObj.channelInfo=null;
			broadcastObj.cloudEvent=eventObj;
			SwagDispatcher.dispatchEvent(broadcastObj, this);
		}//onDisconnectPeer
		
		/**
		 * Event responder listening for a new disconnection from the announce channel. This method is not 
		 * intended to be called directly. Listen for the SwAG event "AnnounceChannelEvent.ONDISCONNECT"
		 * to be notified of this status.
		 * 
		 * @param eventObj A <code>SwagCloudEvent</code> event object.
		 * 
		 */
		public function onDisconnectAnnounceChannel(eventObj:SwagCloudEvent):void {
			References.debug("AnnounceChannel: Announce Channel diconnected (NetStatus: \""+eventObj.statusCode+"\").");
			AnnounceChannelQueueItem.clearQueue();
			this.removeChannelListeners();			
			var broadcastObj:AnnounceChannelEvent=new AnnounceChannelEvent(AnnounceChannelEvent.ONDISCONNECT);
			broadcastObj.channelInfo=null;
			broadcastObj.cloudEvent=eventObj;
			SwagDispatcher.dispatchEvent(broadcastObj, this);	
			_channelConnected=false;			
			_channelConnecting=false;
			_channel=null;			
		}//onDisconnectAnnounceChannel
		
		/** 
		 * @return <em>True</em> if the announce channel is connected, <em>false</em> otherwise.
		 */
		public function get connected():Boolean {
			return (_channelConnected);
		}//get connected
		
		/** 
		 * @return Alias for the <code>connected</code> value.
		 */
		public static function get isConnected():Boolean {
			return (_channelConnected);
		}//get isConnected
		
		/** 
		 * @return <em>True</em> if the announce channel is currently in the process of connecting, 
		 * <em>false</em> otherwise (if connected or not currently connecting).
		 */
		public function get connecting():Boolean {
			return (_channelConnecting);
		}//get connecting
		
		/** 
		 * @return Alias for the <code>connecting</code> value.
		 */
		public static function get isConnecting():Boolean {
			return (_channelConnecting);
		}//get isConnecting
		
		/** 
		 * @private 
		 */
		private function validateAVChannelData(infoObject:Object=null):Boolean {
			if (infoObject==null) {
				return (false);
			}//if			
			var tempVal:*;
			//Note three different validation methods for the values below
			try {
				//1. Check for a valid, existing, non-empty string
				tempVal=infoObject.requestType;
				if ((tempVal=="") || (tempVal==null)) {
					return (false);
				}//if
				tempVal=infoObject.channelName;
				if ((tempVal=="") || (tempVal==null)) {
					return (false);
				}//if
				/*
				tempVal=infoObject.SCID;
				if ((tempVal=="") || (tempVal==null)) {
					return (false);
				}//if
				*/
				tempVal=infoObject.channelID;
				if ((tempVal=="") || (tempVal==null)) {
					return (false);
				}//if
				tempVal=infoObject.channelDescription;
				if ((tempVal=="") || (tempVal==null)) {
					return (false);
				}//if
				tempVal=infoObject.channelIcon;
				if ((tempVal=="") || (tempVal==null)) {
					return (false);
				}//if
				//2. Check to ensure it's a valid boolean value
				if (!(tempVal is Boolean)) {
					return (false);
				}//if
				//3. May be null but must exist (throw exception/return false otherwise).
				tempVal=infoObject.channelIconID;
				tempVal=infoObject.channelUnderlay;
				if ((tempVal=="") || (tempVal==null)) {
					return (false);
				}//if
				if (!(tempVal is Boolean)) {
					return (false);
				}//if
				tempVal=infoObject.channelOverlay;
				if ((tempVal=="") || (tempVal==null)) {
					return (false);
				}//if
				if (!(tempVal is Boolean)) {
					return (false);
				}//if
				tempVal=infoObject.channelOverlayID;
				tempVal=infoObject.videoBroadcast;
				if ((tempVal=="") || (tempVal==null)) {
					return (false);
				}//if
				if (!(tempVal is Boolean)) {
					return (false);
				}//if
				tempVal=infoObject.audioBroadcast;
				if ((tempVal=="") || (tempVal==null)) {
					return (false);
				}//if
				if (!(tempVal is Boolean)) {
					return (false);
				}//if
			} catch (e:*) {
				//One of the referenced values doesn't exist (undefined).
				return (false);				
			}//catch			
			//Everything passed
			return (true);			
		}//validateAVChannelData
		
		/** 
		 * @private 
		 */
		private function addChannelListeners():void {
			if (_channel!=null) {
				SwagDispatcher.addEventListener(SwagCloudEvent.BROADCAST, this.onChannelBroadcast, this, _channel);
				SwagDispatcher.addEventListener(SwagCloudEvent.DIRECT, this.onDirectChannelMessage, this, _channel);
				SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECT, this.onConnectChannel, this, _channel);
				SwagDispatcher.addEventListener(SwagCloudEvent.PEERDISCONNECT, this.onDisconnectPeer, this, _channel);
				SwagDispatcher.addEventListener(SwagCloudEvent.PEERCONNECT, this.onConnectPeer, this, _channel);
				SwagDispatcher.addEventListener(SwagCloudEvent.GROUPDISCONNECT, this.onDisconnectAnnounceChannel, this, _channel);
				SwagDispatcher.addEventListener(SwagCloudEvent.DISCONNECT, this.onDisconnectAnnounceChannel, this, _channel);
				SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECTFAIL, this.onFailConnectAVChannel, this, _channel);
				SwagDispatcher.addEventListener(SwagCloudEvent.GROUPREJECT, this.onFailConnectAVChannel, this, _channel);
			}//if
		}//addChannelListeners
		
		/** 
		 * @private 
		 */
		private function removeChannelListeners():void {
			if (_channel!=null) {
				SwagDispatcher.removeEventListener(SwagCloudEvent.BROADCAST, this.onChannelBroadcast, _channel);
				SwagDispatcher.removeEventListener(SwagCloudEvent.DIRECT, this.onDirectChannelMessage, _channel);
				SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onConnectChannel, _channel);
				SwagDispatcher.removeEventListener(SwagCloudEvent.PEERDISCONNECT, this.onDisconnectPeer, _channel);
				SwagDispatcher.removeEventListener(SwagCloudEvent.PEERCONNECT, this.onConnectPeer, _channel);
				SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPDISCONNECT, this.onDisconnectAnnounceChannel, _channel);
				SwagDispatcher.removeEventListener(SwagCloudEvent.DISCONNECT, this.onDisconnectAnnounceChannel, _channel);
				SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECTFAIL, this.onFailConnectAVChannel, _channel);
				SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPREJECT, this.onFailConnectAVChannel, _channel);
			}//if
		}//removeChannelListeners
		
		/** 
		 * @private 
		 */
		private function connectChannel():void {
			if (this.connected || this.connecting) {			
				return;
			}//if
			if (_channel==null) {
				_channel=new SwagCloud();						
			}//if			
			this.removeChannelListeners();
			this.addChannelListeners();
			if ((!_channel.groupConnected) && (!_channel.groupConnecting)) {
				References.debug("AnnounceChannel: Connecting...");			
				_channelConnecting=true;
				_channel.connectGroup(_announceChannelName, true, _channelPassword, _channelHash, false);
			}//if
		}//connectChannel
		
	}//AnnounceChannel class
	
}//package