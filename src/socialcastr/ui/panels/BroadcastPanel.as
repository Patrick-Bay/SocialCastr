package socialcastr.ui.panels {	
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.Video;
	import flash.net.NetStream;
	import flash.net.NetStreamAppendBytesAction;
	import flash.utils.ByteArray;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.core.AnnounceChannel;
	import socialcastr.core.Timeline;
	import socialcastr.core.TimelineElement;
	import socialcastr.core.timeline.SimpleVideoFadeEffect;
	import socialcastr.core.timeline.TimelineInvokeConstants;
	import socialcastr.events.AnnounceChannelEvent;
	import socialcastr.events.MovieClipButtonEvent;
	import socialcastr.events.TimelineEvent;
	import socialcastr.interfaces.ui.IPanel;
	import socialcastr.ui.Panel;
	import socialcastr.ui.PanelContent;
	import socialcastr.ui.panels.BroadcastSetupPanel;
	import socialcastr.ui.components.RadioTowerIcon;
	import socialcastr.ui.components.Tooltip;
	import socialcastr.ui.components.VideoDisplayComponent;
	import socialcastr.ui.input.MovieClipButton;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.core.instances.SwagLoader;
	import swag.events.SwagCloudEvent;
	import swag.events.SwagLoaderEvent;
	import swag.network.SwagCloud;
	
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
	public class BroadcastPanel extends PanelContent {
		
		private static var _broadcastPanels:Vector.<BroadcastPanel>=new Vector.<BroadcastPanel>();
		private static var _currentPanel:BroadcastPanel=null;
		
		public const group_prefix="SocialCastr.AV:";
		
		public var broadcastButton:MovieClipButton;
		public var audioBroadcastButton:MovieClipButton;
		public var connectBroadcastsButton:MovieClipButton;
		public var clickHerePrompt:MovieClip;
		public var radioTowerIcon1:RadioTowerIcon;
		public var radioTowerIcon2:RadioTowerIcon;		
		
		private var _localVideo:VideoDisplayComponent=null;
		private var _videoBroadcastActive:Boolean=false;
		private var _audioBroadcastActive:Boolean=false;
		private var _announceChannelOnConnect:Boolean=false;
		private var _broadcastsLinked:Boolean=false;
		private var _liveTimeline:Timeline=null;
		
		private var _mediaBroadcast:SwagCloud=null;
		private var _connectionPayloads:Vector.<XML>=new Vector.<XML>();
		private var _announce:SwagCloud=null;
		
		private var _testFadeEffect:SimpleVideoFadeEffect;
		
		public function BroadcastPanel(parentPanelRef:Panel) {
			_broadcastPanels.push(this);
			super(parentPanelRef);
		}//constructor
		
		public function onTimelineEvent(eventObj:TimelineEvent):void {
			References.debug("onTimelineEvent: "+eventObj.invoke);
			if (this.isStreamStartInvocation(eventObj)) {
				this.createGroupConnection(eventObj);
			}//if
			if (eventObj.invoke==TimelineInvokeConstants.VIDEO_STOP_RECSTREAM) {
				this.onVideoStreamEnd();
			}//if
		}//onTimelineEvent
		
		private function isStreamStartInvocation(eventObj:TimelineEvent):Boolean {
			if (eventObj==null) {
				return (false);
			}//if
			if ((eventObj.invoke=="") || (eventObj.invoke==null)) {
				return (false);
			}//if
			if (eventObj.invoke==TimelineInvokeConstants.VIDEO_START_LIVESTREAM) {
				return (true);
			}//if
			if (eventObj.invoke==TimelineInvokeConstants.VIDEO_START_RECSTREAM) {
				return (true);
			}//if
			if (eventObj.invoke==TimelineInvokeConstants.AUDIO_START_LIVESTREAM) {
				return (true);
			}//if
			if (eventObj.invoke==TimelineInvokeConstants.AUDIO_START_RECSTREAM) {
				return (true);
			}//if
			return (false);
		}//isStreamStartInvocation
		
		public function onBroadcastClick(eventObj:MovieClipButtonEvent):void {	
			var notificationMessage:String=this.getBroadcastSettingsNotification();
			if (notificationMessage!="") {			
				References.panelManager.togglePanel("channel_setup", true);
				var panelRef:IPanel=References.panelManager.togglePanel("notification", false);
				PanelContent(panelRef.content).updateMessageText(notificationMessage);
				return;
			}//if
			this._videoBroadcastActive=true;
			//First timeline element typically invokes createGroupConnection
			this._liveTimeline=this.broadcastBootstrapTimeline;			
			this._liveTimeline.start();
			this.broadcastButton.lockState("enabled", MovieClipButtonEvent.ONCLICK, "disable");
			this.updatePromptText();
			/*
			if (Camera.isSupported) {
				this._videoBroadcastActive=true;		
				if (!this.mediaBroadcast.groupConnected) {					
					var groupName:String=Settings.getPanelDataByID("channel_setup", "channelName", String);
					var groupPassword:String=Settings.getPanelDataByID("channel_setup", "channelPassword", String);
					groupName=group_prefix+groupName;
					References.debug("BroadcastPanel: Establishing group connection \""+groupName+"\" for stream(s).");
					SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECT, this.startLiveVideoStream, this, this.mediaBroadcast);
					this.mediaBroadcast.connectGroup(groupName, false, groupPassword);
				} else {
					this.startLiveVideoStream();
				}//else
				this.broadcastButton.lockState("enabled", MovieClipButtonEvent.ONCLICK, "disable");
				this.updatePromptText();
			}//if
			*/
		}//onBroadcastClick
		
		public function onAudioBroadcastClick(... args):void {	
			var notificationMessage:String=this.getBroadcastSettingsNotification();
			if (notificationMessage!="") {	
				References.panelManager.togglePanel("channel_setup", true);
				var panelRef:IPanel=References.panelManager.togglePanel("notification", false);
				PanelContent(panelRef.content).updateMessageText(notificationMessage);
				return;
			}//if
			if (this._audioBroadcastActive) {
				return;
			}//if
			this._audioBroadcastActive=true;
			//this.createGroupConnection();
			this.audioBroadcastButton.lockState("enabled", MovieClipButtonEvent.ONCLICK, "disable");
			this.updatePromptText();
			/*
			if (!this.mediaBroadcast.groupConnected) {
				var groupName:String=Settings.getPanelDataByID("channel_setup", "channelName", String);
				var groupPassword:String=Settings.getPanelDataByID("channel_setup", "channelPassword", String);
				groupName=group_prefix+groupName;
				References.debug("BroadcastPanel: Establishing group connection \""+groupName+"\" for stream(s).");
				SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECT, this.onAudioConnectionEstablished, this, this.mediaBroadcast);
				this.mediaBroadcast.connectGroup(groupName, false, groupPassword);
			} else {
				this.onAudioConnectionEstablished();
			}//else
			this.audioBroadcastButton.lockState("enabled", MovieClipButtonEvent.ONCLICK, "disable");
			this.updatePromptText();
			*/					
		}//onAudioBroadcastClick
		
		public function createGroupConnection(eventObj:TimelineEvent):void {			
			//TODO: update connection payloads to match with individual media broadcasts
			this._connectionPayloads[0]=new XML(eventObj.payload.toXMLString());
			try {
				var channelNode:XML=eventObj.payload[0] as XML;
				//TODO: update to support multiple media broadcasts
				if (!this.mediaBroadcast.groupConnected) {
					//var groupName:String=Settings.getPanelDataByID("channel_setup", "channelName", String);
					var groupName:String=channelNode.id[0].toString();					
					//Group password isn't currently used so the following setting is always null.
					var groupPassword:String=Settings.getPanelDataByID("channel_setup", "channelPassword", String);					
					groupName=group_prefix+groupName;					
					References.debug("BroadcastPanel: Establishing group connection \""+groupName+"\" for stream(s).");
					SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECT, this.onGroupConnectionEstablished, this, this.mediaBroadcast);
					this.mediaBroadcast.connectGroup(groupName, false, groupPassword);				
				} else {
					this.onGroupConnectionEstablished();
				}//else
			} catch (e:*) {
			}//catch
		}//createGroupConnection
		
		public function onGroupConnectionEstablished(eventObj:SwagCloudEvent=null):void {
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onGroupConnectionEstablished, this.mediaBroadcast);			
			var sourceNode:XML=this._connectionPayloads[0].source[0] as XML;
			this._liveTimeline.stop();
			References.debug("BroadcastPanel: *** Group Connection Established ***");
			References.debug("BroadcastPanel:    Rendezvous @ "+SwagCloud(eventObj.source).serverAddress);
			References.debug("BroadcastPanel:    NetStatusEvent status code = "+eventObj.statusCode);
			References.debug("BroadcastPanel: ******************");
			if (sourceNode.@type=="file") {
				this.startFileVideoStream(eventObj);
			} else if (sourceNode.@type=="camera") {
				this.startLiveVideoStream(eventObj);
			} else {
				References.debug("BroadcastPanel: Unrecognized bootstrap source type (\""+sourceNode.@type+"\") in connection payload.");
			}//else
		}//onGroupConnectionEstablished
		
		public function startFileVideoStream(eventObj:SwagCloudEvent=null):void {			
			if (!this._videoBroadcastActive) {
				return;
			}//if
			this.onConnectBroadcastsClick(null);
			this._localVideo=this.createDefaultVideoView();			
			this._liveTimeline.beacon=this._localVideo;
			this._testFadeEffect=new SimpleVideoFadeEffect(this._localVideo);
			if (this._localVideo!=null) {
				this._announceChannelOnConnect=true;
				this.addChild(this._localVideo);
				var sourceNode:XML=this._connectionPayloads[0].source[0] as XML;
				var videoFileURL:String=sourceNode.children().toString();				
				this._localVideo.createDisplay(false);
				//TODO: Break out file loading functionality to support huge files (read in chunks)
				var fileLoader:SwagLoader=new SwagLoader(videoFileURL);		
				SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, this.onLoadStreamFile, this, fileLoader);
				fileLoader.load(null, ByteArray);
			}  else {
				References.debug("BroadcastPanel: Couldn't create default local camera view!");
			}//else
		}//startFileVideoStream		
		
		public function onLoadStreamFile(eventObj:SwagLoaderEvent):void {			
			this.mediaBroadcast.distribute(eventObj.source.loadedData);
			var streamConnection:NetStream=this._localVideo.attachLocalStream();
			streamConnection.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onLoadStreamFile, eventObj.source);
			streamConnection.appendBytes(eventObj.source.loadedData);
			this.radioTowerIcon2.enable();
			var tip:Tooltip=Tooltip.getTipFor(this.broadcastButton);
			if (tip!=null) {
				if (this._broadcastsLinked) {
					tip.text="Broadcasting audio and video! Click to stop";
				} else {
					tip.text="Broadcasting video! Click to stop";
				}//else
			}//if
			tip=Tooltip.getTipFor(this.radioTowerIcon2);
			if (tip!=null) {
				tip.text="Video broadcast is LIVE!";
			}//if
			this.setChildIndex(this._localVideo, 1); //under all UI elements
			if (this._broadcastsLinked) {
				this.onAudioBroadcastClick();
			}//if	
			this.onVideoStreamActive(null);			
			this._liveTimeline.start();
		}//onLoadStreamFile
		
		public function startLiveVideoStream(eventObj:SwagCloudEvent=null):void {
			if (!this._videoBroadcastActive) {
				return;
			}//if
			if (eventObj==null) {
				References.debug("BroadcastPanel: *** Mixing video stream with existing audio stream  ***");
			}//if
			this._localVideo=this.createDefaultVideoView();
			this._liveTimeline.beacon=this._localVideo;
			this._testFadeEffect=new SimpleVideoFadeEffect(this._localVideo);
			if (this._localVideo!=null) {
				if (!this._audioBroadcastActive) {
					this._announceChannelOnConnect=true;
				}//if
				this.addChild(this._localVideo);
				var sourceNode:XML=this._connectionPayloads[0].source[0] as XML;
				var cameraID:String=sourceNode.children().toString();
				if ((cameraID=="") || (cameraID==null)) {
					cameraID=Settings.getBroadcastSetting("cam0");
				}//if		
				if ((cameraID!=null) && (cameraID!="")) {
					this._localVideo.localCamera=Camera.getCamera(cameraID);
				} else {
					this._localVideo.localCamera=Camera.getCamera(); //Use the default one
				}//else				
				References.debug("BroadcastPanel: Attaching camera to outbound stream...");				
				var streamName:String=Settings.getPanelDataByID("channel_setup", "channelName", String);
				streamName=this.group_prefix+streamName;
				SwagDispatcher.removeEventListener(SwagCloudEvent.STREAMOPEN, this.onVideoStreamActive, this.mediaBroadcast);
				SwagDispatcher.addEventListener(SwagCloudEvent.STREAMOPEN, this.onVideoStreamActive, this, this.mediaBroadcast);
				this.mediaBroadcast.createMediaStream(streamName);
				References.debug("BroadcastPanel: Creating local camera display area...");
				var ns:NetStream=this.mediaBroadcast.streamCamera(this._localVideo.localCamera);	
				var reliableSetting:String=Settings.getBroadcastSetting("losslessVideo");				
				if (reliableSetting=="true") {
					References.debug("BroadcastPanel: Video stream in reliable mode.");
					ns.videoReliable=true;
				} else {
					References.debug("BroadcastPanel: Video stream in standard mode.");
					ns.videoReliable=false;
				}//else				
				this._localVideo.createDisplay();
				var videoDims:String=Settings.getBroadcastSetting("camres0");
				var fpsSetting:String=Settings.getBroadcastSetting("camfps0");
				if (fpsSetting!=null) {
					var fps:Number=new Number(fpsSetting);
				} else {
					fps=18;
				}//else
				if (videoDims==null) {
					var videoWidth:int=int(this._localVideo.width);
					var videoHeight:int=int(this._localVideo.height);
				} else {
					var dimsSplit:Array=videoDims.split("x");
					videoWidth=int(dimsSplit[0]);
					videoHeight=int(dimsSplit[1]);
				}//else			
				References.debug ("BroadcastPanel: Setting video mode to "+String(videoWidth)+"x"+String(videoHeight)+" @"+fps+" fps");				
				this._localVideo.localCamera.setMode(videoWidth, videoHeight, fps, true);
				this._localVideo.localCamera.setLoopback(false); //Settings!
				this._localVideo.localCamera.setQuality(BroadcastSetupPanel.broadcastBitRate, BroadcastSetupPanel.broadcastQuality);
				this.radioTowerIcon2.enable();
				var tip:Tooltip=Tooltip.getTipFor(this.broadcastButton);
				if (tip!=null) {
					if (this._broadcastsLinked) {
						tip.text="Broadcasting audio and video! Click to stop";
					} else {
						tip.text="Broadcasting video! Click to stop";
					}//else
				}//if
				tip=Tooltip.getTipFor(this.radioTowerIcon2);
				if (tip!=null) {
					tip.text="Video broadcast is LIVE!";
				}//if
				this.setChildIndex(this._localVideo, 1); //under all UI elements
			} else {
				References.debug("BroadcastPanel: Couldn't create default local camera view!");
			}//else			
			if (!this.mediaBroadcast.mediaStreamPublished) {
				streamName=Settings.getPanelDataByID("channel_setup", "channelName", String);
				streamName=this.group_prefix+streamName;
				References.debug("BroadcastPanel: Publishing media stream \""+streamName+"\"...");
				this.mediaBroadcast.createMediaStream(streamName);
			}//if			
			if (this._broadcastsLinked) {
				this.onAudioBroadcastClick();
			}//if			
		}//startLiveVideoStream
		
		public function onAudioConnectionEstablished(eventObj:SwagCloudEvent=null):void {
			if (!this._audioBroadcastActive) {
				return;
			}//if
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onAudioConnectionEstablished, this.mediaBroadcast);
			if (eventObj==null) {
				References.debug("BroadcastPanel: *** Mixing audio stream with existing video stream ***");
			} else {
				References.debug("BroadcastPanel: *** Group Connection Established ***");
				References.debug("BroadcastPanel:    Rendezvous @ "+SwagCloud(eventObj.source).serverAddress);
				References.debug("BroadcastPanel:    NetStatusEvent status code = "+eventObj.statusCode);
				References.debug("BroadcastPanel: ******************");
			}//else
			if (!this.mediaBroadcast.mediaStreamPublished) {
				var streamName:String=Settings.getPanelDataByID("channel_setup", "channelName", String);
				streamName=this.group_prefix+streamName;
				References.debug("BroadcastPanel: Publishing media stream \""+streamName+"\"...");
				this.mediaBroadcast.createMediaStream(streamName);
			}//if
			if (!this.mediaBroadcast.mediaStreamPublished) {
				References.debug("BroadcastPanel: Couldn't publish media stream!");
				return;
			}//if
			if (!this._videoBroadcastActive) {
				this._announceChannelOnConnect=true;
			}//if
			var microphoneID:String=Settings.getBroadcastSetting("mic0");
			if ((microphoneID!=null) && (microphoneID!="")) {
				var microphone:Microphone=Microphone.getMicrophone(int(microphoneID));
			} else {
				microphone=Microphone.getMicrophone(0);
			}//else
			References.debug("BroadcastPanel: Streaming microphone...");
			SwagDispatcher.removeEventListener(SwagCloudEvent.STREAMOPEN, this.onAudioStreamActive, this.mediaBroadcast);
			SwagDispatcher.addEventListener(SwagCloudEvent.STREAMOPEN, this.onAudioStreamActive, this, this.mediaBroadcast);
			var stream:NetStream=this.mediaBroadcast.streamMicrophone(microphone);
			var reliableSetting:String=Settings.getBroadcastSetting("losslessAudio");
			if (reliableSetting=="true") {
				References.debug("BroadcastPanel: Audio stream in reliable mode.");
				stream.audioReliable=true;
			} else {
				References.debug("BroadcastPanel: Audio stream in standard mode.");
				stream.audioReliable=false;
			}//else
			this.radioTowerIcon1.enable();
			var tip:Tooltip=Tooltip.getTipFor(this.audioBroadcastButton);
			if (tip!=null) {
				tip.text="Broadcasting audio! Click to stop";
			}//if
			tip=Tooltip.getTipFor(this.radioTowerIcon1);
			if (tip!=null) {
				tip.text="Audio broadcast is LIVE!";
			}//if
		}//onAudioConnectionEstablished
		
		public function onVideoStreamActive(eventObj:SwagCloudEvent) {
			if (eventObj!=null) {
				SwagDispatcher.removeEventListener(SwagCloudEvent.STREAMOPEN, this.onVideoStreamActive, eventObj.source);
				References.debug("BroadcastPanel:   Live video stream \""+eventObj.streamID+"\" established...");
			} else {
				References.debug ("BroadcastPanel:    Distributed video stream established...");
			}//else			
			if (this._announceChannelOnConnect) {
				this._announceChannelOnConnect=false;
				this.announceChannelBroadcast();
			}//if
		}//onVideoStreamActive
		
		/**
		 * Invoked when a recorded video stream has completed (typically by the associated timeline via
		 * the <code>onTimelineEvent</code> method).
		 */
		public function onVideoStreamEnd():void {
			References.debug("BroadcastPanel.onVideoStreamEnd();");
			var loopSetting:String=Settings.getBroadcastSetting("loopVideoOnEnd");
			if (loopSetting=="true") {		
				var sourceNode:XML=this._connectionPayloads[0].source[0] as XML;
				var videoFileURL:String=sourceNode.children().toString();
				var fileLoader:SwagLoader=new SwagLoader(videoFileURL);		
				SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, this.onLoadStreamFile, this, fileLoader);
				fileLoader.load(null, ByteArray);this._localVideo.play();
			} else {
				this.onBroadcastDisable(null);
			}//else
		}//onVideoStreamEnd
		
		public function onAudioStreamActive(eventObj:SwagCloudEvent) {
			if (eventObj!=null) {
				SwagDispatcher.removeEventListener(SwagCloudEvent.STREAMOPEN, this.onAudioStreamActive, eventObj.source);
				References.debug("BroadcastPanel:    Audio stream \""+eventObj.streamID+"\" established.");
			} else {
				References.debug ("BroadcastPanel:    Distributed audio stream established.");
			}//else
			if (this._announceChannelOnConnect) {
				this._announceChannelOnConnect=false;
				this.announceChannelBroadcast();
			}//if
		}//onAudioStreamActive
		
		public function clearChannelBroadcastAnnounce():void {
			AnnounceChannel.stopAnnounceAVChannel();
		}//clearChannelBroadcastAnnounce
		
		/**
		 * Announces that the broadcast is active to the main Announce group.
		 */
		public function announceChannelBroadcast():void {			
			if (References.announceChannel==null) {
				return;
			}//if
			References.debug("BroadcastPanel: Announcing channel globally.");
			var iconFileName:String=Settings.getPanelDataByID("channel_setup", "iconImage", String);
			var underlayImageName:String=Settings.getPanelDataByID("channel_setup", "backgroundImage", String);
			var overlayImageName:String=Settings.getPanelDataByID("channel_setup", "foregroundImage", String);
			References.debug("BroadcastPanel: Attempting global share of channel icon.");			
			if ((iconFileName!=null) && (iconFileName!="")) {
				Settings.loadPanelDataFile("channel_setup", iconFileName, this.onChannelIconShared);
			} else {
				this.onChannelIconShared();
			}//else
			References.debug("BroadcastPanel: Attempting global share of channel underlay image.");
			if ((underlayImageName!=null) && (underlayImageName!="")) {
				Settings.loadPanelDataFile("channel_setup", underlayImageName, this.startChannelUnderlayShare);
			} else {
				References.debug("BroadcastPanel:    Couldn't start underlay image share because no file was specified.");
			}//else
			References.debug("BroadcastPanel: Attempting global share of channel overlay image.");
			if ((overlayImageName!=null) && (overlayImageName!="")) {
				Settings.loadPanelDataFile("channel_setup", overlayImageName, this.startChannelOverlayShare);
			} else {
				References.debug("BroadcastPanel: Couldn't start overlay image share because no file was specified.");
			}//else
		}//announceChannelBroadcast		
		
		/**
		 * Announces that the broadcast is fully disconnecting (no audio, no video), to the Announce group.
		 */
		public function announceChannelDisconnect():void {
			if (References.announceChannel==null) {
				return;
			}//if
			References.debug("BroadcastPanel: Announcing channel disconnect globally.");
			References.announceChannel.announceCloseAVChannel(this);
		}//announceChannelDisconnect
		
		public function onChannelIconShared(eventObj:SwagLoaderEvent=null):void {
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onChannelIconShared);
			if (this._liveTimeline==null) {
				References.debug("         Live timeline was about to be reset. Not good. Not good.");
				//this._liveTimeline=this.startBroadcastTimeline;
			}//if
			if (eventObj==null) {
				References.debug("BroadcastPanel: No channel icon to share.");
				this.shareLiveTimeline();
				return;
			}//if			
			var fileData:ByteArray=eventObj.source.loadedData as ByteArray;
			var channelID:String=Settings.getPanelDataByID("channel_setup", "channelName", String);			
			if ((channelID!=null) && (channelID!="")) {
				var iconShareName:String=Settings.getPanelDataByID("channel_setup", "iconImage", String);
				References.debug("BroadcastPanel: Sharing channel icon as \""+iconShareName+"\".");
				References.announceChannel.beginSharing(channelID, iconShareName, fileData, 65535);				
			} else {
				References.debug("BroadcastPanel: Couldn't share the channel icon because the channel ID is not available!");
			}//else			
			this.shareLiveTimeline();
		}//onChannelIconShared
		
		private function shareLiveTimeline():void {
			References.debug("BroadcastPanel: Attempting to create Live Timeline channel...");
			SwagDispatcher.addEventListener(AnnounceChannelEvent.ONLIVETIMELINEREG, this.onShareLiveTimeline, this, References.announceChannel);
			SwagDispatcher.addEventListener(AnnounceChannelEvent.ONLIVETIMELINEREGFAIL, this.onShareLiveTimelineFail, this, References.announceChannel);			
			this.prepLiveTimelineBroadcast();	
			References.announceChannel.registerLiveTimelineChannel(this._liveTimeline);
		}//shareLiveTimeline
		
		public function onShareLiveTimeline(eventObj:AnnounceChannelEvent):void {
			References.debug("BroadcastPanel: ...Live Timeline channel successfully opened.");
			SwagDispatcher.removeEventListener(AnnounceChannelEvent.ONLIVETIMELINEREG, this.onShareLiveTimeline, References.announceChannel);
			SwagDispatcher.removeEventListener(AnnounceChannelEvent.ONLIVETIMELINEREGFAIL, this.onShareLiveTimelineFail, References.announceChannel);			
			References.announceChannel.announceNewAVChannel(this,null,true);
		}//onShareLiveTimeline
		
		public function onShareLiveTimelineFail(eventObj:AnnounceChannelEvent):void {
			References.debug("BroadcastPanel: ...Live Timeline channel couldn't be opened (probably already exists)!");
			SwagDispatcher.removeEventListener(AnnounceChannelEvent.ONLIVETIMELINEREG, this.onShareLiveTimeline, References.announceChannel);
			SwagDispatcher.removeEventListener(AnnounceChannelEvent.ONLIVETIMELINEREGFAIL, this.onShareLiveTimelineFail, References.announceChannel);
			//TODO: Do we really want to announce a new AV channel if the timeline connection fails?
			References.announceChannel.announceNewAVChannel(this,null,true);
		}//onShareLiveTimelineFail
		
		/**
		 * Prepares the current Live Timeline for broadcast to external sources by stripping out or updating any
		 * data (nodes, attributes, etc.) used only internally. This is done both for security reasons as well
		 * as to compact the data prior to broadcasting it.
		 * 
		 * @private 		 
		 */
		private function prepLiveTimelineBroadcast():void {
			if (this._liveTimeline==null) {
				return;
			}//if
			var timelineElements:Vector.<TimelineElement>=this._liveTimeline.elements;
			for (var count:uint=0; count<timelineElements.length; count++) {
				var currentElement:TimelineElement=timelineElements[count] as TimelineElement;
				var elementXML:XML=currentElement.elementData;
				//Remove any <source> nodes
				var sourceNodes:XMLList=elementXML.descendants("source");
				for (var count2:uint=0; count2<sourceNodes.length(); count2++) {
					delete sourceNodes[count2];					
				}//for								
			}//for
		}//prepLiveTimelineBroadcast
		
		private function get broadcastBootstrapTimeline():Timeline {			
			var returnTimeline:Timeline=new Timeline(null);
			var payload:XML=new XML("<channel SCID=\"\" CCID=\"\"><id /><description /><source /></channel>");
			payload.@SCID=Settings.getSCID();
			payload.@CCID=Settings.getCCID();
			var channelID:String=Settings.getPanelDataByID("channel_setup", "channelName", String);	
			var channelDesc:String=Settings.getPanelDataByID("channel_setup", "channelDescription", String);
			payload.id[0].appendChild(new XML("<![CDATA["+channelID+"]]>"));
			payload.description[0].appendChild(new XML("<![CDATA["+channelDesc+"]]>"));
			var primarySource:String=Settings.getBroadcastSetting("cam0");
			var sourceFile:String=Settings.getBroadcastSetting("streamfile");
			if (primarySource=="_file_") {
				payload.source.@type="file";
				payload.source.appendChild(sourceFile);
				returnTimeline.broadcastElement(TimelineElement.create(TimelineInvokeConstants.VIDEO_START_RECSTREAM, "00:00:00:00", "", "high", payload, true), false);
			} else {
				payload.source.@type="camera";
				payload.source.appendChild(primarySource);
				returnTimeline.broadcastElement(TimelineElement.create(TimelineInvokeConstants.VIDEO_START_LIVESTREAM, "00:00:00:00", "", "high", payload, true), false);
			}//else
			returnTimeline.incorporateElements(Settings.liveTimelineXML);
			return (returnTimeline);
		}//get broadcastBootstrapTimeline
		
		private function get startBroadcastTimeline():Timeline {
			var returnTimeline:Timeline=new Timeline(this._localVideo);
			var payload:XML=new XML("<channel SCID=\"\" CCID=\"\"><id /><description /></channel>");
			payload.@SCID=Settings.getSCID();
			payload.@CCID=Settings.getCCID();
			var channelID:String=Settings.getPanelDataByID("channel_setup", "channelName", String);	
			var channelDesc:String=Settings.getPanelDataByID("channel_setup", "channelDescription", String);
			payload.id[0].appendChild(new XML("<![CDATA["+channelID+"]]>"));
			payload.description[0].appendChild(new XML("<![CDATA["+channelDesc+"]]>"));
			if (this._videoBroadcastActive) {
				returnTimeline.addElement(TimelineElement.create(TimelineInvokeConstants.VIDEO_START_LIVESTREAM, "00:00:00:00", "", "high", payload));
			}//if
			if (this._audioBroadcastActive) {
				returnTimeline.addElement(TimelineElement.create(TimelineInvokeConstants.AUDIO_START_LIVESTREAM, "00:00:00:00", "", "high", payload));
			}//if
			//Append pre-recorded effects here
			return (returnTimeline);
		}//get startBroadcastTimeline
		
		public function startChannelUnderlayShare(eventObj:SwagLoaderEvent):void {
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.startChannelUnderlayShare, eventObj.source);
			var fileData:ByteArray=eventObj.source.loadedData as ByteArray;
			var channelID:String=Settings.getPanelDataByID("channel_setup", "channelName", String);			
			if ((channelID!=null) && (channelID!="")) {
				var underlayImageName:String=Settings.getPanelDataByID("channel_setup", "backgroundImage", String);
				References.debug("BroadcastPanel: Sharing underlay image as \""+underlayImageName+"\".");
				References.announceChannel.beginSharing(channelID, underlayImageName, fileData, 65535);
			} else {
				References.debug("BroadcastPanel: Couldn't share the underlay image because the channel ID is not available!");
			}//else			
		}//startChannelUnderlayShare
		
		public function startChannelOverlayShare(eventObj:SwagLoaderEvent):void {
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.startChannelOverlayShare, eventObj.source);
			var fileData:ByteArray=eventObj.source.loadedData as ByteArray;
			var channelID:String=Settings.getPanelDataByID("channel_setup", "channelName", String);			
			if ((channelID!=null) && (channelID!="")) {
				var overlayImageName:String=Settings.getPanelDataByID("channel_setup", "foregroundImage", String);
				References.debug("BroadcastPanel: Sharing overlay image as \""+overlayImageName+"\".");
				References.announceChannel.beginSharing(channelID, overlayImageName, fileData, 65535);
			} else {
				References.debug("BroadcastPanel: Couldn't share the overlay image because the channel ID is not available!");
			}//else			
		}//startChannelOverlayShare
		
		public function onConnectBroadcasts(eventObj:MovieClipButtonEvent):void {
			if (this._videoBroadcastActive) {
				this.onAudioBroadcastClick();
			}//if
		}//onConnectBroadcasts		
		
		public function onBroadcastDisable(eventObj:MovieClipButtonEvent):void {
			if (this.mediaBroadcast.stopCameraStream()) {				
				References.debug("BroadcastPanel: ...video stream terminated.");
				var tip:Tooltip=Tooltip.getTipFor(this.radioTowerIcon2);				
				if (tip!=null) {
					tip.text="Video broadcast disabled";
				}//if
				tip=Tooltip.getTipFor(this.broadcastButton);
				if (this._broadcastsLinked) {					
					tip.text="Click to start video and audio broadcast";
				} else {
					tip.text="Click to start video broadcast";
				}//else
				this.radioTowerIcon2.disable();
				if (this._localVideo!=null) {
					this._localVideo.destroy();
					this.removeChild(this._localVideo);
					this._localVideo=null;
				}//if
				this._videoBroadcastActive=false;
				if (!this._audioBroadcastActive) {					
					References.debug("BroadcastPanel: Disconnecting broadcast group...");
					this.announceChannelDisconnect();
					SwagDispatcher.addEventListener(SwagCloudEvent.GROUPDISCONNECT, this.closeGroupConnection, this, this.mediaBroadcast);
					this.mediaBroadcast.disconnectGroup();					
				}//if					
			} else {
				References.debug("BroadcastPanel: Video broadcast couldn't be stopped!");
			}//else
			if (this._broadcastsLinked) {
				this.disableAudioBroadcast();
			}//if
		}//onBroadcastDisable
		
		public function closeGroupConnection(eventObj:SwagCloudEvent):void {
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPDISCONNECT, this.closeGroupConnection, this.mediaBroadcast);
			References.debug("BroadcastPanel: ...broadcast group disconnected.");
			if (this._localVideo!=null) {
				this._localVideo.destroy();
				this.removeChild(this._localVideo);
				this._localVideo=null;
			}//if
			SwagDispatcher.addEventListener(SwagCloudEvent.DISCONNECT, this.closeVideoConnection, this, this._mediaBroadcast);
			References.debug("BroadcastPanel: Terminating connection...");
			this.mediaBroadcast.disconnect();	
		}//closeGroupConnection
		
		public function closeVideoConnection(eventObj:SwagCloudEvent):void {
			//Don't use this.mediaBroadcast at this point -- the object should be fully destroyed in this method!
			this._mediaBroadcast=null;
			References.debug("BroadcastPanel: Connection terminated.");
			SwagDispatcher.removeEventListener(SwagCloudEvent.DISCONNECT, this.closeVideoConnection, this._mediaBroadcast);
			var tip:Tooltip=Tooltip.getTipFor(this.radioTowerIcon2);
			if (tip!=null) {
				tip.text="Video broadcast disabled";
			}//if
			this.radioTowerIcon2.disable();
			this.updatePromptText();	
		}//closeVideoConnection
		
		public function onAudioBroadcastDisable(eventObj:MovieClipButtonEvent):void {							
			if (this.mediaBroadcast.stopMicrophoneStream()) {
				this._audioBroadcastActive=false;
				References.debug("BroadcastPanel: ...audio stream terminated.");
				var tip:Tooltip=Tooltip.getTipFor(this.radioTowerIcon1);
				if (tip!=null) {					
					tip.text="Audio broadcast disabled";					
				}//if
				tip=Tooltip.getTipFor(this.audioBroadcastButton);
				tip.text="Click to start audio broadcast";
				if (!this._videoBroadcastActive) {
					SwagDispatcher.addEventListener(SwagCloudEvent.GROUPDISCONNECT, this.closeGroupConnection, this, this.mediaBroadcast);
					this.announceChannelDisconnect();
					this.mediaBroadcast.disconnectGroup();				
				}//if				
				this.radioTowerIcon1.disable();
				this.updatePromptText();
			} else {
				References.debug("BroadcastPanel: Audio broadcast couldn't be stopped!");
			}//else								
		}//onAudioBroadcastDisable
		
		public function disableAudioBroadcast():void {			
			if (this._audioBroadcastActive) {
				this.audioBroadcastButton.releaseState();	
			}//if			
		}//disableAudioBroadcast
	
		public function get mediaBroadcast():SwagCloud {
			if (this._mediaBroadcast==null) {
				References.debug("BroadcastPanel: <<< New Media Broadcast Connection Created >>>");
				this._mediaBroadcast=new SwagCloud();
				this._mediaBroadcast.gatherStrategy="streaming";								
			}//if
			return (this._mediaBroadcast);
		}//mediaBroadcast
		
		public function get videoBroadcastActive():Boolean {
			return (this._videoBroadcastActive);
		}//get videoBroadcastActive
		
		public function get audioBroadcastActive():Boolean {
			return (this._audioBroadcastActive);
		}//get audioBroadcastActive
		
		public function get liveTimeline():Timeline {
			if (this._liveTimeline==null) {
				this._liveTimeline=new Timeline(this._localVideo);
			}//if
			return (this._liveTimeline);
		}//get liveTimeLine
		
		public function get liveTimelineXML():XML {
			if (this.liveTimeline==null) {
				return (null);
			}//if
			return (this.liveTimeline.toXML());
		}//get liveTimelineXML
		
		public function onConnectBroadcastsClick(eventObj:MovieClipButtonEvent):void {
			this._broadcastsLinked=true;
			var tip:Tooltip=Tooltip.getTipFor(this.connectBroadcastsButton);
			if (tip!=null) {
				tip.text="Click to disconnect broadcast controls";
			}//if
			tip=Tooltip.getTipFor(this.broadcastButton);
			if (tip!=null) {
				if (this.videoBroadcastActive) {
					if (this._broadcastsLinked) {					
						tip.text="Broadcasting audio and video! Click to stop";
					} else {
						tip.text="Broadcasting video! Click to stop";
					}//else
				} else {
					if (this._broadcastsLinked) {					
						tip.text="Click to start video and audio broadcast";
					} else {
						tip.text="Click to start video broadcast";
					}//else
				}//else
			}//if
			this.connectBroadcastsButton.lockState("enable", MovieClipButtonEvent.ONCLICK, "disable");
		}//onConnectBroadcastsClick
		
		public function onDisconnectBroadcasts(eventObj:MovieClipButtonEvent):void {
			this._broadcastsLinked=false;
			var tip:Tooltip=Tooltip.getTipFor(this.connectBroadcastsButton);
			if (tip!=null) {
				tip.text="Click to connect broadcast controls";
			}//if
			tip=Tooltip.getTipFor(this.broadcastButton);
			if (tip!=null) {
				if (this.videoBroadcastActive) {
					if (this._broadcastsLinked) {					
						tip.text="Broadcasting audio and video! Click to stop";
					} else {
						tip.text="Broadcasting video! Click to stop";
					}//else
				} else {
					if (this._broadcastsLinked) {					
						tip.text="Click to start video and audio broadcast";
					} else {
						tip.text="Click to start video broadcast";
					}//else
				}//else
			}//if			
		}//onDisconnectBroadcasts
		
		public function createDefaultVideoView():VideoDisplayComponent {
			if (!SwagDataTools.isXML(this.panelData.displays)) {
				return (null);
			}//if
			var displaysNode:XML=this.panelData.displays[0] as XML;
			if (!SwagDataTools.isXML(displaysNode.local)) {
				return (null);
			}//if
			var defaultNode:XML=displaysNode.local[0] as XML;
			var newDisplayComponent:VideoDisplayComponent=new VideoDisplayComponent(defaultNode);
			return (newDisplayComponent);
		}//createDefaultVideoView
		
		public static function get allPanels():Vector.<BroadcastPanel> {
			return (_broadcastPanels);
		}//get allPannels
		
		public static function get currentPanel():BroadcastPanel {
			return (_currentPanel);
		}//get currentPanel
		
		private function getBroadcastSettingsNotification():String {			
			var notification:String=new String();
			var notifyType:uint=new uint();	
			var channelNameString:String=Settings.getPanelDataByID("channel_setup", "channelName", String);
			var channelDescString:String=Settings.getPanelDataByID("channel_setup", "channelDescription", String);
			if ((channelNameString==null) || (channelNameString=="")) {
				notifyType=SwagDataTools.setBit(notifyType, 1, true);				
			}//if
			if ((channelDescString==null) || (channelDescString=="")) {
				notifyType=SwagDataTools.setBit(notifyType, 2, true);
			}//if
			if (notifyType!=0) {
				notification="Set the ";
				if (SwagDataTools.getBit(notifyType, 1) && SwagDataTools.getBit(notifyType, 2)) {
					notification+="name and description";	
				} else if (SwagDataTools.getBit(notifyType, 2)) {
					notification+="description";
				} else if (SwagDataTools.getBit(notifyType, 1)) {
					notification+="name";	
				}//else if
				notification+=" in the Channel Setup panel.";
			}//if			
			return (notification);
		}//getBroadcastSettingsNotification
		
		private function updatePromptText():void {
			if (this.clickHerePrompt!=null) {
				if (this._videoBroadcastActive) {
					this.clickHerePrompt.gotoAndStop(2);
				} else {
					this.clickHerePrompt.gotoAndStop(1);
				}//else
			}//if
		}//updatePromptText
		
		private function addListeners():void {
			if (this.broadcastButton!=null) {
				var BBTooltip:Tooltip=new Tooltip(this.broadcastButton, "Click to start video broadcast");
				SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onBroadcastClick, this, this.broadcastButton);
				SwagDispatcher.addEventListener(MovieClipButtonEvent.ONUNLOCKSTATE, this.onBroadcastDisable, this, this.broadcastButton);				
			}//if
			if (this.onAudioBroadcastClick!=null) {
				var ABTooltip:Tooltip=new Tooltip(this.audioBroadcastButton, "Click to start audio broadcast");
				SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onAudioBroadcastClick, this, this.audioBroadcastButton);
				SwagDispatcher.addEventListener(MovieClipButtonEvent.ONUNLOCKSTATE, this.onAudioBroadcastDisable, this, this.audioBroadcastButton);
			}//if
			if (this.connectBroadcastsButton!=null) {
				var CBTooltip:Tooltip=new Tooltip(this.connectBroadcastsButton, "Click to connect broadcast controls");
				SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onConnectBroadcastsClick, this, this.connectBroadcastsButton);	
				SwagDispatcher.addEventListener(MovieClipButtonEvent.ONUNLOCKSTATE, this.onDisconnectBroadcasts, this, this.connectBroadcastsButton);
				SwagDispatcher.addEventListener(MovieClipButtonEvent.ONLOCKSTATE, this.onConnectBroadcasts, this, this.connectBroadcastsButton);
			}//if
			SwagDispatcher.addEventListener(TimelineEvent.INVOKE, this.onTimelineEvent, this);
		}//addListeners
		
		private function removeListeners():void {
			if (this.broadcastButton!=null) {
				SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onBroadcastClick, this.broadcastButton);
				SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONUNLOCKSTATE, this.onBroadcastDisable, this.broadcastButton);
			}//if
			if (this.onAudioBroadcastClick!=null) {
				SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onAudioBroadcastClick, this.audioBroadcastButton);
				SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONUNLOCKSTATE, this.onAudioBroadcastDisable, this.audioBroadcastButton);
			}//if
			if (this.connectBroadcastsButton!=null) {
				SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onConnectBroadcastsClick, this.connectBroadcastsButton);
				SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONUNLOCKSTATE, this.onDisconnectBroadcasts, this.connectBroadcastsButton);
				SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONLOCKSTATE, this.onConnectBroadcasts, this.connectBroadcastsButton);
			}//if
			SwagDispatcher.removeEventListener(TimelineEvent.INVOKE, this.onTimelineEvent, this);
		}//removeListeners
		
		
		override public function initialize():void {
			this._videoBroadcastActive=false;
			this.radioTowerIcon1.playback.gotoAndStop("off");
			this.radioTowerIcon2.playback.gotoAndStop("off");
			var RTI1Tooltip:Tooltip=new Tooltip(this.radioTowerIcon1, "Audio broadcast disabled");
			var RTI2Tooltip:Tooltip=new Tooltip(this.radioTowerIcon2, "Video broadcast disabled");
			this.updatePromptText();
			_currentPanel=this;
			this.addListeners();
		}//initialize		
		
	}//BroadcastPanel class
	
}//package