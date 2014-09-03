package socialcastr.ui.panels {
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.Strong;
	
	import flash.display.MovieClip;
	import flash.media.Camera;
	import flash.media.Sound;
	import flash.media.Video;
	import flash.net.NetStream;
	
	import socialcastr.References;
	import socialcastr.interfaces.ui.IVideoChatDisplay;
	import socialcastr.ui.Panel;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
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
	public class VideoChatDisplay extends MovieClip implements IVideoChatDisplay {
		
		private static var _displays:Vector.<VideoChatDisplay>=new Vector.<VideoChatDisplay>;
		
		private const _defaultWidth:Number=640;
		private const _defaultHeight:Number=480;
		private var _displayData:XML;
		private var _video:Video;
		private var _camera:Camera;
		private var _remoteStreamName:String;
		private var _remoteStreamConnection:SwagCloud;
		private var _displayID:String=new String();
		
		private var _xTween:Tween=null;
		private var _yTween:Tween=null;
		private var _widthTween:Tween=null;
		private var _heightTween:Tween=null;
		private var _displayType:String="none";
		
		
		public var displayMask:MovieClip;

		
		public function VideoChatDisplay(displayData:XML)	{
			_displays.push (this);
			this._displayData=displayData;
			References.debugPanel.debug("New VideoChatDisplay instance created.");			
		}//constructor
		
		public function get initWidth():Number {
			if (SwagDataTools.isXML(this._displayData.@width)) {
				return (Number(this._displayData.@width));
			} else {
				return (this._defaultWidth);
			}//else
		}//initWidth
		
		public function get initHeight():Number {
			if (SwagDataTools.isXML(this._displayData.@height)) {
				return (Number(this._displayData.@height));
			} else {
				return (this._defaultHeight);
			}//else
		}//initHeight
		
		public function get initX():Number {
			if (SwagDataTools.isXML(this._displayData.@x)) {
				return (Number(this._displayData.@x));
			} else {
				return (0);
			}//else
		}//initX
		
		public function updateToNewDisplayData(newDisplayData:XML):void {
			this._displayData=newDisplayData;
			this.tweenToNewDisplayLocation();
		}//updateToNewDisplayData
		
		private function tweenToNewDisplayLocation():void {
			this.clearAllTweens();			
			//Should we tween the video and mask independently instead?
			this._xTween=new Tween(this, "x", Strong.easeOut, this.x, this.initX, 1, true);
			this._yTween=new Tween(this, "y", Strong.easeOut, this.y, this.initY, 1, true);
			this._widthTween=new Tween(this, "width", Strong.easeOut, this.width, this.initWidth, 1, true);
			this._heightTween=new Tween(this, "height", Strong.easeOut, this.height, this.initHeight, 1, true);
		}//tweenToNewDisplayLocation
		
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
		
		private function onTweenUpdate(eventObj:TweenEvent):void {
			
		}//onTweenEvent
		
		public function get initY():Number {
			if (SwagDataTools.isXML(this._displayData.@y)) {
				return (Number(this._displayData.@y));
			} else {
				return (0);
			}//else
		}//initY
		
		public function get remoteStreamName():String {
			if (this._remoteStreamName==null) {
				this._remoteStreamName=new String();
			}//if
			return (this._remoteStreamName);
		}//get remoteStreamName
		
		public function set remoteStreamName(nameSet:String):void {
			this._remoteStreamName=nameSet;
		}//set remoteStreamName
		
		public function get localCamera():Camera {
			return (this._camera);
		}//get localCamera
		
		public function set localCamera(cameraSet:Camera):void {
			this._camera=cameraSet;
		}//set localCamera
		
		public function get source():String {
			if (SwagDataTools.isXML(this._displayData.@source)) {
				var sourceString:String=new String(this._displayData.@source);
				return (sourceString);
			} else {
				return (null);
			}//else
		}//initY
		
		public function get displayID():String {
			if (SwagDataTools.isXML(this._displayData.@id)) {
				return (String(this._displayData.@id));
			} else {
				for (var count:uint=0; count<_displays.length; count++) {
					var currentDisplay:VideoChatDisplay=_displays[count];
					if (currentDisplay==this) {
						return ("VideoChatDisplay_"+String(count));
					}//if
				}//for				
			}//else
			return (null);
		}//getDisplayID
		
		/**
		 * Returns a <code>VideoChatDisplay</code> instance by index. Index values are 1-based (the first
		 * display starts at 1, etc.)
		 *  
		 * @param index The index of the desired <code>VideoChatDisplay</code> instance to return.
		 * 
		 * @return The <code>VideoChatDisplay</code> at the specified index, or <em>null</em> if none
		 * cane be found.
		 * 
		 */
		public static function getDisplayByIndex(index:uint):VideoChatDisplay {
			if ((index<1) || (index>=_displays.length)) {
				return (null);
			}//if
			index-=1;
			return (_displays[index] as VideoChatDisplay);
		}//getDisplayByIndex
		
		/**
		 * Returns the number of currently active <code>VideoChatDisplay</code> instances		 
		 */
		public static  function get getNumberOfDisplays():uint {			
			return (_displays.length);
		}//get getNumberOfDisplays
		
		private function attachActiveCamera(cameraRef:Camera):void {		
			this._video.attachCamera(cameraRef);			
		}//attachActiveCamera
		
		private function createRemoteSream(streamName:String):void {
			this._remoteStreamConnection=new SwagCloud(); 
			SwagDispatcher.addEventListener(SwagCloudEvent.GROUPCONNECT, this.onConnectRemoteStream, this, this._remoteStreamConnection);			
			this._remoteStreamConnection.connectGroup(streamName, true, "");
		}//createRemoteSream
		
		public function onConnectRemoteStream(eventObj:SwagCloudEvent):void {
			References.debugPanel.debug("VideoChatDisplay: Remote stream \""+this._remoteStreamName+"\" connection established.");	
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onConnectRemoteStream, this._remoteStreamConnection);
			this.attachActiveStream();
		}//onConnectRemoteStream
		
		private function closeRemoteStream():void {
			if (this._remoteStreamConnection!=null) {
				this._remoteStreamConnection.stopStreams();
			}//if
		}//closeRemoteStream
		
		private function disconnectRemoteStream():void {
			if (this._remoteStreamConnection!=null) {
				this._remoteStreamConnection.disconnectGroup();
				this._remoteStreamConnection=null;
			}//if
		}//disconnectRemoteStream
		
		private function attachActiveStream():void {
			References.debugPanel.debug("VideoChatDisplay: Attaching video stream.");
			this._remoteStreamConnection.attachVideoStream(this._video);
			References.debugPanel.debug("VideoChatDisplay: Starting remote playback stream "+this._remoteStreamName+"\"");
			this._remoteStreamConnection.playVideoStream(this._remoteStreamName);
		}//attachActiveStream
		
		private function createMask():void {
			if (this.displayMask!=null) {
				this.mask=this.displayMask;
			}//if
		}//createMask
		
		private function removeMask():void {			
			this.mask=null;
			if (this.displayMask!=null) {
				this.displayMask.visible=false;
				this.displayMask.alpha=0;
			}//if
		}//removeMask
		
		public function get displayType():String {
			return (this._displayType);
		}//get displayType
		
		public function createDisplay():void {
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
			this.displayMask.x=this._video.x;
			this.displayMask.y=this._video.y;
			this.displayMask.visible=false;
			this.addChild(this._video);			
			if (this._displayData.localName()=="local") {
				if (this._camera==null) {
					this._displayType="none";
					References.debugPanel.debug("VideoChatDisplay: No local camera defined for local display -- cannot create!");	
				} else {
					this._displayType="local";
					References.debugPanel.debug("VideoChatDisplay: Attaching "+this._camera.name+" to display.");
					this.attachActiveCamera(this._camera);
				}//else
			} else {
				if (this.remoteStreamName=="") {
					this._displayType="none";
					References.debugPanel.debug("VideoChatDisplay: No stream name supplied for remote stream -- cannot create!");
				} else {
					this._displayType="remote";
					References.debugPanel.debug("VideoChatDisplay: Attaching remote stream \""+this.remoteStreamName+"\" to display.");
					this.createRemoteSream(this.remoteStreamName);
				}//else
			}//else
		}//createDisplay
		
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
				var currentDisplay:VideoChatDisplay=_displays[count] as VideoChatDisplay;
				if ((currentDisplay.displayType==displayTypeString) || (displayTypeString=="all")) {
					_displays.splice(count, 1);
					currentDisplay.destroy();
					currentDisplay.parent.removeChild(currentDisplay);
				}//if
			}//for
			return (displayRemoved);
		}//removeAllDisplays
		
		public function destroy(... args):void {
			this.removeMask();
			SwagDispatcher.removeEventListener(SwagCloudEvent.GROUPCONNECT, this.onConnectRemoteStream, this._remoteStreamConnection);
			this.disconnectRemoteStream();
			if (this._video!=null) {
				if (this.contains(this._video)) {
					this.removeChild(this._video);
				}//if
				this._video.attachCamera(null);
			}//if
			this._video=null;
			this._camera=null;
		}//destroy
		
	}//VideoChatDisplay class
	
}//package