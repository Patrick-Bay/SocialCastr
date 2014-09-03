package socialcastr.ui.components {
	
	import com.adobe.images.JPGEncoder;
	import com.adobe.images.PNGEncoder;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.events.MovieClipButtonEvent;
	import socialcastr.events.ProfileImageEvent;
	import socialcastr.interfaces.ui.components.IProfileImage;
	import socialcastr.ui.input.MovieClipButton;
	
	import swag.core.SwagDispatcher;
	import swag.core.instances.SwagLoader;
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
	
	public class ProfileImage extends MovieClip implements IProfileImage	{
				
		private var _profileImageLoader:Loader;
		private var _camera:Camera;
		private var _video:Video;
		private var _captureWidth, _captureHeight:int;
		private var _captureBitmapData:BitmapData;
		private var _captureBitmap:Bitmap;
		private var _JPGEncoder:JPGEncoder;
		private var _PNGEncoder:JPGEncoder;
		private var _loader:SwagLoader;
		private var _fileBrowser:FileReference;
		
		public var loadButton:MovieClipButton;
		public var webcamButton:MovieClipButton;
		public var imageMask:MovieClip;
		public var notificationText:TextField;
		public var profileImage:MovieClip;
		
		
		public function ProfileImage()	{			
			this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			super();
		}//constructor
		
		public function onLoadRollOver(eventObj:MovieClipButtonEvent):void {
			this.notificationText.text="LOAD EXISTING IMAGE";
		}//onLoadRollOver
		
		public function onCameraRollOver(eventObj:MovieClipButtonEvent):void {
			this.notificationText.text="SNAP WEBCAM IMAGE";
		}//onCameraRollOver
		
		public function onLoadRollOut(eventObj:MovieClipButtonEvent):void {
			this.notificationText.text="SET PROFILE IMAGE";
		}//onLoadRollOut
		
		public function onCameraRollOut(eventObj:MovieClipButtonEvent):void {
			this.notificationText.text="SET PROFILE IMAGE";
		}//onCameraRollOut
		
		public function onLoadClick(eventObj:MovieClipButtonEvent):void {
			this.mouseChildren=true;
			this.buttonMode=false;
			this.useHandCursor=false;
			this.removeListeners();
			this.removeEventListener(MouseEvent.MOUSE_OVER, this.onProfileImageRollOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT, this.onProfileImageRollOut);	
			this._fileBrowser=new FileReference();
			this._fileBrowser.addEventListener(Event.SELECT, this.onLoadSelect);
			this._fileBrowser.addEventListener(Event.CANCEL, this.onLoadCancel);
			var imageTypes:FileFilter=new FileFilter("Images (*.jpg, *.png, *.gif)", "*.jpg;*.png;*.gif");			
			this._fileBrowser.browse([imageTypes]);
			this.notificationText.text="SELECT FILE";
		}//onLoadClick
		
		private function onLoadCancel(eventObj:Event):void {
			this._fileBrowser=null;
			this.loadProfileImage();		
		}//onLoadCancel
		
		private function onLoadSelect(eventObj:Event):void {
			this._fileBrowser.removeEventListener(Event.SELECT, this.onLoadSelect);
			this._fileBrowser=eventObj.target as FileReference;
			References.debugPanel.debug("Loading file "+this._fileBrowser.name+" as profile image.");
			this._fileBrowser.addEventListener(Event.COMPLETE, this.onLoadImage);
			this._fileBrowser.load();			
		}//onLoadSelect
		
		private function onLoadImage(eventObj:Event):void {
			this._fileBrowser.removeEventListener(Event.COMPLETE, this.onLoadImage);
			References.debugPanel.debug("Saving profile image data to Local Shared Object with "+eventObj.target.data.length+" bytes.");
			Settings.saveToSharedObject(eventObj.target.data, "profile_image");
			this._fileBrowser=null;
			var event:ProfileImageEvent=new ProfileImageEvent(ProfileImageEvent.ONUPDATE);
			SwagDispatcher.dispatchEvent(event, this);
			this.loadProfileImage();
		}//onLoadImage
		
		public function onCameraClick(eventObj:MovieClipButtonEvent):void {			
			this.mouseChildren=true;
			this.buttonMode=false;
			this.useHandCursor=false;
			this.removeEventListener(MouseEvent.MOUSE_OVER, this.onProfileImageRollOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT, this.onProfileImageRollOut);	
			this.removeListeners();
			this.webcamButton.visible=false;
			this.loadButton.visible=false;
			this.notificationText.text="CLICK TO RECORD";
			this.createCaptureProfilemage();			
		}//onCameraClick
		
		public function createCaptureProfilemage():void {
			this._camera=Camera.getCamera();
			if (this._camera==null) {							
				References.debugPanel.debug("ProfileImage component is unable to find a camera for capture.");
				return;
			}//if			
			References.debugPanel.debug("ProfileImage is using camera "+this._camera.name+" for capture");
			this._video=new Video();
			this._captureWidth=this._camera.width*2;
			this._captureHeight=this._camera.height*2;
			this._camera.setLoopback(false);
			this._camera.setMode(this.width, this.height, 15, true);
			this._camera.setQuality(0, 100);
			this._video.attachCamera(this._camera);
			this.addChild(this._video);
			this._video.x=0;
			this._video.y=0;			
			this._video.width=this._camera.width;
			this._video.height=this._camera.height;
			this.swapChildren(this._video, this.notificationText);
			this.imageMask.useHandCursor=true;
			this.imageMask.buttonMode=true;
			this.imageMask.addEventListener(MouseEvent.CLICK, this.captureProfileImage);
		}//createCaptureProfilemage
		
		public function captureProfileImage(eventObj:MouseEvent):void {			
			this.imageMask.removeEventListener(MouseEvent.CLICK, this.captureProfileImage);
			this.imageMask.useHandCursor=false;
			this.imageMask.buttonMode=false;
			this._captureBitmapData=new BitmapData(this._captureWidth, this._captureHeight, false, 0xFFFFFF);
			this._captureBitmap=new Bitmap(this._captureBitmapData);
			this._captureBitmapData.draw(this._video);
			this._captureBitmap.width=this.width;
			this._captureBitmap.height=this.height;
			this._JPGEncoder=new JPGEncoder(85);
			var JPEGData:ByteArray=this._JPGEncoder.encode(this._captureBitmapData);
			References.debugPanel.debug("Storing profile image JPEG in Local Shared Object using "+JPEGData.length+" bytes.");
			Settings.saveToSharedObject(JPEGData, "profile_image");			
			this._video.attachCamera(null);
			this._camera=null;
			this.removeChild(this._video);
			this._video=null;		
			var event:ProfileImageEvent=new ProfileImageEvent(ProfileImageEvent.ONUPDATE);
			SwagDispatcher.dispatchEvent(event, this);
			this.loadProfileImage();
		}//captureProfileImage
		
		public function get profileImageData():ByteArray {
			var imageData:ByteArray=Settings.loadFromSharedObject("profile_image");
			return (imageData);
		}//get profileImageData
		
		private function onProfileImageRollOver(eventObj:MouseEvent):void {
			this.loadButton.visible=true;
			this.webcamButton.visible=true;
			this.notificationText.visible=true;
			this.notificationText.text="UPDATE PROFILE IMAGE";
		}//onProfileImageRollOver
		
		private function onProfileImageRollOut(eventObj:MouseEvent):void {
			this.loadButton.visible=false;
			this.webcamButton.visible=false;
			this.notificationText.text="";
			this.notificationText.visible=false;
		}//onProfileImageRollOut
		
		private function loadProfileImage():void {
			var imageData:ByteArray=Settings.loadFromSharedObject("profile_image");		
			if (this._profileImageLoader!=null) {
				this.profileImage.removeChild(this._profileImageLoader.content);
				this._profileImageLoader=null;				
			}//if
			this.loadButton.visible=false;
			this.webcamButton.visible=false;
			this.notificationText.text="";
			this.notificationText.visible=false;
			this.addListeners();
			if (imageData==null) {
				this.loadButton.visible=true;
				this.webcamButton.visible=true;
				this.notificationText.visible=true;
				this.notificationText.text="SET PROFILE IMAGE";
			} else {			
				this.useHandCursor=true;
				this.buttonMode=true;				
				this.mouseChildren=true;
				this.addEventListener(MouseEvent.MOUSE_OVER, this.onProfileImageRollOver);
				this.addEventListener(MouseEvent.MOUSE_OUT, this.onProfileImageRollOut);				
				this._profileImageLoader=new Loader();
				this._profileImageLoader.contentLoaderInfo.addEventListener(Event.INIT, this.onLoadProfileImage);
				this._profileImageLoader.loadBytes(imageData);								
			}//else
		}//loadProfileImage
		
		private function onLoadProfileImage(eventObj:Event):void {			
			this._profileImageLoader.contentLoaderInfo.removeEventListener(Event.INIT, this.onLoadProfileImage);
			this.profileImage.addChild(this._profileImageLoader.content);
			this.profileImage.width=this.imageMask.width;
			this.profileImage.height=this.imageMask.height;						
		}//onLoadProfileImage
		
		private function addMask():void {
			if (this.imageMask!=null) {
				this.mask=this.imageMask;
				//Compensate for glow filter...
				this.imageMask.width+=5;
				this.imageMask.height+=5;
				this.imageMask.x-=2.5;
				this.imageMask.y-=2.5;				
			}//if
		}//addMask
		
		private function removeMask():void {
			if (this.imageMask!=null) {
				this.mask=this.imageMask;
			}//if
		}//removeMask
		
		private function addListeners():void {
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONOVER, this.onLoadRollOver, this, this.loadButton);
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONOVER, this.onCameraRollOver, this, this.webcamButton);			
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONOUT, this.onLoadRollOut, this, this.loadButton);
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONOUT, this.onCameraRollOut, this, this.webcamButton);
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onLoadClick, this, this.loadButton);
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onCameraClick, this, this.webcamButton);
		}//addListeners
		
		private function removeListeners():void {
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONOVER, this.onLoadRollOver, this.loadButton);
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONOVER, this.onCameraRollOver, this.webcamButton);			
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONOUT, this.onLoadRollOut, this.loadButton);
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONOUT, this.onCameraRollOut,this.webcamButton);
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onLoadClick, this.loadButton);
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onCameraClick, this.webcamButton);
		}//removeListeners
		
		private function setDefaults(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			this.addMask();			
			this.loadButton.visible=false;
			this.webcamButton.visible=false;
			this.loadProfileImage();
		}//setDefaults
		
	}//ProfileImage class
	
}//package