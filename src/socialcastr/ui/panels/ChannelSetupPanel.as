package socialcastr.ui.panels {
	
	import com.adobe.images.PNGEncoder;
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.utils.ByteArray;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.ui.input.MovieClipButton;
	import socialcastr.events.MovieClipButtonEvent;
	import socialcastr.events.TextInputEvent;
	import socialcastr.ui.Panel;
	import socialcastr.ui.PanelContent;
	import socialcastr.ui.components.Tooltip;
	import socialcastr.ui.input.TextInput;
	import socialcastr.ui.panels.NotificationPanel;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
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
	public class ChannelSetupPanel extends PanelContent {
		
		public var bottomImage:MovieClip;
		public var topImage:MovieClip;
		public var iconImage:MovieClip;
		public var helpButton:SimpleButton;
		
		private var _bottomBitmap:Bitmap=null;
		private var _topBitmap:Bitmap=null;
		private var _iconBitmap:Bitmap=null;
		
		public var channelName:TextField;
		public var channelDescription:TextField;
		public var acceptChannelNameButton:MovieClipButton;
		public var acceptDescriptionButton:MovieClipButton;
		
		private var _bgImageLoader:SwagLoader;
		private var _fgImageLoader:SwagLoader;
		private var _icnImageLoader:SwagLoader;
		
		public function ChannelSetupPanel(parentPanelRef:Panel) {
			super(parentPanelRef);
		}//constructor
			
		public function onChannelNameUpdate(eventObj:MovieClipButtonEvent):void {
			var channelNameNode:XML=Settings.verifyChildNode(this.panelData, "channelName");
			Settings.createChildTextNode(channelNameNode, this.channelName.text);
			this.acceptChannelNameButton.lockState("disabled");
			this.stage.focus=null;
			Settings.saveSettings();			
		}//onChannelNameUpdate
		
		public function onChannelDescriptionUpdate(eventObj:MovieClipButtonEvent):void {
			var channelNameNode:XML=Settings.verifyChildNode(this.panelData, "channelDescription");
			Settings.createChildTextNode(channelNameNode, this.channelDescription.text);
			this.acceptDescriptionButton.lockState("disabled");
			this.stage.focus=null;
			Settings.saveSettings();
		}//onChannelDescriptionUpdate
		
		private function onStartEditInputFields(eventObj:TextEvent):void {
			if (eventObj.target==this.channelName) {
				this.acceptChannelNameButton.releaseState();
			}//if
			if (eventObj.target==this.channelDescription) {
				this.acceptDescriptionButton.releaseState();
			}//if
		}//onStartEditInputFields
		
		private function updateChannelInfo():void {
			if (SwagDataTools.isXML(this.panelData.channelName)) {
				this.channelName.text=String(this.panelData.channelName[0].children().toString());
			}//if
			if (SwagDataTools.isXML(this.panelData.channelDescription)) {
				this.channelDescription.text=String(this.panelData.channelDescription[0].children().toString());
			}//if
			if (SwagDataTools.isXML(this.panelData.backgroundImage)) {
				var path:String=String(this.panelData.backgroundImage[0].children().toString());
				this.loadBackgroundImage(path);
			}//if
			if (SwagDataTools.isXML(this.panelData.foregroundImage)) {
				path=String(this.panelData.foregroundImage[0].children().toString());
				this.loadForegroundImage(path);
			}//if
			if (SwagDataTools.isXML(this.panelData.iconImage)) {
				path=String(this.panelData.iconImage[0].children().toString());
				this.loadIconImage(path);
			}//if			
		}//updateChannelInfo
		
		private function onHelpClick(eventObj:MouseEvent):void {
			References.panelManager.togglePanel("channel_setup_help", true);
		}//onHelpClick
		
		private function selectBackgroundImage(eventObj:MouseEvent):void {
			if (!SwagSystem.isAIR) {
				return;
			}//if			
			var filter:*=new References.FileFilter("Image  (*.jpg, *.png, *.gif)", "*.png;*.jpg;*.gif");
			var openFile:*=new References.File();
			openFile.addEventListener(Event.SELECT, this.onSelectBackgroundImage);
			openFile.browseForOpen("Select background image", [filter]);
		}//selectBackgroundImage
		
		private function onSelectBackgroundImage(eventObj:Event):void {
			var sourceFileRef:*=References.File(eventObj.target);
			var fileName:String="background_image."+SwagLoader.getFileExtension(sourceFileRef);
			var targetPath:String=Settings.getPanelFileLocation(this.panelID)+"/"+fileName;
			var targetFileRef:*=new References.File(targetPath);	
			sourceFileRef.copyTo(targetFileRef, true);			
			var fileNameNode:XML=Settings.verifyChildNode(this.panelData, "backgroundImage");
			Settings.createChildTextNode(fileNameNode, fileName);
			Settings.saveSettings();
			this.loadBackgroundImage(fileName); 
		}//onSelectBackgroundImage
		
		private function selectForegroundImage(eventObj:MouseEvent):void {
			if (!SwagSystem.isAIR) {
				return;
			}//if
			var filter:*=new References.FileFilter("Transparent Image (*.png, *.gif)", "*.png;*.gif");
			var openFile:*=new References.File();
			openFile.addEventListener(Event.SELECT, this.onSelectForegroundImage);
			openFile.browseForOpen("Select transparent foreground image", [filter]);
		}//selectForegroundImage
		
		
		private function onSelectForegroundImage(eventObj:Event):void {
			var sourceFileRef:*=References.File(eventObj.target);
			var fileName:String="foreground_image."+SwagLoader.getFileExtension(sourceFileRef);			
			var targetPath:String=Settings.getPanelFileLocation(this.panelID)+"/"+fileName;			
			var targetFileRef:*=new References.File(targetPath);	
			sourceFileRef.copyTo(targetFileRef, true);	
			var fileNameNode:XML=Settings.verifyChildNode(this.panelData, "foregroundImage");
			Settings.createChildTextNode(fileNameNode, fileName);
			Settings.saveSettings();
			this.loadForegroundImage(fileName);
		}//onSelectForegroundImage
			
		
		private function selectIconImage(eventObj:MouseEvent):void {
			if (!SwagSystem.isAIR) {
				return;
			}//if			
			var filter:*=new References.FileFilter("Image  (*.jpg, *.png, *.gif)", "*.png;*.jpg;*.gif");
			var openFile:*=new References.File();
			openFile.addEventListener(Event.SELECT, this.onSelectIconImage);
			openFile.browseForOpen("Select icon image (100 x 100 pixels)", [filter]);
		}//selectIconImage
		
		private function onSelectIconImage(eventObj:Event):void {
			var sourceFileRef:*=References.File(eventObj.target);
			var fileName:String="channel_icon."+SwagLoader.getFileExtension(sourceFileRef);			
			var targetPath:String=Settings.getPanelFileLocation(this.panelID)+"/"+fileName;
			var targetShortPath:String=this.panelID+"/"+fileName;
			try {
				var targetFileRef:*=References.File.applicationStorageDirectory.resolvePath(targetShortPath);
				var fileStream:*=new References.FileStream();
				fileStream.open(sourceFileRef, References.FileMode.READ);
				var imageData:ByteArray=new ByteArray();
				fileStream.readBytes(imageData);
				fileStream.close();
				SwagDataTools.byteArrayToDisplayObject(imageData, this.onLoadedIconSelection);		
			} catch (e:*) {
				var notificationPanel:Panel=References.panelManager.togglePanel("notification", false) as Panel;
				NotificationPanel(notificationPanel.content).updateMessageText("That doesn't seem to be a valid image file!");
				References.debug("ChannelSetupPanel: Problem loading icon image -- "+e.toString());
			}//catch
		}//onSelectIconImage
		
		private function onLoadedIconSelection(eventObj:Event):void {	
			References.debug("ChannelSetupPanel.onLoadedIconSelection -- "+eventObj.toString());	
			if (this.iconImage!=null) {
				if (this._iconBitmap!=null) {
					if (this.iconImage.contains(this._iconBitmap)) {
						this.iconImage.removeChild(this._iconBitmap);
					}//if
				}//if
			}//if
			this._iconBitmap=null;
			this._iconBitmap=Bitmap(eventObj.target.content);
			var fileName:String="channel_icon.png";
			References.debug("ChannelSetupPanel: Loaded icon dimensions: "+this._iconBitmap.bitmapData.width+"x"+this._iconBitmap.bitmapData.height+" pixels");
			if ((this._iconBitmap.bitmapData.width!=100) || (this._iconBitmap.bitmapData.height!=100)) {
				var originalWidth:Number=this._iconBitmap.width;
				var originalHeight:Number=this._iconBitmap.height;
				this._iconBitmap=Bitmap(SwagDataTools.sizeWithAspectRatio(this._iconBitmap, 100, 100, true));
				References.debug("ChannelSetupPanel: Icon sized to "+this._iconBitmap.bitmapData.width+"x"+this._iconBitmap.bitmapData.height+" pixels");
				var notificationPanel:Panel=References.panelManager.togglePanel("notification", false) as Panel;
				var notification:String="The image was re-sized to fit into a 100x100 pixel constraint. It's now ";
				notification+=String(this._iconBitmap.bitmapData.width)+"x"+String(this._iconBitmap.bitmapData.height)+" pixels.";
				NotificationPanel(notificationPanel.content).updateMessageText(notification);
			}//if
			var PNGData:ByteArray=PNGEncoder.encode(this._iconBitmap.bitmapData);				
			References.debug("ChannelSetupPanel: About to save (\""+this.panelID+"\", \""+fileName+"\", [PNG IMAGE DATA] "+PNGData.length+" bytes)");
			Settings.savePanelDataFile(this.panelID, fileName, PNGData);
			var fileNameNode:XML=Settings.verifyChildNode(this.panelData, "iconImage");
			var iconFileName:String=Settings.getPanelDataByID("channel_setup", "iconImage", String);			
			Settings.createChildTextNode(fileNameNode, fileName);
			Settings.saveSettings();
			this.loadIconImage(fileName);
		}//onLoadedIconSelection
		
		private function loadBackgroundImage(fileName:String):void {
			if (this._bottomBitmap!=null) {
				this.bottomImage.removeChild(this._bottomBitmap);
			}//if
			var fullPath:String=Settings.getPanelFileLocation(this.panelID)+"/"+fileName;
			References.debugPanel.debug("ChannelSetupPanel: Loading background image \""+fullPath+"\"");
			this.topImage.background.alpha=1;
			this._bgImageLoader=new SwagLoader();
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onLoadBackgroundImage, this._bgImageLoader);
			SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, this.onLoadBackgroundImage, this, this._bgImageLoader);	
			this._bgImageLoader.load(fullPath, Bitmap, SwagLoader.LOCALTRANSPORT);
		}//loadBackgroundImage
		
		public function onLoadBackgroundImage(eventObj:SwagLoaderEvent):void {		
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onLoadBackgroundImage, this._bgImageLoader);
			if (this._bgImageLoader.loadedData!=null) {			
				this.bottomImage.background.alpha=0;
				this._bottomBitmap=this._bgImageLoader.loadedData;
				SwagDataTools.sizeWithAspectRatio(this._bottomBitmap, this.bottomImage.background.width, this.bottomImage.background.height);
				this.bottomImage.addChild(this._bottomBitmap);
			}//if			
			this._bgImageLoader=null;
		}//onLoadBackgroundImage
		
		private function loadForegroundImage(fileName:String):void {
			if (this._topBitmap!=null) {
				this.topImage.removeChild(this._topBitmap);
			}//if			
			this.topImage.background.visible=true;
			var fullPath:String=Settings.getPanelFileLocation(this.panelID)+"/"+fileName;
			References.debugPanel.debug("ChannelSetupPanel: Loading foreground image \""+fullPath+"\"");
			this._fgImageLoader=new SwagLoader();
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onLoadForegroundImage, this._fgImageLoader);
			SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, this.onLoadForegroundImage, this, this._fgImageLoader);
			this._fgImageLoader.load(fullPath, Bitmap, SwagLoader.LOCALTRANSPORT);
		}//loadForegroundImage
		
		public function onLoadForegroundImage(eventObj:SwagLoaderEvent):void {			
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onLoadForegroundImage, this._fgImageLoader);
			if (this._fgImageLoader.loadedData!=null) {
				this.topImage.background.alpha=0;
				this._topBitmap=this._fgImageLoader.loadedData;
				if ((this._topBitmap.width>this.topImage.width) || (this._topBitmap.height>this.topImage.height)) {
					SwagDataTools.sizeWithAspectRatio(this._fgImageLoader.loadedData, this.topImage.width, this.topImage.height);
				}//if
				this.topImage.addChild(this._fgImageLoader.loadedData);
			}//if		
			this._fgImageLoader=null;
		}//onLoadForegroundImage
		
		private function loadIconImage(fileName:String="channel_icon.png"):void {
			if (this.iconImage!=null) {
				if (this._iconBitmap!=null) {
					if (this.iconImage.contains(this._iconBitmap)) {
						this.iconImage.removeChild(this._iconBitmap);
					}//if
				}//if
			}//if
			this._iconBitmap=null;
			this.iconImage.background.visible=true;
			var fullPath:String=Settings.getPanelFileLocation(this.panelID)+"/"+fileName;
			References.debugPanel.debug("ChannelSetupPanel: Loading icon image \""+fullPath+"\"");
			this._icnImageLoader=new SwagLoader();
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onLoadIconImage, this._icnImageLoader);
			SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, this.onLoadIconImage, this, this._icnImageLoader);
			this._icnImageLoader.load(fullPath, Bitmap, SwagLoader.LOCALTRANSPORT);
		}//loadIconImage		
		
		public function onLoadIconImage(eventObj:SwagLoaderEvent):void {			
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, this.onLoadForegroundImage, this._icnImageLoader);
			if (this._icnImageLoader.loadedData!=null) {
				References.debugPanel.debug("ChannelSetupPanel: Icon image loaded.");
				this.iconImage.background.alpha=0;
				this._iconBitmap=this._icnImageLoader.loadedData;
				this.iconImage.addChild(this._iconBitmap);				
			} else {
				References.debugPanel.debug("ChannelSetupPanel: Icon image file doesn't exist.");
			}//else
			this._icnImageLoader=null;
		}//onLoadIconImage
		
		private function addListeners():void {
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onChannelNameUpdate, this, this.acceptChannelNameButton);
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onChannelDescriptionUpdate, this, this.acceptDescriptionButton);
			this.channelName.addEventListener(TextEvent.TEXT_INPUT, this.onStartEditInputFields);
			this.channelDescription.addEventListener(TextEvent.TEXT_INPUT, this.onStartEditInputFields);
			this.iconImage.addEventListener(MouseEvent.CLICK, this.selectIconImage);
			var iconTop:Tooltip=new Tooltip(this.iconImage, "Click here to update the icon for your channel (100 x 100 pixels!)");
			this.bottomImage.addEventListener(MouseEvent.CLICK, this.selectBackgroundImage);
			var bottomImageTip:Tooltip=new Tooltip(this.bottomImage, "Click here to update the image that will appear beneath the video");
			this.topImage.addEventListener(MouseEvent.CLICK, this.selectForegroundImage);
			var topImageTip:Tooltip=new Tooltip(this.topImage, "Click here to update the image that will appear above the video");
			this.helpButton.addEventListener(MouseEvent.CLICK, this.onHelpClick);
			this.iconImage.useHandCursor=true;
			this.iconImage.buttonMode=true;
			this.bottomImage.useHandCursor=true;
			this.bottomImage.buttonMode=true;
			this.topImage.useHandCursor=true;
			this.topImage.buttonMode=true;
		}//addListeners
		
		private function removeListeners():void {
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onChannelNameUpdate, this.acceptChannelNameButton);
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onChannelDescriptionUpdate, this.acceptDescriptionButton);
			this.channelName.removeEventListener(TextEvent.TEXT_INPUT, this.onStartEditInputFields);
			this.channelDescription.removeEventListener(TextEvent.TEXT_INPUT, this.onStartEditInputFields);
			this.bottomImage.removeEventListener(MouseEvent.CLICK, this.selectBackgroundImage);
			this.topImage.removeEventListener(MouseEvent.CLICK, this.selectForegroundImage);
			this.iconImage.removeEventListener(MouseEvent.CLICK, this.selectIconImage);
			this.bottomImage.useHandCursor=false;
			this.bottomImage.buttonMode=false;
			this.topImage.useHandCursor=false;
			this.topImage.buttonMode=false;
			this.iconImage.useHandCursor=true;
			this.iconImage.buttonMode=true;
		}//removeListeners
		
		override public function initialize():void {
			this.addListeners();
			this.updateChannelInfo();
			this.acceptDescriptionButton.lockState("disabled");
			this.acceptChannelNameButton.lockState("disabled");
		}//initialize
		
	}//ChannelSetupPanel class
	
}//package