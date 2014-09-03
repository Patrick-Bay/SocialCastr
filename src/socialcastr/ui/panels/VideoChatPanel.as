package socialcastr.ui.panels {
	
	import flash.display.MovieClip;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.net.NetStream;
	import flash.utils.ByteArray;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.events.IDPanelEvent;
	import socialcastr.events.MovieClipButtonEvent;
	import socialcastr.events.PanelEvent;
	import socialcastr.events.TextInputEvent;
	import socialcastr.events.VideoChatConfirmEvent;
	import socialcastr.ui.Panel;
	import socialcastr.ui.PanelContent;
	import socialcastr.ui.components.Tooltip;
	import socialcastr.ui.input.MovieClipButton;
	import socialcastr.ui.input.TextInput;
	import socialcastr.ui.panels.VideoChatConfirmPanel;
	import socialcastr.ui.components.VideoDisplayComponent;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.instances.SwagMovieClip;
	import swag.events.SwagCloudEvent;
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
	public class VideoChatPanel extends PanelContent {
		
		private const defaultChatStreamName:String="SocialCastr_Group_Video_Chat:";
		
		/**
		 * Used to announce new connections to the group.
		 */
		private var _announceConnection:SwagCloud;
		/**
		 * Outbound webcam connection.  
		 */		
		private var _webcamConnection:SwagCloud;	
		private var _webcam:Camera;	
		
		public var connectButton:MovieClipButton;
		public var disconnectButton:MovieClipButton;
		public var groupNameField:TextInput;
		public var passwordField:TextInput;
		public var groupNameErrorDisplay:MovieClip;
		public var passwordErrorDisplay:MovieClip;
		public var groupNameErrorControl:SwagMovieClip;
		public var passwordErrorControl:SwagMovieClip;
		
		private var _chatGroupName:String;
		private var _chatGroupPassword:String;
		private var _mediaStreamName:String;
		private var _newChatConnectionAllowed:Boolean=false;
		private var _newChatUserData:Object;
		
		private var _videoChatDisplays:Array=new Array();
		
		public function VideoChatPanel(parentPanelRef:Panel) {
			super(parentPanelRef);
		}//constructor
		
		public function onGroupConnect(eventObj:SwagCloudEvent):void {
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onGroupConnect, this._announceConnection);
			References.debugPanel.debug("VideoChatPanel: Successfully connected to \""+this._chatGroupName+"\" group.");
			References.debugPanel.debug("VideoChatPanel: Attaching to default camera "+this.activeCamera.name+".");
			SwagDispatcher.addEventListener(SwagCloudEvent.DIRECT, this.onDirectMessageReceive, this, this._announceConnection);
			this.verifySocialName();			
		}//onGroupConnect
		
		public function onPeerConnect(eventObj:SwagCloudEvent):void {
			References.debugPanel.debug("VideoChatPanel: New peer \""+eventObj.remotePeerID+"\" connected to \""+this._chatGroupName+"\" group.");
			this.notifyPeerOfMediaStream(eventObj.remotePeerID);
		}//onPeerConnect
		
		public function onDirectMessageReceive(eventObj:SwagCloudEvent):void {		
			try {
				References.debugPanel.debug("VideoChatPanel: Received action message \""+eventObj.data.action+"\" from peer \""+eventObj.remotePeerID+"\".");
				switch (eventObj.data.action) {
					case "publish_new_stream" :		
						References.debugPanel.debug("VideoChatPanel: Peer has published a new stream \""+eventObj.data.streamID+"\".");
						SwagDispatcher.addEventListener(PanelEvent.ONHIDE, this.onConfirmPanelClose, this);
						SwagDispatcher.addEventListener(PanelEvent.ONSHOW, this.updateConfirmationPanel, this);
						var confirmPanel:VideoChatConfirmPanel=References.panelManager.togglePanel("video_chat_confirm", false) as VideoChatConfirmPanel;						
						this._newChatUserData=eventObj.data;
						this._newChatUserData.groupName=this._chatGroupName;
						this.notifyPeerOfMediaStream(eventObj.remotePeerID);
						break;
					default: break;
				}//switch
			} catch (e:*) {
				References.debugPanel.debug("VideoChatPanel: Received incorrectly formatted broadcast.");
			}//catch
		}//onDirectMessageReceive
		
		public function onConfirmPanelClose(eventObj:PanelEvent):void {
			SwagDispatcher.removeEventListener(PanelEvent.ONHIDE, this.onConfirmPanelClose, this);
			this._announceConnection.netGroup.close();
			this._announceConnection=null;
			if (this._newChatConnectionAllowed) {
				References.debugPanel.debug("VideoChatPanel: User accepted incoming video chat request.");
				this.createDisplay("default_remote",this._newChatUserData.streamID);
				this._newChatConnectionAllowed=false;
			} else {
				References.debugPanel.debug("VideoChatPanel: User refused incoming video chat request.");
			}//else
		}//onConfirmPanelClose
		
		public function updateConfirmationPanel(eventObj:PanelEvent):void {
			if (Panel(eventObj.source).content is VideoChatConfirmPanel) {
				SwagDispatcher.removeEventListener(PanelEvent.ONSHOW, this.updateConfirmationPanel, this);
				VideoChatConfirmPanel(Panel(eventObj.source).content).updateRemoteUserData(this._newChatUserData);
			}//if
		}//updateConfirmationPanel
		
		public function onAllowConnection(eventObj:VideoChatConfirmEvent):void {
			this._newChatConnectionAllowed=true;
		}//onAllowConnection
		
		public function onDenyConnection(eventObj:VideoChatConfirmEvent):void {
			this._newChatConnectionAllowed=false;	
		}//onDenyConnection
		
		private function verifySocialName():void {
			SwagDispatcher.removeEventListener(PanelEvent.ONSHOW, this.verifySocialName, this.parentPanel);
			References.debugPanel.debug("VideoChatPanel: Verifying social name...");
			if (References.IdentityPanel==null) {
				References.debugPanel.debug("!FATAL ERROR! Identity Panel couldn't be found in memory space!");
				return;
			}//if
			if ((References.IdentityPanel.socialName==null) || (References.IdentityPanel.socialName=="")) {
				References.debugPanel.debug("VideoChatPanel: Social is blank. Showing Identity Panel to allow user to update.");
				SwagDispatcher.addEventListener(PanelEvent.ONSHOW, this.showSocialNameError, this, References.IdentityPanel.parentPanel);
				this.parentPanel.hide(Panel(this.parentPanel).defaultHideDirection);			
				References.IdentityPanel.parentPanel.show(Panel(this.parentPanel).defaultShowDirection);
			} else {
				this.connectButton.hide();
				this.disconnectButton.show();
				this._mediaStreamName=this.generateUniqueStreamID(References.IdentityPanel.socialName, this._announceConnection.neighborCount);
				References.debugPanel.debug("VideoChatPanel: Social name verified.");				
				this.attachCamera(this.defaultCameraName);
				this.createOutgoingStream();
			}//else
		}//verifySocialName
				
		
		private function notifyPeerOfMediaStream(peerID:String):void {
			var sendObject:Object=new Object();
			sendObject.id=this.parentPanel.panelID;;			
			sendObject.action="publish_new_stream";
			sendObject.streamID=this._mediaStreamName;
			sendObject.remoteUserImage=null;
			sendObject.remoteUserImage=References.IdentityPanel.profileImage.profileImageData;
			sendObject.socialName=References.IdentityPanel.socialName;
			References.debugPanel.debug ("VideoChatPanel: Notifying peer \""+peerID+"\" of new video stream \""+this._mediaStreamName+"\".");		
			this._announceConnection.send(sendObject, peerID);
		}//notifyPeersOfMediaStream
		
		public function showSocialNameError(eventObj:PanelEvent):void {			
			SwagDispatcher.removeEventListener(PanelEvent.ONSHOW, this.showSocialNameError, References.IdentityPanel.parentPanel);			
			SwagDispatcher.addEventListener(IDPanelEvent.ONUPDATE, this.onEditSocialName, this, References.IdentityPanel);
			References.IdentityPanel.showFieldError("socialName");
		}//showSocialNameError
		
		public function onEditSocialName(eventObj:IDPanelEvent):void {			
			SwagDispatcher.removeEventListener(IDPanelEvent.ONUPDATE, this.verifySocialName, References.IdentityPanel);
			this.parentPanel.show(Panel(this.parentPanel).defaultShowDirection);
			References.IdentityPanel.parentPanel.hide(Panel(this.parentPanel).defaultHideDirection);
			SwagDispatcher.addEventListener(PanelEvent.ONSHOW, this.verifySocialName, this, this.parentPanel);			
		}//onEditSocialName		
		
		//Creates a unique media stream ID combining the supplies social name, system clock, position index (connected neighbour count), and 
		//a random value.
		private function generateUniqueStreamID(socialName:String, positionIndex:Number):String {
			var generatedID:String=new String();
			generatedID=this._chatGroupName+"_"+socialName+"_";
			var dateObj:Date=new Date();
			generatedID+=String(dateObj.day)+String(dateObj.date)+String(dateObj.fullYear);
			generatedID+=String(dateObj.hours)+String(dateObj.minutes)+String(dateObj.seconds)+String(dateObj.milliseconds);
			generatedID+=String(dateObj.time);
			return (generatedID);
		}//generateUniqueStreamID
				
		
		public function get defaultCameraName():String {			
			if (SwagDataTools.isXML(this.panelData.default)) {
				var defaultNode:XML=this.panelData.default[0] as XML;	
				if (SwagDataTools.isXML(defaultNode.@camera)) {					
					return (String(defaultNode.@camera));
				}//if
			}//if
			var newDefaultNode:XML=new XML("<default />");			
			newDefaultNode.@camera=this.firstInstalledCamera;
			this.panelData.appendChild(newDefaultNode);			
			return (String(newDefaultNode.@camera));
		}//get defaultCameraName
		
		private function createOutgoingStream():void {		
			this.attachCamera(this.defaultCameraName);
			if ((this._announceConnection!=null) && (this._webcam!=null)) {
				this._webcamConnection=new SwagCloud();
				References.debugPanel.debug("VideoChatPanel: Creating new outbound connection \""+this._mediaStreamName+"\"");
				SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECT, this.onOutgoingStreamConnect, this, this._webcamConnection);
				SwagDispatcher.addEventListener(SwagCloudEvent.GROUPDISCONNECT, this.onOutgoingStreamFail, this, this._webcamConnection);
				SwagDispatcher.addEventListener(SwagCloudEvent.GROUPREJECT, this.onOutgoingStreamFail, this, this._webcamConnection);
				//The outgoing stream uses the stream name for both the group and the password
				this._webcamConnection.connectGroup(this._mediaStreamName, true, "");				
			}//if
		}//createOutgoingStream
		
		public function onOutgoingStreamConnect(eventObj:SwagCloudEvent):void {
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onOutgoingStreamConnect, this._webcamConnection);
			References.debugPanel.debug("VideoChatPanel: Beginning outbound camera stream \""+this._mediaStreamName+"\"");
			References.debugPanel.debug("VideoChatPanel: Creating media stream "+this._mediaStreamName+"\".");
			this._webcamConnection.createMediaStream(this._mediaStreamName);
			References.debugPanel.debug("VideoChatPanel: Starting media stream from "+this.activeCamera.name);
			this._webcamConnection.streamCamera(this.activeCamera);			
		}//onOutgoingStreamConnect
		
		public function onOutgoingStreamFail(eventObj:SwagCloudEvent):void {
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPDISCONNECT, this.onOutgoingStreamFail, this._webcamConnection);
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPREJECT, this.onOutgoingStreamFail, this._webcamConnection);
			if (eventObj.type==SwagCloudEvent.GROUPDISCONNECT) {
				References.debugPanel.debug("VideoChatPanel: Stream connection \""+this._mediaStreamName+"\" failed! (Connection was dropped)");	
			} else {
				References.debugPanel.debug("VideoChatPanel: Stream connection \""+this._mediaStreamName+"\" failed! (Connection was rejected)");
			}//else
			this.disconnect();			
		}//onOutgoingStreamFail
		
		/**
		 * Creates a display, as specified in the associated displays settings data.
		 *  
		 * @param id The ID of the display to generate. If left blank or null, all displays will be generated.		 
		 * @param remoteStreamName The published stream name to attach to the stream.
		 * 
		 * @return <em>True</em> if the display(s) could be created. <em>False</em> will only be returned if no display could be created
		 * or if there was an error in creating the display in some way.
		 */
		private function createDisplay(id:String=null, remoteStreamName:String=null):Boolean {
			if (!SwagDataTools.isXML(this.panelData.displays)) {				
				return (false);
			}//if
			var displaysNode:XML=this.panelData.displays[0] as XML;
			var displayChildren:XMLList=displaysNode.children();
			var displayCreated:Boolean=false;
			for (var count:uint=0; count<displayChildren.length(); count++) {				
				var currentDisplayNode:XML=displayChildren[count] as XML;
				if (SwagDataTools.isXML(currentDisplayNode.@id)) {
					var currentDisplayID:String=String(currentDisplayNode.@id);
				} else {
					currentDisplayID=null;
				}//else
				if ((id==null) || (id==currentDisplayID)) {
					displayCreated=true;
					var videoChatDisplay:VideoDisplayComponent=new VideoDisplayComponent(currentDisplayNode);
					//var videoChatDisplay:VideoDisplayComponent=new VideoDisplayComponent();
					this._videoChatDisplays.push(videoChatDisplay);
					this.addChild(videoChatDisplay);
					videoChatDisplay.remoteStreamName=remoteStreamName;
					videoChatDisplay.localCamera=this.activeCamera;
					videoChatDisplay.createDisplay();
				}//if
			}//for
			return (displayCreated);
		}//createDisplay		
		
		private function findRemoteDisplayNode(displayNumber:uint, totalDisplays:uint):XML {
			if (!SwagDataTools.isXML(this.panelData.displays)) {				
				return (null);
			}//if
			var displaysNode:XML=this.panelData.displays[0] as XML;
			var displayChildren:XMLList=displaysNode.children();
			var displayCreated:Boolean=false;
			for (var count:uint=0; count<displayChildren.length(); count++) {				
				var currentDisplayNode:XML=displayChildren[count] as XML;
				if (currentDisplayNode.localName()=="remote") {
					if (SwagDataTools.isXML(currentDisplayNode.@connection)) {
						var currentDisplayValue:String=new String(currentDisplayNode.@connection);
					} else {
						currentDisplayValue=null;
					}//else
					if (currentDisplayValue!=null) {
						var displaySplit:Array=currentDisplayValue.split(":");
						if (displaySplit.length>1) {
							var currentDisplayString:String=displaySplit[0] as String;
							var totalDisplaysString:String=displaySplit[1] as String;
							var currentDisplayNum:uint=uint(currentDisplayString);
							var totalDisplayNum:uint=uint(totalDisplaysString);
							if ((displayNumber==currentDisplayNum) || (totalDisplayNum==totalDisplays)) {
								return (currentDisplayNode);
							}//if
						}//if
					}//if
				}//if
			}//for
			return (null);
		}//createDisplay
		
		public function onConnectClick(eventObj:MovieClipButtonEvent):void {
			var errorsFound:Boolean=false;			
			if ((this.groupNameField.text=="") || (this.groupNameField.text==null)) {
				this.groupNameErrorControl.playRange("show", "onShow", false);
				errorsFound=true;
			}//if			
			if (errorsFound) {
				return;
			}//if
			this._chatGroupName=this.groupNameField.text;
			this._chatGroupPassword=this.passwordField.text;
			References.debugPanel.debug("VideoChatPanel: Connecting to chat group \""+this.groupNameField.text+"\"...");
			this.connectToGroup(this._chatGroupName, true, this._chatGroupPassword);
		}//onConnectClick
		
		public function onDisconnectClick(eventObj:MovieClipButtonEvent):void {
			this.disconnect();
		}//onDisconnectClick
		
		private function disconnect(... args):void {			
			VideoDisplayComponent.removeAllDisplays("remote");
			this._webcamConnection.disconnectGroup();
			this._webcamConnection=null;
			this.connectButton.show();
			this.disconnectButton.hide();
		}//disconnect
		
		
		public function get activeCamera():Camera {
			if (this._webcam==null) {
				this.attachCamera(this.defaultCameraName);
			}//if
			return (this._webcam);
		}//get activeCamera
		
		private function attachCamera(cameraID:String=""):void {
			if ((cameraID=="") || (cameraID==null)) {
				References.debugPanel.debug("VideoChatPanel: Could not attach camera (no camera specified).");
				return;
			}//if
			this._webcam=Camera.getCamera(cameraID);			
		}//attachCamera
		
		private function get firstInstalledCamera():String {
			var cameraInstance:Camera=Camera.getCamera();
			if (cameraInstance!=null) {
				return (cameraInstance.name)
			}//if
			return ("-1");
		}//firstInstalledCamera
		
		private function connectToGroup (groupName:String, open:Boolean=true, password:String=null):void {
			this._announceConnection=new SwagCloud();			
			SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECT, this.onGroupConnect, this, this._announceConnection);
			SwagDispatcher.addEventListener(SwagCloudEvent.PEERCONNECT, this.onPeerConnect, this, this._announceConnection);
			this._announceConnection.connectGroup(groupName, open, password);			
		}//connectToGroup
		
		private function addListeners():void {
			var connectTooltip:Tooltip=new Tooltip(this.connectButton, "Connect");
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onConnectClick, this, this.connectButton);
			var disconnectTooltip:Tooltip=new Tooltip(this.disconnectButton, "Disconnect");
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onDisconnectClick, this, this.disconnectButton);
			SwagDispatcher.addEventListener(TextInputEvent.ONEDIT, this.onChangeSettings, this, this.groupNameField);
			SwagDispatcher.addEventListener(TextInputEvent.ONEDIT, this.onChangeSettings, this, this.passwordField);
			SwagDispatcher.addEventListener(VideoChatConfirmEvent.ALLOW, this.onAllowConnection, this);
			SwagDispatcher.addEventListener(VideoChatConfirmEvent.REFUSE, this.onDenyConnection, this);
		}//addListeners
		
		private function removeListeners():void {
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onConnectClick, this.connectButton);
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onDisconnectClick, this.disconnectButton);
			SwagDispatcher.removeEventListener(TextInputEvent.ONEDIT, this.onChangeSettings, this.groupNameField);
			SwagDispatcher.removeEventListener(TextInputEvent.ONEDIT, this.onChangeSettings, this.passwordField);
			SwagDispatcher.removeEventListener(VideoChatConfirmEvent.ALLOW, this.onAllowConnection, this);
			SwagDispatcher.removeEventListener(VideoChatConfirmEvent.REFUSE, this.onDenyConnection, this);
		}//removeListeners
		
		public function onChangeSettings(eventObj:TextInputEvent):void {
			References.debugPanel.debug("VideoChatPanel: Settings changed. Saving..");
			this._chatGroupName=this.groupNameField.text;
			this._chatGroupPassword=this.passwordField.text;
			if (SwagDataTools.isXML(this.panelData.default)) {
				var defaultNode:XML=this.panelData.default[0] as XML;				
				defaultNode.@group=this._chatGroupName;
				defaultNode.@camera=this.defaultCameraName;
			}//else			
			Settings.saveSettings();
		}//onChangeSettings
		
		private function updateSettings():void {
			if (SwagDataTools.isXML(this.panelData.default)) {
				var defaultNode:XML=this.panelData.default[0] as XML;
				if (SwagDataTools.isXML(defaultNode.@group)) {
					this._chatGroupName=new String(defaultNode.@group);
					this.groupNameField.text=this._chatGroupName;
				}//if
			}//if
		}//updateSettings
		
		override public function initialize():void {
			References.debugPanel.debug("VideoChatPanel: Initializing.");			
			this.updateSettings();
			this.groupNameErrorControl=new SwagMovieClip(this.groupNameErrorDisplay);
			this.groupNameErrorControl.gotoAndStop(1);
			this.passwordErrorControl=new SwagMovieClip(this.passwordErrorDisplay);
			this.passwordErrorControl.gotoAndStop(1);			
			if (this.createDisplay("default_local")) {
				References.debugPanel.debug("VideoChatPanel: Created default local display successfully.");
			} else {
				References.debugPanel.debug("VideoChatPanel: Could not create default local display (most likely missing XML data).");
			}//else
			this.disconnectButton.visible=false;
			this.addListeners();
		}//initialize
		
	}//VideoChatPanel
		
}//package