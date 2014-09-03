package socialcastr.ui.components {
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.Strong;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.media.Camera;
	import flash.media.Sound;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import socialcastr.References;
	import socialcastr.interfaces.ui.components.IVideoDisplayComponent;
	import socialcastr.ui.Panel;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.events.SwagCloudEvent;
	import swag.network.SwagCloud;
	
	/**
	 * Generic video display for use with SocialCastr. The class should be instantiated with XML data specifying the layout
	 * of the video display. The data looks like this:
	 * 
	 * <remote id="remote1" x="220" y="20" width="320" height="240" />
	 * 
	 * -or-
	 * 
	 * <local id="local1" x="220" y="20" width="320" height="240" />
	 * 
	 * -or-
	 * 
	 * <none id="local1" x="220" y="20" width="320" height="240" />
	 * 
	 * The "remote" node specifies a remote video window and requires a remote <code>NetStream</code> object whereas a
	 * "local" video display requires only a valid camera reference.
	 * 
	 * After passing the node to the new VideoDisplay instance, call either the <code>attachCamera</code> or <code>attachVideoStream</code>
	 * methods followed by <code>createDisplay</code>.
	 * 
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
	public class VideoDisplayComponent extends MovieClip implements IVideoDisplayComponent {
		
		private static var _displays:Vector.<VideoDisplayComponent>=new Vector.<VideoDisplayComponent>;
		
		/**
		 * Optional callback method invoked whenever the video display component attaches to a stream. 
		 */
		public var onConnectStream:Function=null;
		
		private const _defaultWidth:Number=640;
		private const _defaultHeight:Number=480;
		private var _displayData:XML=<none id="VideoDisplay_#" x="105" y="50" width="640" height="480" />;
		private var _video:Video;
		private var _camera:Camera;
		private var _remoteStreamName:String;
		private var _streamConnection:SwagCloud;
		//Used when streaming a local or remote file in "Data Generation Mode", or when data is sent via a method
		//other than through a published stream (a distributed file, for example). Because the connections
		//must be connected to null for playback, these connections are used even if streaming a remote file.
		private var _localStreamConnection:NetConnection;
		private var _localStream:NetStream;
		private var _displayID:String=new String();
		
		private var _xTween:Tween=null;
		private var _yTween:Tween=null;
		private var _widthTween:Tween=null;
		private var _heightTween:Tween=null;
		private var _displayType:String="none";
		
		public var displayMask:MovieClip;
		
		/**
		 * Creates a new instance of the video display component. Be sure to add it to the
		 * display list and invoke <code>createDisplay</code> method if not specifying the 
		 * <code>autoConnect</code> parameter.
		 *  
		 * @param displayData The initialization XML data withi which to create this component with. See
		 * the class header for information on valid structure.
		 * @param autoConnect An optional reference to use to automatically attach to this video display component.
		 * If this is a <code>Camera</code> object, the internal camera reference is set. If this is a string,
		 * it is assumed to be a group stream name it will be used to automatically connect the component to the 
		 * stream. If this is a reference to a <code>SwagCloud</code> instance, an attempt is made to connect to its
		 * active stream (so it must already be connected and streaming). If <em>null</em> (default), not automatic 
		 * connection is attempted.
		 * 
		 */
		public function VideoDisplayComponent(displayData:XML=null, autoConnect:*=null)	{
			_displays.push (this);
			if (displayData!=null) {
				this._displayData=displayData;	
			}//if	
			if (autoConnect!=null) {
				if (autoConnect is Camera) {
					this.attachActiveCamera(autoConnect);
					this.createDisplay(true);
				}//if
				if (autoConnect is String) {
					this.remoteStreamName=autoConnect;
					this.createDisplay(true);
				}//if
				if (autoConnect is SwagCloud) {
					if (SwagCloud(autoConnect).stream!=null) {
						this._streamConnection=autoConnect;
						this.createDisplay(false);
						this._streamConnection.attachVideoStream(this._video);
					}//if
				}//if
			}//if
		}//constructor
		
		/**
		 * Creates the display based on the supplied or set video display component initialization data.
		 * Call this method after instantiating the component to actually create the video display and optionally
		 * attach an active camera or remote stream.
		 * <p>Note that an automated streaming connection will use the default settings for all parameters
		 * except the <code>streamName</code> when invoking the <code>attachRemoteStream</code> method. If this
		 * is not desired, prevent automated startup and initiate the connection manually.</p>
		 *  
		 * @param autoStart If <em>true</em>, the component is assumed to be fully initialized (XML data supplied
		 * and any active camera or simple stream name alread set), and will attempt to automatically attach
		 * to the specified source (and begin streamin, if applicable). If <em>false</em>, any streams or cameras
		 * must be manually attached.
		 * 
		 */
		public function createDisplay(autoStart:Boolean=true):void {
			this._video=new Video();
			this._video.width=this.initWidth;
			this._video.height=this.initHeight;
			this.createMask();
			if (this.displayMask!=null) {
				this.displayMask.width=this.initWidth;
				this.displayMask.height=this.initHeight;
			}//if
			this._video.x=this.initX;
			this._video.y=this.initY;
			if (this.displayMask!=null) {
				this.displayMask.x=this._video.x;
				this.displayMask.y=this._video.y;
				this.displayMask.visible=false;
			}//if
			this.addChild(this._video);	
			if (autoStart==false) {				
				return;
			}//if
			//Everything beyond this is autoStart related.
			if (this.displayType=="local") {
				if (this._camera==null) {
					
					References.debugPanel.debug("VideoDisplayComponent: No local camera defined for local display -- cannot create!");	
				} else {
					References.debugPanel.debug("VideoDisplayComponent: Attaching "+this._camera.name+" to display.");
					this.attachActiveCamera(this._camera);
				}//else
			} else if (this.displayType=="remote") {
				if (this.remoteStreamName=="") {
					References.debugPanel.debug("VideoDisplayComponent: No stream name supplied for remote stream.");
				} else {
					References.debugPanel.debug("VideoDisplayComponent: Attaching remote stream \""+this.remoteStreamName+"\" to display.");
					this.attachRemoteStream(this.remoteStreamName);
				}//else
			} else if (this.displayType=="none") {
			} else {
				//this.displayType="none";
			}//else
		}//createDisplay
		
		/** 
		 * @return The initial video display component width, either as specified in the initial
		 * startup XML data, or as a default value.
		 */
		public function get initWidth():Number {
			if (SwagDataTools.isXML(this._displayData.@width)) {
				return (Number(this._displayData.@width));
			} else {
				return (this._defaultWidth);
			}//else
		}//initWidth
		
		/** 
		 * @return The initial video display component height, either as specified in the initial
		 * startup XML data, or as a default value.
		 */
		public function get initHeight():Number {
			if (SwagDataTools.isXML(this._displayData.@height)) {
				return (Number(this._displayData.@height));
			} else {
				return (this._defaultHeight);
			}//else
		}//initHeight
		
		/** 
		 * @return The initial video display component X position, either as specified in the initial startup
		 * XML data, or the default value.
		 */
		public function get initX():Number {
			if (SwagDataTools.isXML(this._displayData.@x)) {
				return (Number(this._displayData.@x));
			} else {
				return (0);
			}//else
		}//initX
		
		/** 
		 * @return The initial video display component Y position, either as specified in the initial startup
		 * XML data, or the default value.
		 */
		public function get initY():Number {
			if (SwagDataTools.isXML(this._displayData.@y)) {
				return (Number(this._displayData.@y));
			} else {
				return (0);
			}//else
		}//initY
		
		/**
		 * Updates the video display component's dimensions and location from new XML initialization data
		 * and automatically animated the component to the new location / dimensions.
		 *  
		 * @param newDisplayData The new initialization XML data to apply to the video display component instance.
		 * Refer to the <code>_displayData</code> instantiation data at the beginning of this class for
		 * correct XML structure.
		 * @param animationSpeed The speed, in seconds, at which to perform the update animation.
		 * 
		 */
		public function updateToNewDisplayData(newDisplayData:XML, animationSpeed:Number=1):void {
			this._displayData=newDisplayData;
			this.tweenToNewDisplayLocation(animationSpeed);
		}//updateToNewDisplayData
		
		/**
		 * @private
		 */
		private function tweenToNewDisplayLocation(tweenSpeed:Number=1):void {
			this.clearAllTweens();			
			//Should we tween the video and mask independently instead?
			this._xTween=new Tween(this, "x", Strong.easeOut, this.x, this.initX, tweenSpeed, true);
			this._yTween=new Tween(this, "y", Strong.easeOut, this.y, this.initY, tweenSpeed, true);
			this._widthTween=new Tween(this, "width", Strong.easeOut, this.width, this.initWidth, tweenSpeed, true);
			this._heightTween=new Tween(this, "height", Strong.easeOut, this.height, this.initHeight, tweenSpeed, true);
		}//tweenToNewDisplayLocation
		
		/**
		 * @private
		 */
		private function clearAllTweens():void {
			if (this._xTween!=null) {
				this._xTween.stop();
				this._xTween.removeEventListener(TweenEvent.MOTION_CHANGE, this.onTweenUpdate);
				this._xTween=null;
			}//if
			if (this._yTween!=null) {
				this._yTween.stop();
				this._yTween.removeEventListener(TweenEvent.MOTION_CHANGE, this.onTweenUpdate);
				this._yTween=null;
			}//if
			if (this._widthTween!=null) {
				this._widthTween.stop();
				this._widthTween.removeEventListener(TweenEvent.MOTION_CHANGE, this.onTweenUpdate);
				this._widthTween=null;
			}//if
			if (this._heightTween!=null) {
				this._heightTween.stop();
				this._heightTween.removeEventListener(TweenEvent.MOTION_CHANGE, this.onTweenUpdate);
				this._heightTween=null;
			}//if
		}//clearAllTweens
		
		/**
		 * @private
		 */
		private function onTweenUpdate(eventObj:TweenEvent):void {
			
		}//onTweenEvent
		
		/**
		 * Pauses the remote stream connection associated with this video display component,
		 * or does nothing if no remote stream is attached. 
		 */
		public function pauseStream():void {
			if (this._streamConnection==null) {
				return;
			}//if
			//This should probably be updated to control each stream individually!
			this._streamConnection.pauseStreams();			
		}//pauseStream
		
		/**
		 * Pauses the remote stream connection associated with this video display component,
		 * or does nothing if no remote stream is attached. 
		 */
		public function resumeStream():void {
			//This should probably be updated to control each stream individually!
			if (this._streamConnection==null) {
				return;
			}//if
			this._streamConnection.resumeStreams();			
		}//resumeStream
		
		/** 
		 * @return The name of the currently connected remote stream, or an empty string if none is assigned.
		 * Note that a valid stream name does not mean that the stream is connected or streaming. Also,
		 * 
		 */
		public function get remoteStreamName():String {
			if (this._remoteStreamName==null) {
				this._remoteStreamName=new String();
			}//if
			return (this._remoteStreamName);
		}//get remoteStreamName
		
		public function set remoteStreamName(nameSet:String):void {
			this._remoteStreamName=nameSet;
		}//set remoteStreamName
		
		/** 
		 * @return A reference to the <code>Camera</code> object currently attached to the video
		 * display object, or <em>null</em> if none is attached. 
		 */
		public function get localCamera():Camera {
			return (this._camera);
		}//get localCamera
		
		public function set localCamera(cameraSet:Camera):void {
			this._camera=cameraSet;
		}//set localCamera
		
		/** 
		 * @return A reference to the <code>SwagCloud</code> or <code>NetStream</code> instance being used to stream or host 
		 * the contents of the video display component, or <em>null</em> if no stream is currentlly active.
		 */
		public function get streamConnection():* {
			if (this._localStream!=null) {
				return (this._localStream);
			}//if
			return (this._streamConnection);
		}//get streamConnection
		
		/** 
		 * @return The ID of the current video display component, either as specified in the initilization
		 * XML data, or automatically generated as "VideoDisplay_" with the index of the highest detected
		 * video display component, plus one, is added to the end. <em>null</em> is returned in the exceptional
		 * possibility that no video display components can be detected in memory. 
		 */
		public function get displayID():String {
			if (SwagDataTools.isXML(this._displayData.@id)) {
				return (String(this._displayData.@id));
			} else {
				for (var count:uint=0; count<_displays.length; count++) {
					var currentDisplay:VideoDisplayComponent=_displays[count];
					if (currentDisplay==this) {
						return ("VideoDisplay_"+String(count));
					}//if
				}//for				
			}//else
			return (null);
		}//getDisplayID
		
		/**
		 * Returns a <code>VideoDisplay</code> instance by index. Index values are 1-based (the first
		 * display starts at 1, etc.)
		 *  
		 * @param index The index of the desired <code>VideoDisplay</code> instance to return.
		 * 
		 * @return The <code>VideoDisplay</code> at the specified index, or <em>null</em> if none
		 * cane be found.
		 * 
		 */
		public static function getDisplayByIndex(index:uint):VideoDisplayComponent {
			if ((index<1) || (index>=_displays.length)) {
				return (null);
			}//if
			index-=1;
			return (_displays[index] as VideoDisplayComponent);
		}//getDisplayByIndex
		
		/**
		 * Returns the number of currently active <code>VideoDisplay</code> instances		 
		 */
		public static  function get getNumberOfDisplays():uint {			
			return (_displays.length);
		}//get getNumberOfDisplays
		
		/** 
		 * @private
		 */
		private function attachActiveCamera(cameraRef:Camera):void {		
			this._video.attachCamera(cameraRef);
			//this.displayType="none";
		}//attachActiveCamera
		
		/**
		 * Attaches the video display component to a remote <code>SwagCloud</code> stream. Calling this method
		 * automates the process of connecting to the stream and is therefore asynchronous.
		 * <p>If no group name is supplied, the stream name is used. If the stream name is omitted (<em>null</em> or
		 * a blank string), the stream is assumed to be distributed and playback begins using this connection
		 * method instead of the standard published live stream.</p>  
		 * 
		 * @param streamName The exact name of the stream to connect to within the <code>SwagCloud</code> group, once connected.
		 * @param groupName The exact name of the group containing the stream to connect to.
		 * @param password The password of the group containing the stream to connect to.
		 * @param open The open group setting in the publishing <code>SwagCloud</code> instance. In other words,
		 * this parameter must match the "open" setting of the group to connect to, otherwise it is assumed
		 * not to be the same group.
		 * 
		 * @return The <code>SwagCloud</code> instance created for the stream, also available as the <code>streamconnection</code>
		 * property.
		 * 
		 */
		public function attachRemoteStream(streamName:String, groupName:String="", password:String="", open:Boolean=true):SwagCloud {			
			if (this._streamConnection!=null) {				
				SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onConnectRemoteStream, this._streamConnection);
				this._streamConnection.disconnectGroup();
				this._streamConnection=null;
			}//if
			this._streamConnection=new SwagCloud(); 			
			SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECT, this.onConnectRemoteStream, this, this._streamConnection);
			if (groupName=="") {
				groupName=streamName;
			}//if
			this._remoteStreamName=streamName;
			this._streamConnection.connectGroup(groupName, open, password);
			return (this._streamConnection);
		}//attachRemoteStream	
		
		/**
		 * Attaches the video display component to a remote <code>SwagCloud</code> stream. This is almost identical
		 * to the <code>attachRemoteStream</code> method except that the connection is assumed to carry a distributed / shared
		 * stream rather than a live one which uses the "Data Generation" mode of the <code>NetStream</code> object. Because this
		 * is not a live stream, it can also be recorded or otherwise captured as in any other <code>SwagCloud.gather</code> operation. 
		 * 
		 * @param streamName The exact name of the stream to connect to within the <code>SwagCloud</code> group, once connected.
		 * @param groupName The exact name of the group containing the stream to connect to.
		 * @param password The password of the group containing the stream to connect to.
		 * @param open The open group setting in the publishing <code>SwagCloud</code> instance. In other words,
		 * this parameter must match the "open" setting of the group to connect to, otherwise it is assumed
		 * not to be the same group.
		 * 
		 * @return The <code>SwagCloud</code> instance created for the stream, also available as the <code>streamconnection</code>
		 * property.
		 * 
		 */
		public function attachRemoteDistributedStream(streamName:String, groupName:String="", password:String="", open:Boolean=true):SwagCloud {			
			if (this._streamConnection!=null) {				
				SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onConnectRemoteStream, this._streamConnection);
				this._streamConnection.disconnectGroup();
				this._streamConnection=null;
			}//if
			this._streamConnection=new SwagCloud(); 			
			SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECT, this.onConnectRemoteStream, this, this._streamConnection);
			if (groupName=="") {
				groupName=streamName;
			}//if
			this._remoteStreamName=null; //Important! This is how the onConnectRemoteStream method differentiates the connection type.
			this._streamConnection.connectGroup(groupName, open, password);
			return (this._streamConnection);
		}//attachRemoteDistributedStream	
		
		/**
		 * Event listener invoked when the remote stream for the video display component has connected.
		 * 
		 * @param eventObj A <code>SwagCloudEvent</code> object.
		 * 
		 */
		public function onConnectRemoteStream(eventObj:SwagCloudEvent):void {
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onConnectRemoteStream, this._streamConnection);
			this.displayType="remote";
			if ((this._remoteStreamName==null) || (this._remoteStreamName=="")) {
				References.debugPanel.debug("VideoDisplayComponent: Distributed stream (no name) connection established.");	
			} else {
				References.debugPanel.debug("VideoDisplayComponent: Published stream \""+this._remoteStreamName+"\" connection established.");
			}//else			
			this.attachActiveStream();
		}//onConnectRemoteStream 
		
		/**
		 * Creates a <em>null</em> connection <em>NetStream</em> connection and associates it
		 * with the <code>Video</code> object being used to display the stream. Used for local playback
		 * of pre-recorded media and can also be used as a reference to remote distributed streams.
		 *  
		 * @return The <code>NetStream</code> object being used for local playback. Use the <code>appendBytes</code>
		 * and <code>appendBytesAction</code> methods to feed data to the local stream for playback.
		 * 
		 */
		public function attachLocalStream():NetStream {
			if (this._localStreamConnection!=null) {
				this._localStreamConnection=null;
			}//if
			this._localStreamConnection=new NetConnection();
			this._localStreamConnection.connect(null);
			this._localStream=new NetStream(this._localStreamConnection);
			this._video.attachNetStream(this._localStream);
			this._localStream.client=this;
			this._localStream.play(null);
			return (this._localStream);
		}//attachLocalStream
		
		public function onMetaData(... args):void {
			References.debug ("onMetaData "+args[0]);
		}//onMetaData
		
		public function onCuePoint(... args):void {
			References.debug ("onCuePoint "+args[0]);
		}//onCuePoint
		
		public function onPlayStatus(... args):void {
			References.debug("onPlaystatus: "+args[0]);
		}
		
		public function onSeekPoint(... args):void {
			References.debug("onSeekPoint: "+args[0]);
		}
		
		/**
		 * @private 
		 */
		private function closeRemoteStream():void {
			if (this._streamConnection!=null) {
				this._streamConnection.stopStreams();
				//this.displayType="none";
			}//if
		}//closeRemoteStream
		
		/**
		 * @private 
		 */
		private function attachActiveStream():void {
			if (this._streamConnection==null) {
				return;
			}//if			
			References.debugPanel.debug("VideoDisplayComponent: Attaching video stream.");
			this._streamConnection.attachVideoStream(this._video);
			if ((this._remoteStreamName==null) || (this._remoteStreamName=="")) {
				References.debugPanel.debug("VideoDisplayComponent: Starting distributed stream.");
				this._streamConnection.playDistributedStream(this.attachLocalStream());
			} else {
				References.debugPanel.debug("VideoDisplayComponent: Starting published stream \""+this._remoteStreamName+"\".");
				this._streamConnection.playVideoStream(this._remoteStreamName);
			}//else			
			if (this.onConnectStream!=null) {
				this.onConnectStream();
			}//if
		}//attachActiveStream
				
		/**
		 * @private
		 */
		private function createMask():void {
			if (this.displayMask!=null) {
				this.mask=this.displayMask;
			}//if
		}//createMask
		
		/**
		 * @private
		 */
		private function removeMask():void {			
			this.mask=null;
			if (this.displayMask!=null) {
				this.displayMask.visible=false;
				this.displayMask.alpha=0;
			}//if
		}//removeMask
		
		/** 
		 * @param typeSet The type of display that this type of video display component is to behave as.
		 * Valid values include "local", "remote", and "none". This value is actually the node name (local name)
		 * of the associated XML initialization data.
		 */
		public function set displayType(typeSet:String):void {
			if ((typeSet==null) || (typeSet=="")) {
				return;
			}//if
			typeSet=SwagDataTools.stripOutsideChars(typeSet, SwagDataTools.SEPARATOR_RANGE);
			typeSet=typeSet.toLowerCase();
			if ((typeSet=="local") || (typeSet=="remote") || (typeSet=="none")) { 
				this._displayData.setLocalName(typeSet);
			}//if
		}//get displayType
		
		public function get displayType():String {
			return (this._displayData.localName() as String);
		}//get displayType
		
		/**
		 * Removes all current video display components of a certain type from memory and any
		 * display list they may be in.
		 *  
		 * @param type The type of display(s) to remove. Valid values are "all", "remote", and "local".
		 * 
		 * @return <em>True</em> if at least one display matching the specified type was removed, <em>false</em>
		 * otherwise.
		 */
		public static function removeAllDisplays(type:String):Boolean {
			var displayTypeString:String=new String(type);
			displayTypeString=displayTypeString.toLowerCase();
			displayTypeString=SwagDataTools.stripChars(displayTypeString, SwagDataTools.SEPARATOR_RANGE);
			var displayRemoved:Boolean=false;
			if ((displayTypeString!="local") && (displayTypeString!="remote") 
				&& (displayTypeString!="none") && (displayTypeString!="all")) {
				return (displayRemoved);
			}//if
			for (var count:uint=0; count<_displays.length; count++) {
				var currentDisplay:VideoDisplayComponent=_displays[count] as VideoDisplayComponent;
				if ((currentDisplay.displayType==displayTypeString) || (displayTypeString=="all")) {
					displayRemoved=true;
					_displays.splice(count, 1);
					currentDisplay.destroy();
					currentDisplay.parent.removeChild(currentDisplay);
				}//if
			}//for
			return (displayRemoved);
		}//removeAllDisplays
		
		/**
		 * Destroys the video display component by disconnecting and removing any active strems or attached
		 * cameras. Note that this method does not remove the video display component from the display list. 
		 *  
		 * @param args
		 * 
		 */
		public function destroy(... args):void {
			this.removeMask();
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onConnectRemoteStream, this._streamConnection);
			this.closeRemoteStream();
			if (this._video!=null) {
				this._video.attachCamera(null);
				this.removeChild(this._video);				
			}//if
			this._video=null;
			this._camera=null;
			this._streamConnection=null;
		}//destroy
		
	}//VideoDisplay class
	
}//package