package socialcastr.ui.panels {
	
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
	
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.text.TextField;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.interfaces.ui.IPanel;
	import socialcastr.interfaces.ui.IPanelContent;
	import socialcastr.ui.Panel;
	import socialcastr.ui.PanelContent;
	import socialcastr.ui.panels.NotificationPanel;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.events.SwagErrorEvent;
	
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
	public class BroadcastSetupPanel extends PanelContent implements IPanelContent {
				
		//The value set in the <cam0> settings data if the source chosen was a file and not a camera (otherwise
		//the <cam0> value is the camera index).
		private const fileSourceDesignator:String="_file_";
		private static const defaultBitRate:int=2000000;
		private static const defaultquality:int=75;
		
		public var videoSourceDropdown:ComboBox;
		public var resolutionDropdown:ComboBox;
		public var FPSDropdown:ComboBox;
		public var audioSourceDropdown:ComboBox;
		public var reliableAudioCB:CheckBox;
		public var reliableVideoCB:CheckBox;
		public var loopVideoCB:CheckBox;
		
		public var bitRateField:TextField;
		public var qualiltyField:TextField;
		
		public function BroadcastSetupPanel(parentPanelRef:Panel) {			
			super(parentPanelRef);
		}//constructor
		
		private function onVideoSourceSelect(eventObj:Event):void {			
			if (this.videoSourceDropdown.selectedIndex==this.videoSourceDropdown.length-1) {
				Settings.setBroadcastSetting("cam0", this.fileSourceDesignator);
				this.resolutionDropdown.enabled=false;
				this.FPSDropdown.enabled=false;
				this.selectStreamFile();
			} else {
				Settings.setBroadcastSetting("cam0", this.videoSourceDropdown.selectedItem.data);
				this.resolutionDropdown.enabled=true;
				this.FPSDropdown.enabled=true;
				this.loopVideoCB.enabled=false;
				var count:int=this.videoSourceDropdown.length-1;
				var cameraItem:Object=this.videoSourceDropdown.getItemAt(count);				
				cameraItem.label=String(count+1)+". Select file...";
				cameraItem.data=String(count);	
				this.videoSourceDropdown.validateNow();
			}//else
			Settings.saveSettings();
			this.populateResolutionDropdown(true);
			this.populateFPSDropdown(true);
		}//onVideoSourceSelect
		
		private function selectStreamFile():void {
			if (!SwagSystem.isAIR) {
				return;
			}//if
			var filter:*=new References.FileFilter("FLV Video/Audio file  (*.flv)", "*.flv");
			var openFile:*=new References.File();
			openFile.addEventListener(Event.SELECT, this.onStreamFileSelect);
			openFile.browseForOpen("Select file to stream", [filter]);
		}//selectBackgroundImage
			
		private function onStreamFileSelect(eventObj:Event):void {
			var sourceFileRef:*=References.File(eventObj.target);
			var updatedListItem:Object=new Object();
			updatedListItem.label=sourceFileRef.nativePath;
			updatedListItem.data=sourceFileRef.url;
			this.videoSourceDropdown.replaceItemAt(updatedListItem, this.videoSourceDropdown.length-1);
			this.videoSourceDropdown.validateNow();		
			Settings.setBroadcastSetting("streamfile", sourceFileRef.url);
			this.loopVideoCB.enabled=true;
			Settings.saveSettings();
		}//onStreamFileSelect
		
		private function onAudioSourceSelect(eventObj:Event):void {			
			Settings.setBroadcastSetting("mic0", String(this.audioSourceDropdown.selectedIndex));	
			Settings.saveSettings();
		}//onAudioSourceSelect
		
		private function onFPSSelect(eventObj:Event):void {		
			Settings.setBroadcastSetting("camfps0", this.FPSDropdown.selectedItem.data);	
			Settings.saveSettings();
		}//onFPSSelect
		
		private function onResolutionSelect(eventObj:Event):void {
			Settings.setBroadcastSetting("camres0", this.resolutionDropdown.selectedItem.data);	
			Settings.saveSettings();
			this.populateFPSDropdown(true);
		}//onResolutionSelect		
		
		private function populateVideoDropdown():void {
			if (this.videoSourceDropdown==null) { 
				return;
			}//if
			var savedSelection:int=-1;
			for (var count:int=0; count<Camera.names.length; count++) {				
				var currentCamera:Camera=Camera.getCamera(String(count));
				if (currentCamera==null) {
					var newCameraItem:Object=new Object();
					newCameraItem.label=String(count+1)+". "+String(Camera.names[count])+" (in use)";					
					newCameraItem.data=null;
				} else {
					if ((currentCamera.index==int(Settings.getBroadcastSetting("cam0")))) {
						savedSelection=count;
					}//if
					newCameraItem=new Object();
					newCameraItem.label=String(count+1)+". "+currentCamera.name;
					newCameraItem.data=String(count);
					if (SwagSystem.isMobile) {
						newCameraItem.label+=" ["+currentCamera["position"]+"]";
					}//if					
				}//else
				this.videoSourceDropdown.dataProvider.addItem(newCameraItem);				
			}//for	
			if (Settings.getBroadcastSetting("cam0")==this.fileSourceDesignator) {
				var selectedFileName:String=Settings.getBroadcastSetting("streamfile");
				newCameraItem=new Object();
				newCameraItem.label=selectedFileName;
				newCameraItem.data=String(count);		
				this.videoSourceDropdown.dataProvider.addItem(newCameraItem);
				savedSelection=this.videoSourceDropdown.length-1;
				this.resolutionDropdown.enabled=false;
				this.FPSDropdown.enabled=false;
				this.loopVideoCB.enabled=true;
			} else {
				newCameraItem=new Object();
				newCameraItem.label=String(count+1)+". Select file...";
				newCameraItem.data=String(count);		
				this.videoSourceDropdown.dataProvider.addItem(newCameraItem);
				this.resolutionDropdown.enabled=true;
				this.FPSDropdown.enabled=true;
				this.loopVideoCB.enabled=false;
			}//else
			if (savedSelection>-1) {
				this.videoSourceDropdown.selectedIndex=savedSelection;
			} else {
				this.videoSourceDropdown.selectedIndex=this.videoSourceDropdown.length-1;
			}//else			
		}//populateVideoDropdown
		
		private function populateResolutionDropdown(reset:Boolean=false):void {			
			if (this.resolutionDropdown==null) { 				
				return;
			}//if
			if (this.videoSourceDropdown==null) { 				
				return;
			}//if			
			this.resolutionDropdown.removeAll();			
			var currentSourceIndex:String=String(this.videoSourceDropdown.selectedIndex);				
			var resList:Array=SwagSystem.getCameraResolutions(currentSourceIndex);
			if (resList==null) {
				return;
			};			
			var savedSelection:int=-1;
			var camResString:String=new String(Settings.getBroadcastSetting("camres0"));
			if (camResString!=null) {
				var splitString:Array=camResString.split("x");
				var selectedWidth:int=int(splitString[0] as String);
				var selectedHeight:int=int(splitString[1] as String);
			} else {
				selectedWidth=0;
				selectedHeight=0;
			}//else
			for (var count:int=0; count<resList.length; count++) {
				var currentRes:Object=resList[count];
				if ((currentRes.width==selectedWidth) && (currentRes.height==selectedHeight) && (!reset)) {
					savedSelection=count;
				}//if
				var newResItem:Object=new Object();
				newResItem.label=String(currentRes.width)+"x"+String(currentRes.height);
				newResItem.data=String(currentRes.width)+"x"+String(currentRes.height);
				this.resolutionDropdown.dataProvider.addItem(newResItem);
			}//for	
			if (savedSelection>-1) {
				this.resolutionDropdown.selectedIndex=savedSelection;
			} else {
				this.resolutionDropdown.selectedIndex=this.resolutionDropdown.length-1;
			}//else				
		}//populateResolutionDropdown
		
		private function populateFPSDropdown(reset:Boolean=false):void {			
			if (this.FPSDropdown==null) { 				
				return;
			}//if
			if (this.resolutionDropdown==null) { 				
				return;
			}//if
			this.FPSDropdown.removeAll();
			var resList:Array=SwagSystem.getCameraResolutions(String(this.videoSourceDropdown.selectedIndex));
			if (resList==null) {
				return;
			};
			var savedSelection:int=-1;
			var currentRes:Object=resList[this.resolutionDropdown.selectedIndex];
			if (currentRes==null) {
				return;
			}//if
			var maxFPS:Number=new Number(currentRes.fps);			
			this.FPSDropdown.dataProvider.addItem(createNewFPSListObject(0.1));
			if ((0.1==Number(Settings.getBroadcastSetting("camfps0"))) && (reset==false)) {
				savedSelection=int(0);
			}//if
			this.FPSDropdown.dataProvider.addItem(createNewFPSListObject(0.5));
			if ((0.5==Number(Settings.getBroadcastSetting("camfps0"))) && (reset==false)) {
				savedSelection=int(1);
			}//if
			for (var count:Number=1; count<=maxFPS; count++) {	
				if ((count==Number(Settings.getBroadcastSetting("camfps0"))) && (reset==false)) {
					savedSelection=int(String(count+2));
				}//if
				this.FPSDropdown.dataProvider.addItem(createNewFPSListObject(count));				
			}//for	
			if (savedSelection>-1) {
				this.FPSDropdown.selectedIndex=savedSelection;
			} else {
				this.FPSDropdown.selectedIndex=this.FPSDropdown.length-1;
			}//else	
		}//populateFPSDropdown
		
		private function createNewFPSListObject(FPS:Number):Object {
			var returnObj:Object=new Object();
			returnObj.label=String(FPS);
			returnObj.data=String(FPS);
			return (returnObj);
		}//createNewFPSListObject
		
		private function populateAudioDropdown():void {
			if (this.videoSourceDropdown==null) { 
				return;
			}//if
			var savedSelection:int=0;
			for (var count:int=0; count<Microphone.names.length; count++) {
				var currentMicrophone:Microphone=Microphone.getMicrophone(count);
				if (currentMicrophone!=null) {
					if (currentMicrophone.name==Settings.getBroadcastSetting("mic0")) {
						savedSelection=count;
					}//if
					var newMicrophoneItem:Object=new Object();
					newMicrophoneItem.label=String(count+1)+". "+currentMicrophone.name;
					newMicrophoneItem.data=currentMicrophone.name;									
					this.audioSourceDropdown.dataProvider.addItem(newMicrophoneItem);				
				}//if
			}//for			
			if (savedSelection>-1) {
				this.audioSourceDropdown.selectedIndex=savedSelection;
			} else {
				this.audioSourceDropdown.selectedIndex=this.audioSourceDropdown.length-1;
			}//else			
		}//populateAudioDropdown
		
		private function populateReliableVideoCB():void {	
			if (Settings.getBroadcastSetting("losslessVideo")=="true") {
				this.reliableVideoCB.selected=true;
			} else {
				this.reliableVideoCB.selected=false;
			}//else
		}//populateReliableVideoCB
		
		private function onReliableVideoCBToggle(eventObj:Event):void {
			if (this.reliableVideoCB.selected) {
				Settings.setBroadcastSetting("losslessVideo", "true");
			} else {
				Settings.setBroadcastSetting("losslessVideo", "false");
			}//else
			Settings.saveSettings();
		}//onReliableVideoCBToggle
		
		private function populateReliableAudioCB():void {			
			if (Settings.getBroadcastSetting("losslessVideo")=="true") {
				this.reliableAudioCB.selected=true;
			} else {
				this.reliableAudioCB.selected=false;
			}//else
		}//populateReliableAudioCB
		
		private function onReliableAudioCBToggle(eventObj:Event):void {
			if (this.reliableAudioCB.selected) {
				Settings.setBroadcastSetting("losslessAudio", "true");
			} else {
				Settings.setBroadcastSetting("losslessAudio", "false");
			}//else
			Settings.saveSettings();
		}//onReliableAudioCBToggle
		
		private function onLoopVideoCBToggle(eventObj:Event):void {
			if (this.loopVideoCB.selected) {
				Settings.setBroadcastSetting("loopVideoOnEnd", "true");
			} else {
				Settings.setBroadcastSetting("loopVideoOnEnd", "false");
			}//else
			Settings.saveSettings();
		}//onLoopVideoCBToggle
		
		private function populateLoopVideoCB():void {			
			if (Settings.getBroadcastSetting("loopVideoOnEnd")=="true") {
				this.loopVideoCB.selected=true;
			} else {
				this.loopVideoCB.selected=false;
			}//else
		}//populateLoopVideoCB
		
		private function populateStreamQualityFields():void {
			var bitRate:String=Settings.getBroadcastSetting("bitrate");
			bitRate=SwagDataTools.stripChars(bitRate, 
					SwagDataTools.LOWERCASE_RANGE+SwagDataTools.PUNCTUATION_RANGE+
					SwagDataTools.SEPARATOR_RANGE+SwagDataTools.UPPERCASE_RANGE);
			var quality:String=Settings.getBroadcastSetting("quality");
			quality=SwagDataTools.stripChars(quality, 
				SwagDataTools.LOWERCASE_RANGE+SwagDataTools.PUNCTUATION_RANGE+
				SwagDataTools.SEPARATOR_RANGE+SwagDataTools.UPPERCASE_RANGE);
			this.bitRateField.restrict="0-9";
			this.qualiltyField.restrict="0-9";
			if ((bitRate==null) || (bitRate=="")) {
				this.bitRateField.text=String(defaultBitRate);
			} else {
				this.bitRateField.text=bitRate;
			}//else
			if ((quality==null) || (quality=="")) {
				this.qualiltyField.text=String(defaultquality);
			} else {
				this.qualiltyField.text=quality;
			}//else
		}//populateStreamQualityFields
		
		private function validateStreamSettings():void {
			var bitRate:String=this.bitRateField.text;
			var quality:String=this.qualiltyField.text;
			if (int(bitRate)==0) {
				bitRate="1";
			}//if
			if (int(quality)==0) {
				quality="1";
			}//if
			if (int(quality)>100) {
				quality="100";
			}//if
			if ((bitRate==null) || (bitRate=="")) {
				this.bitRateField.text=String(defaultBitRate);
			} else {
				this.bitRateField.text=bitRate;
			}//else
			if ((quality==null) || (quality=="")) {
				this.qualiltyField.text=String(defaultquality);
			} else {
				this.qualiltyField.text=quality;
			}//else
		}//validateStreamSettings
		
		public static function get broadcastBitRate():int {
			var bitRate:String=Settings.getBroadcastSetting("bitrate");
			bitRate=SwagDataTools.stripChars(bitRate, 
				SwagDataTools.LOWERCASE_RANGE+SwagDataTools.PUNCTUATION_RANGE+
				SwagDataTools.SEPARATOR_RANGE+SwagDataTools.UPPERCASE_RANGE);
			if ((bitRate==null) || (bitRate=="")) {
				return (defaultBitRate);
			} else {
				return (int(bitRate));
			}//else
		}//get broadcastBitRate
		
		public static function get broadcastQuality():int {
			var quality:String=Settings.getBroadcastSetting("quality");
			quality=SwagDataTools.stripChars(quality, 
				SwagDataTools.LOWERCASE_RANGE+SwagDataTools.PUNCTUATION_RANGE+
				SwagDataTools.SEPARATOR_RANGE+SwagDataTools.UPPERCASE_RANGE);
			if ((quality==null) || (quality=="")) {
				return(defaultquality);
			} else {
				return (int(quality));
			}//else
		}//get broadcastQuality
		
		private function saveStreamQualitySettings(eventObj:FocusEvent):void {
			this.validateStreamSettings();
			Settings.setBroadcastSetting("bitrate", this.bitRateField.text);
			Settings.setBroadcastSetting("quality", this.qualiltyField.text);
			Settings.saveSettings();
		}//saveStreamQualitySettings
		
		private function addListeners():void {			
			this.audioSourceDropdown.addEventListener(Event.CHANGE, this.onAudioSourceSelect);
			this.videoSourceDropdown.addEventListener(Event.CHANGE, this.onVideoSourceSelect);
			this.FPSDropdown.addEventListener(Event.CHANGE, this.onFPSSelect);
			this.resolutionDropdown.addEventListener(Event.CHANGE, this.onResolutionSelect);
			this.reliableAudioCB.addEventListener(Event.CHANGE, this.onReliableAudioCBToggle);
			this.reliableVideoCB.addEventListener(Event.CHANGE, this.onReliableVideoCBToggle);
			this.loopVideoCB.addEventListener(Event.CHANGE, this.onLoopVideoCBToggle);	
			this.bitRateField.addEventListener(FocusEvent.FOCUS_OUT, this.saveStreamQualitySettings);
			this.qualiltyField.addEventListener(FocusEvent.FOCUS_OUT, this.saveStreamQualitySettings);
		}//addListeners
		
		private function removeListeners():void {
			this.audioSourceDropdown.removeEventListener(Event.CHANGE, this.onAudioSourceSelect);
			this.videoSourceDropdown.removeEventListener(Event.CHANGE, this.onVideoSourceSelect);
			this.FPSDropdown.removeEventListener(Event.CHANGE, this.onFPSSelect);
			this.resolutionDropdown.removeEventListener(Event.CHANGE, this.onResolutionSelect);
			this.reliableAudioCB.removeEventListener(Event.CHANGE, this.onReliableAudioCBToggle);
			this.reliableVideoCB.removeEventListener(Event.CHANGE, this.onReliableVideoCBToggle);
			this.loopVideoCB.removeEventListener(Event.CHANGE, this.onLoopVideoCBToggle);
			this.bitRateField.removeEventListener(FocusEvent.FOCUS_OUT, this.saveStreamQualitySettings);
			this.qualiltyField.removeEventListener(FocusEvent.FOCUS_OUT, this.saveStreamQualitySettings);
		}//removeListeners
		
		override public function initialize():void {					
			this.removeListeners();
			this.populateAudioDropdown();
			this.populateVideoDropdown();
			this.populateReliableAudioCB();
			this.populateReliableVideoCB();	
			this.populateLoopVideoCB();
			this.populateResolutionDropdown();
			this.populateFPSDropdown();
			this.populateStreamQualityFields();
			this.addListeners();
		}//initialize		
		
		
	}//BroadcastSetupPanel class
	
}//package
