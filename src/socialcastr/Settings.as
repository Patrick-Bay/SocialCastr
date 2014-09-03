package socialcastr {
	
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.net.SharedObject;
	import flash.net.SharedObjectFlushStatus;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import socialcastr.core.AnnounceChannel;
	import socialcastr.core.SCID;
	import socialcastr.core.Timeline;
	import socialcastr.core.TimelineElement;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.core.instances.SwagLoader;
	import swag.events.SwagErrorEvent;
	import swag.events.SwagLoaderEvent;
	import swag.network.SwagCloud;
	
	/**
	 * Holds application-wide settings in static variables or through accessible static methods.
	 * 
	 * Because the data in the class is intended to exist throughout the life of the application, it is required that all properties and
	 * methods found here are static and that all return or create default values as a final fallback. For this same reason no constructor 
	 * should ever be present.
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
	public class Settings {
		
		
		public static const defaultSharedObjectName:String="SOCIALCASTR_SO";
		public static const useTooltipsOnMobile:Boolean=false; //exactly as it says
		
		/**
		 * The parameter that defines the SCID to automatically play at startup.  
		 */
		public static const _defaultChannelParameter:String="play_scid";
		/**
		 * Defines the default ID (not class!), of the panel to use as the startup panel when the "play_scid" 
		 * is defined, but only if this is Receivr for Web. In all other instances it will be ignored. 
		 */
		public static var _defaultChannelPlayerPanelID:String=null;
		
		/**
		 * Used to load the settings XML data. 
		 */
		private static var _settingsLoader:SwagLoader;
		private static var _dataSaveLoader:SwagLoader;
		private static var _settingsSO:SharedObject;
		private static var _loaders:Vector.<Object>=new Vector.<Object>();
		/**
		 * Holds a copy of the <code>settingsFile</code> constant which may be changed if the load doesn't 
		 * successfully complete (fallback). 
		 */
		private static var _settingsFile:String;
		/**
		 * The fallback attempts counter and tracking variables used for load setup.
		 */
		private static var _fallbackAttempt:uint=0;
		private static var _usingSO:Boolean=false;
		private static var _usingAppStorage:Boolean=false;
		private static var _usingDefaults:Boolean=false;		
		
		public static var settingsData:XML=null;
		
		public static function get defaultSettingsFile():String {
			var settingsFilePath:String=new String("xml/settings.xml");
			//Conditional compiler statements, set through Publish Settings -> Flash -> ActionScript "Settings..."
			//This is used mostly to allow the same source files to host multiple apps.
			CONFIG::RECEIVR {
				settingsFilePath="xml/receivr/settings.xml";				
			}//CONFIG::RECEIVR			
			CONFIG::BROADCASTR {
				settingsFilePath="xml/broadcastr/settings.xml"				
			}//CONFIG::BROADCASTR
			return (settingsFilePath);
		}//get defaultSettingsFile
		
		public static function loadSettings(useSharedObject:Boolean=false, useAppStorage:Boolean=true, loadDefaults:Boolean=false):void {
			References.debug  ("Settings.loadSettings("+useSharedObject+", "+useAppStorage+", "+loadDefaults+");");
			if (loadDefaults) {
				References.debug  ("   Settings.loadSettings: Loading installation data. Application will be reset with defaults.");
			}//if			
			_usingSO=useSharedObject;
			_usingAppStorage=useAppStorage;
			_usingDefaults=loadDefaults;
			if (useSharedObject) {
				References.debug  ("   Settings.loadSettings: Loading from Local Shared Object...");
				_settingsSO=SharedObject.getLocal(defaultSharedObjectName);				
				if (_settingsSO.data.settingsXML!=null) {
					settingsData=new XML(String(_settingsSO.data.settingsXML));
					_settingsFile="{L.S.O.}";
					_usingSO=true;
					_usingAppStorage=false;
					_usingDefaults=false;
					References.main.startApplication();
					return;
				} else {
					//Couldn't use shared object, try app storage...
					useAppStorage=true;
					loadDefaults=false;
				}//else
			}//if
			if ((useAppStorage) && (SwagSystem.isAIR)) {
				References.debug  ("   Settings.loadSettings: Loading from app storage...");
				if (_settingsLoader!=null) {
					SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onLoadSettings, _settingsLoader);
					SwagDispatcher.removeEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, onLoadSettingsError, _settingsLoader);
					_settingsLoader=null;
				}//if
				if (_fallbackAttempt==0) {
					_settingsFile=SwagLoader.resolveToAppStorage(_settingsFile).url;					
				}//if
				if (_fallbackAttempt==1) {				
					_settingsFile=SwagDataTools.getStringAfter(_settingsFile, "/", false);								
				}//if
				if (_fallbackAttempt==2) {				
					_settingsFile="/"+_settingsFile;						
				}//if				
				if (_fallbackAttempt==3) {					
					//App storage failed, try default location...	
					_fallbackAttempt=0;
					_settingsFile=defaultSettingsFile;
				 	loadSettings(false, false, true);
					return;
				}//if
				_settingsLoader=new SwagLoader();			
				SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, onLoadSettings, Settings, _settingsLoader);			
				SwagDispatcher.addEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, onLoadSettingsError, Settings, _settingsLoader);				
				if (!_settingsLoader.load(_settingsFile, XML)) {
					_fallbackAttempt++;
					loadSettings(false, false, false);
				}//if
				return;
			} else {
				//App storage not available, try default location...				
				loadDefaults=true;	
			}//else
			if (loadDefaults) {
				References.debug  ("   Settings.loadSettings: Loading from default (installation) location...");
				if (_settingsLoader!=null) {
					SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onLoadSettings, _settingsLoader);
					SwagDispatcher.removeEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, onLoadSettingsError, _settingsLoader);
					_settingsLoader=null;
				}//if
				if (_fallbackAttempt==1) {				
					_settingsFile=SwagDataTools.getStringAfter(_settingsFile, "/", false);							
				}//if
				if (_fallbackAttempt==2) {				
					_settingsFile="/"+_settingsFile;					
				}//if				
				if (_fallbackAttempt==3) {
					References.debug  ("   Settings.loadSettings: All fallback load attempts have failed and the settings.xml file couldn't be loaded. Application is stopped!");
					return;
				}//if
				_settingsLoader=new SwagLoader();			
				SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, onLoadSettings, Settings, _settingsLoader);			
				SwagDispatcher.addEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, onLoadSettingsError, Settings, _settingsLoader);				
				if (!_settingsLoader.load(_settingsFile, XML)) {
					_fallbackAttempt++;
					loadSettings(false, false, true);
				}//if
				return;
			}//if
		}//loadSettings
		
		/**
		 * @return A named array of objects containing name value pairs passed to the application running in a web browser.  
		 * The function detects paremeters in the following sequence: via the URL of the enclosing web page, via embedding parameters, 
		 * and finally through loaded XML settings (in the <parameters> node). If all fail, or if web parameters are not available 
		 * (because this is a desktop application, for example), <em>null</em> is returned. In all cases, the naming conventions for parameters
		 * must be assumed to be identical (both when reading and generating).
		 */
		public static function get webParameters():Array {
			if (SwagSystem.isWeb==false) {
				return (null);
			}//if			
			if (ExternalInterface.available) {				
				var returnParams:Array=new Array();
				//Attempt 1 - Query the browser DOM for parameters:
				try {
					//document.URL is the W3C standard and seems to be the most reliable across all browsers. 
					var urlString:String=new String(ExternalInterface.call("function() { return (document.URL); }"));
					if ((urlString!=null) && (urlString!="")) {
						//Try to parse variables our of URL.
						var paramString=SwagDataTools.getStringAfter(urlString, "?");
						if (paramString=="") {
							//It might just be a pure URL-encoded string already
							paramString=urlString;
						}//if
						if ((paramString!=null) && (paramString!="")) {
							var urlVars:URLVariables=new URLVariables(paramString);
							for (var item:String in urlVars) {
								returnParams[item]=urlVars[item];				
							}//for
							return (returnParams);
						}//if
					}//if
				} catch (e:*) {}//catch						
				//Attempt 2 - Query the <parameters> node of the loaded XML data:
				try {
					if (SwagDataTools.isXML(settingsData)) {
						//XML structure is:
						//<parameter name="name" value="value" />
						if (SwagDataTools.isXML(settingsData.parameters)) {						
							var parameterNodes:XMLList=settingsData.parameters[0].children();
							for (var count:uint=0; count<parameterNodes.length(); count++) {
								var currentNode:XML=parameterNodes[count] as XML;
								var parameterName:String=String(currentNode.@name);
								var parameterValue:String=new String(currentNode.@value);
								returnParams[parameterName]=parameterValue;
							}//for							
							return (returnParams);
						}//if					
					}//if
				} catch (e:*) {}//catch
				//Attempt 3 - Query the Flash object embedding parameters:		
				try {
					if (References.main!=null) {
						var params:Object=References.main.stage.loaderInfo.parameters;
						for (item in params) {
							returnParams[item]=params[item];
						}//for
						return (returnParams);
					}//if
				} catch (e:*) {}//catch
				//Nothing got generated meaning no parameters were passed. Return an empty array.
				return (returnParams);
			}//if
			return (null);
		}//get webParameters
		
		public static function getWebParameter(paramName:String, stripOutsideSpaces:Boolean=false, lowerCase:Boolean=false):String {
			if ((paramName==null) || (paramName=="")) {
				return (null);
			}//if
			var wpArray:Array=webParameters;
			if (wpArray==null) {
				return (null);
			}//if
			var paramString:String=SwagDataTools.stripOutsideChars(paramName," ");
			for (var item:String in wpArray) {			
				var itemString:String=SwagDataTools.stripOutsideChars(item," ");
				if (paramString==itemString) {
					var returnString:String=new String();
					returnString=wpArray[item] as String;
					if (stripOutsideSpaces) {
						returnString=SwagDataTools.stripOutsideChars(returnString, " ");
					}//if
					if (lowerCase) {
						returnString=returnString.toLowerCase();
					}//if
					return (returnString);
				}//if
			}//for
			return (null);
		}//getWebParameter
		
		public static function resetSettings():void {
			References.debug("Settings: Resetting settings...");
			if (_settingsLoader!=null) {
				SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onLoadSettings, _settingsLoader);
				SwagDispatcher.removeEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, onLoadSettingsError, _settingsLoader);
				_settingsLoader=null;
			}//if
			resetWindowLocation();
			_settingsLoader=new SwagLoader();
			SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, onResetLoadSettings, Settings, _settingsLoader);			
			SwagDispatcher.addEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, onResetLoadSettingsError, Settings, _settingsLoader);
			_settingsFile=defaultSettingsFile;
			_settingsLoader.load(_settingsFile, XML);
		}//resetSettings
		
		public static function saveSettings():void {			
			References.debugPanel.debug("Settings.saveSettings: Saving settings data...");
			if ((SwagSystem.isAIR) && (_usingSO==false)) {
				_settingsLoader=new SwagLoader();
				SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, onSaveSettings, Settings, _settingsLoader);
				References.debugPanel.debug("   Settings.saveSettings: Saving to local storage file: "+SwagLoader.resolveToAppStorage(_settingsFile).nativePath);
				_settingsLoader.send(SwagLoader.resolveToAppStorage(_settingsFile), settingsData, SwagLoader.LOCALTRANSPORT);
			} else {				
				_settingsSO=SharedObject.getLocal(defaultSharedObjectName);	
				References.debugPanel.debug("   Settings.saveSettings: Saving to Local Shared Object.");				
				_settingsSO.data.settingsXML=settingsData;				
				_settingsSO.flush();				
			}//else			
		}//saveSettings
		
		public static function saveToSharedObject(data:*, variableName:String=null, SOName:String=defaultSharedObjectName):void {
			if ((variableName==null) || (variableName=="")) {
				return;
			}//if
			if (variableName=="settingsXML") {
				//This one is reserved!
				return;
			}//if			
			_settingsSO=SharedObject.getLocal(SOName);				
			_settingsSO.data[variableName]=data;
			_settingsSO.flush();				
		}//saveToSharedObject
		
		public static function loadFromSharedObject(variableName:String=null, SOName:String=defaultSharedObjectName):* {
			if ((variableName==null) || (variableName=="")) {
				return (null);
			}//if			
			_settingsSO=SharedObject.getLocal(SOName);				
			return (_settingsSO.data[variableName]);			
		}//loadFromSharedObject
		
		public static function onSaveSettings(eventObj:SwagLoaderEvent):void {
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onSaveSettings, _settingsLoader);
		}//onSaveSettings
		
		public static function set settingsFile(fileSet:String):void {
			_settingsFile=fileSet;
		}//set settingsFile
		
		public static function get settingsFile():String {
			return(_settingsFile);
		}//get settingsFile
		
		/**
		 * @return A <code>XMLList</code> of all of the child nodes of the broadcast setup panel's <settings> node,
		 * or <em>null</em> if none can be found. An empty <settings> node is created if one doesn't exist and the appropriate panel
		 * definition exists.
		 */
		public static function get broadcastSettings():XMLList {
			var broadcastSetupNode:XML=getPanelDefinitionByID("broadcast_setup", true); //Should be only one!
			if (broadcastSetupNode==null) {
				return (null);
			}//if
			if (SwagDataTools.isXML(broadcastSetupNode.settings)) {
				var settingsNode:XML=broadcastSetupNode.settings[0] as XML;
				return (settingsNode.children());
			} else {
				verifyChildNode(settingsNode, "settings");
			}//else
			return (null);
		}//get broadcastSettings
		
		/**
		 * Gets a specific broadcast setting from the broadcast setup panel data, or <em>null</em> if no such
		 * setting can be found. This is intended to allow other panels to share the data of the broadcast setup panel.
		 *  
		 * @param settingName The setting name (child node name within the broadcast setup panel's <settings> node) to retrieve. If
		 * multiple setting nodes exist with the same name, only the first one is used.		 
		 * 
		 * @return The contents of the requested setting, returned as a <code>String</code>, or <em>null</em> if no such
		 * setting can be found. 
		 */
		public static function getBroadcastSetting(settingName:String):String {
			if ((settingName==null) || (settingName=="")) {
				return (null);
			}//if
			var settingsList:XMLList=broadcastSettings;
			if (settingsList==null) {
				return (null);
			}//if			
			for (var count:uint=0; count<settingsList.length(); count++) {
				var currentSetting:XML=settingsList[count] as XML;
				if (String(currentSetting.localName())==settingName) {
					var returnString:String=new String();
					returnString=currentSetting.children().toString();
					return (returnString);
				}//if
			}//for
			return (null);
		}//getBroadcastSetting
		
		/**
		 * Sets a specific broadcast setting in the broadcast setup panel data. If no such setting exists, it is created. If
		 * the broadcast setup panel data doesn't exist, nothing will be stored and <em>false</em> will be returned.
		 *  
		 * @param settingName The setting name (child node name within the broadcast setup panel's <settings> node) to set or create. If
		 * multiple nodes of the same name exist, the fist one will be updated.
		 * @param content The content to assign to the child node of the broadcast setup panel's <settings> node.
		 * 
		 * @return <em>True</em> if the setting was properly updated or created, <em>false</em> if it coulnd't be (usually
		 * do to an absent broadcast setup panel definition node in the panel definitions). 
		 */
		public static function setBroadcastSetting(settingName:String, content:String):Boolean {			
			if ((settingName==null) || (settingName=="")) {
				return (false);
			}//if
			var settingsList:XMLList=broadcastSettings;
			if (settingsList==null) {
				return (false);
			}//if						
			for (var count:uint=0; count<settingsList.length(); count++) {
				var currentSetting:XML=settingsList[count] as XML;				
				if (String(currentSetting.localName())==settingName) {					
					createChildTextNode(currentSetting, content);					
					return (true);
				}//if
			}//for			
			createChildTextNode(verifyChildNode(settingsList.parent(), settingName), content);
			return (true);
		}//setBroadcastSetting
		
		public static function onLoadSettings(eventObj:SwagLoaderEvent):void {
			References.debug ("Settings.onLoadSettings()");
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onLoadSettings, _settingsLoader);	
			SwagDispatcher.removeEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, onLoadSettingsError, _settingsLoader);
			settingsData=new XML(eventObj.source.loadedBinaryData.toString());
			setEmulation(defaultEmulationProfile);
			References.main.startApplication();
		}//onLoadSettings
		
		public static function onResetLoadSettings(eventObj:SwagLoaderEvent):void {
			saveSettings();
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onResetLoadSettings, _settingsLoader);	
			SwagDispatcher.removeEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, onResetLoadSettingsError, _settingsLoader);
			References.main.destroy();
		}//onResetLoadSettings		
		
		public static function onLoadSettingsError(eventObj:SwagErrorEvent):void {
			References.debug  ("Settings.onLoadSettingsError: ["+String(eventObj.code)+"] "+eventObj.description);
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onLoadSettings, _settingsLoader);	
			SwagDispatcher.removeEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, onLoadSettingsError, _settingsLoader);
			_fallbackAttempt++;
			loadSettings(_usingSO,_usingAppStorage, _usingDefaults);
		}//onLoadSettingsError
		
		public static function onResetLoadSettingsError(eventObj:SwagErrorEvent):void {
			References.debug  ("Settings.onResetLoadSettingsError: ["+String(eventObj.code)+"] "+eventObj.description);
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onResetLoadSettings, _settingsLoader);	
			SwagDispatcher.removeEventListener(SwagErrorEvent.FAILEDOPERATIONERROR, onResetLoadSettingsError, _settingsLoader);
		}//onResetLoadSettingsError
		
		/**
		 * Verifies that a child node of the specified parent node exists, creating it if it doesn't. 
		 * 
		 * @param parentNode The parent node within which the target node should exist.
		 * @param nodeName The node name to find or create if it doesn't exist.
		 * 
		 * @return A newly created XML node with the specified name, or a reference to
		 * the first existing node with that name if one already exists. 
		 * 
		 */
		public static function verifyChildNode(parentNode:XML, nodeName:String):XML {
			if (!SwagDataTools.isXML(parentNode.child(nodeName))) {
				var newNode:XML=new XML("<"+nodeName+" />");
				parentNode.appendChild(newNode);
			}//if
			return (parentNode.child(nodeName)[0] as XML);		
		}//verifyChildNode
		
		/**
		 * Creates a child text node of the specified parent node if none exists. If the specified parent node already 
		 * has a text child node, it is replace with the new text.
		 * 
		 * @param parentNode The parent node under which to create the new text node.
		 * @param textContent The text to assign to the node. This will be created as a CDATA section in order
		 * to preserve any formatting that may be present.
		 * 		 
		 * 
		 */
		public static function createChildTextNode(parentNode:XML, textContent:String):void {
			if (!SwagDataTools.isXML(parentNode)) {
				return;
			}//if
			var textNode:XML=new XML("<![CDATA["+textContent+"]]>");
			parentNode.setChildren(textNode);
		}//createChildTextNode
			
		
		/**
		 * Saves data to the application storage directory within a folder that matches the panel ID. This is
		 * used to safely segregate data saved by various panels with differing functionality.
		 * 
		 * @param panelName
		 * @param fileName
		 * @param data
		 * @return 
		 * 
		 */
		public static function savePanelDataFile(panelID:String, fileName:String, data:*):SwagLoader {
			if (SwagSystem.isAIR==false) {
				return (null);
			}//if	
			var path:String=getPanelFileLocation(panelID)+"/"+fileName;
			_dataSaveLoader=new SwagLoader();
			SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, onSavePanelDataFile, Settings, _dataSaveLoader);
			References.debugPanel.debug("Saving file for panel \""+panelID+"\": "+path);
			_dataSaveLoader.send(path, data, SwagLoader.LOCALTRANSPORT);
			return (_dataSaveLoader);
		}//savePanelDataFile
		
		/**
		 * Loads a file from a specific panel ID directory.
		 * 
		 * @param panelID The panel ID (on disk stored as a folder) in which the file is stored.
		 * @param fileName The file name to load.
		 * @param onLoad The method to invoke when the load is complete. A <code>SwagLoader</code> event will be
		 * included as the first parameter (as though called directly from the <code>SwagLoader</code> instance. Loaded data is 
		 * returned in a <code>ByteArray</code> object by default.
		 * 
		 * @return The <code>SwagLoader</code> instance being used for the load.
		 * 
		 */
		public static function loadPanelDataFile(panelID:String, fileName:String, onLoad:Function):SwagLoader {			
			var fullPath:String=getPanelFileLocation(panelID)+"/"+fileName;			
			var itemLoader:SwagLoader=new SwagLoader();
			var loadInfo:Object=new Object();
			loadInfo.loader=itemLoader;
			loadInfo.onLoad=onLoad;
			if (_loaders==null) {
				_loaders=new Vector.<Object>();
			}//if
			_loaders.push(loadInfo);
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onLoadPanelDataFile, itemLoader);
			SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, onLoadPanelDataFile, Settings, itemLoader);
			itemLoader.load(fullPath, ByteArray, SwagLoader.LOCALTRANSPORT);
			return (itemLoader);
		}//loadPanelDataFile
		
		public static function onLoadPanelDataFile(eventObj:SwagLoaderEvent):void {
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onLoadPanelDataFile, eventObj.source);
			var compactLoaders:Vector.<Object>=new Vector.<Object>();
			for (var count:uint=0; count<_loaders.length; count++) {
				var currentLoaderInfo:Object=_loaders[count];
				if (currentLoaderInfo.loader==eventObj.source) {
					if (currentLoaderInfo.onLoad!=null) {
						currentLoaderInfo.onLoad(eventObj);
					}//if
				} else {
					if (currentLoaderInfo!=null) {
						compactLoaders.push(currentLoaderInfo);
					}//if
				}//else
			}//for
			_loaders=compactLoaders;
		}//onLoadPanelDataFile
		
		/**
		 * Returns the virtual path location to the directory where files are stored for an individual panel.
		 *  
		 * @param panelID The panel ID for which to retrieve the virtual path.
		 * 
		 * @return The virtual path (for a <code>File</code> instance, for example), pointing to the storage directory
		 * associated with a panel. 
		 * 
		 */
		public static function getPanelFileLocation(panelID:String):String {
			var panelIDString:String=new String(panelID);
			panelIDString=SwagDataTools.stripChars(panelIDString, SwagDataTools.SEPARATOR_RANGE);
			panelIDString=SwagLoader.resolveToAppStorage("").url+panelIDString;
			return (panelIDString);
		}//getPanelFileLocation
		
		public static function onSavePanelDataFile(eventObj:SwagLoaderEvent):void {
			References.debugPanel.debug("File for panel saved: "+eventObj.source);
		}//onSavePanelDataFile
		
		public static function get applicationName():String {
			if (!SwagDataTools.isXML(settingsData)) {
				return (null);	
			}//if
			if (!SwagDataTools.isXML(settingsData.application)) {
				return (null);	
			}//if
			var appName:String=new String();
			appName=String(settingsData.application[0].children());
			return (appName);
		}//get applicationName	
		
		public static function get version():Object {
			if (!SwagDataTools.isXML(settingsData)) {
				return (null);	
			}//if
			if (!SwagDataTools.isXML(settingsData.version)) {
				return (null);	
			}//if
			var versionString:String=String(settingsData.version[0].children().toString());
			var versionObj:Object=SwagDataTools.parseVersionString(versionString);
			return (versionObj);
		}//get version
				
		public static function resetWindowLocation():void {
			var locationDataObject:Object=new Object();
			locationDataObject.x=null;
			locationDataObject.y=null;
			Settings.saveToSharedObject(locationDataObject, "SocialCastr.WindowLocation");
		}//resetWindowLocation
		
		public static function set windowLocation(locationPoint:Point):void {
			var locationDataObject:Object=new Object();
			locationDataObject.x=locationPoint.x;
			locationDataObject.y=locationPoint.y;
			Settings.saveToSharedObject(locationDataObject, "SocialCastr.WindowLocation");
		}//set windowLocation
		
		public static function get windowLocation():Point {
			var windowLocationData:Object=loadFromSharedObject("SocialCastr.WindowLocation");
			if (windowLocationData==null) {
				return (null);	
			}//if						
			var returnPoint:Point=new Point();
			if ((windowLocationData.x!=null) && (windowLocationData.x>0)
				&& (windowLocationData.y!=null) && (windowLocationData.y>0)) {
				returnPoint.x=Number(windowLocationData.x);
				returnPoint.y=Number(windowLocationData.y);
				return (returnPoint);
			}//if
			return (null);
		}//get windowLocation		
		
		public static function isDebugLevelSet(debugLevel:String=null):Boolean {
			if (!SwagDataTools.isXML(settingsData)) {
				return (false);	
			}//if
			if (!SwagDataTools.isXML(settingsData.debug)) {
				return (false);	
			}//if
			var debugString:String=new String(settingsData.debug[0].children().toString());
			var debugSplit:Array=debugString.split(";");
			var debugLevelString:String=new String(debugLevel);
			debugString=debugString.toLowerCase();
			for (var count:uint=0; count<debugSplit.length; count++) {
				var currentSplit:String=new String(debugSplit[count]);
				currentSplit=SwagDataTools.stripChars(currentSplit, SwagDataTools.SEPARATOR_RANGE);
				currentSplit=currentSplit.toLowerCase();
				if (debugLevelString==currentSplit) {
					return (true);
				}//if
			}//for
			return (false);
		}//get version
		
		public static function get panelDefinitions():XMLList {
			if (!SwagDataTools.isXML(settingsData)) {
				return (null);	
			}//if
			if (!SwagDataTools.isXML(settingsData.panels)) {
				return (null);	
			}//if
			if (!SwagDataTools.isXML(settingsData.panels.children())) {
				return (null);	
			}//if
			return (settingsData.panels.children());
		}//get panelDefinitions
		
		public static function getPanelDefinitionByName(panelName:String, caseSensitive:Boolean=false):XML {
			if (!SwagDataTools.isXML(panelDefinitions)) {
				return (null);
			}//if
			for (var count:uint=0; count<panelDefinitions.length(); count++) {
				var currentPanelNode:XML=panelDefinitions[count] as XML;
				if (SwagDataTools.hasData(currentPanelNode.@name)) {
					var currentPanelName:String=new String();
					currentPanelName=String(currentPanelNode.@name);
					if (!caseSensitive) {
						currentPanelName=currentPanelName.toLowerCase();
					}//if
					if (currentPanelName==panelName) {
						return (currentPanelNode);
					}//if
				}//if
			}//for
			return (null);
		}//getPanelDefinitionByName
		
		public static function getPanelDefinitionByID(panelID:String, caseSensitive:Boolean=false):XML {
			if (!SwagDataTools.isXML(panelDefinitions)) {
				return (null);
			}//if
			for (var count:uint=0; count<panelDefinitions.length(); count++) {
				var currentPanelNode:XML=panelDefinitions[count] as XML;
				if (SwagDataTools.hasData(currentPanelNode.@id)) {
					var currentPanelID:String=new String();
					currentPanelID=String(currentPanelNode.@id);
					if (!caseSensitive) {
						currentPanelID=currentPanelID.toLowerCase();
					}//if
					if (currentPanelID==panelID) {
						return (currentPanelNode);
					}//if
				}//if
			}//for
			return (null);
		}//getPanelDefinitionByID
		
		public static function getPanelDefinitionByClassName(className:String, caseSensitive:Boolean=false):XML {
			if (!SwagDataTools.isXML(panelDefinitions)) {
				return (null);
			}//if
			for (var count:uint=0; count<panelDefinitions.length(); count++) {
				var currentPanelNode:XML=panelDefinitions[count] as XML;
				if (SwagDataTools.hasData(currentPanelNode.@id)) {
					var currentClassName:String=new String();
					currentClassName=String(currentPanelNode.@id);
					if (!caseSensitive) {
						currentClassName=currentClassName.toLowerCase();
					}//if
					if (currentClassName==className) {
						return (currentPanelNode);
					}//if
				}//if
			}//for
			return (null);
		}//getPanelDefinitionByClassName
		
		public static function getPanelClassByID(panelID:String):Class {
			var panelNode:XML=getPanelDefinitionByID(panelID);
			if (panelNode==null) {
				return (null);
			}//if
			if (!SwagDataTools.hasData(panelNode.attribute("class"))) {
				return (null);
			}//if
			var className:String=String(panelNode.attribute("class"));
			var returnClass:Class=SwagSystem.getDefinition(className);
			return (returnClass);
		}//getPanelClassByID
		
		public static function getPanelDataByID(panelID:String, nodeName:String, returnType:*):* {
			if ((panelID=="") || (nodeName=="")) {
				return (null); 
			}//if
			var panelData:XML=getPanelDefinitionByID(panelID);
			if (panelData==null) {
				return (null);
			}//if
			if (!SwagDataTools.isXML(panelData.child(nodeName))) {
				return (null);	
			}//if
			if (returnType is XMLList) {
				return (panelData.child(nodeName) as XMLList);
			} else if (returnType is XML) {
				return (panelData.child(nodeName)[0] as XML);
			} else {
				var returnString:String=new String();
				returnString=panelData.child(nodeName)[0].children().toString();
				return (returnString);
			}//else
			return (null);
		}//get panelDataByID
		
		public static function get startupPanelID():String {
			if (!SwagDataTools.isXML(settingsData)) {
				return (null);	
			}//if
			if (!SwagDataTools.isXML(settingsData.panels)) {
				return (null);	
			}//if
			if (getWebParameter(_defaultChannelParameter, true, false)!=null) {
				if (SwagSystem.isWeb) {
					_defaultChannelPlayerPanelID="channel_player";
				}//if
				return (_defaultChannelPlayerPanelID);
			}//if
			if (SwagDataTools.hasData(settingsData.panels.@start)) {
				//Use "startup" attribute
				var returnID:String=new String();
				returnID=String(settingsData.panels.@start);
			} else {
				if (panelDefinitions==null) {
					return(null);
				} else {
					//Use first panel ID attribute 
					var firstPanel:XML=panelDefinitions[0] as XML;
					if (SwagDataTools.hasData(firstPanel.@id)) {
						returnID=String(firstPanel.@id);
					} else {
						return (null);
					}//else
				}//else
			}//else
			return (returnID);
		}//get startupPanelID
		
		public static function get tooltipEnabled():Boolean {
			if (!SwagDataTools.isXML(settingsData)) {
				return (false);	
			}//if
			var tipsNodeFailed:Boolean=false;
			//Look in both <tips> and <tooltips> node. Both are valid.
			if (!SwagDataTools.isXML(settingsData.tips)) {
				tipsNodeFailed=true;
			}//if
			if (!SwagDataTools.isXML(settingsData.tooltips) && tipsNodeFailed) {
				return (false);
			}//if
			if (tipsNodeFailed){
				var validTipNode:XML=settingsData.tooltips[0] as XML;
			} else {
				validTipNode=settingsData.tips[0] as XML;
			}//else
			var tipText:String=new String(validTipNode.children().toString());
			tipText=tipText.toLowerCase();
			tipText=SwagDataTools.stripChars(tipText, SwagDataTools.SEPARATOR_RANGE);
			switch (tipText) {
				case "on" : 
					return (true);
					break;
				case "off" : 
					return (false);
					break;
				case "yes" : 
					return (true);
					break;
				case "no" : 
					return (false);
					break;
				case "enabled" : 
					return (true);
					break;
				case "disabled" : 
					return (false);
					break;
				case "1" : 
					return (true);
					break;
				case "0" : 
					return (false);
					break;
				default:
					return (true);
					break;
			}//switch
			return (true);
		}//get menusData
		
		public static function get menusData():XML {
			if (!SwagDataTools.isXML(settingsData)) {
				return (null);	
			}//if
			if (!SwagDataTools.isXML(settingsData.menus)) {
				return (null);	
			}//if
			return (settingsData.menus[0] as XML);
		}//get menusData
		
		public static function getMenuDataByGroup(group:String):XML {
			if (group==null) {
				return (null);
			}//if
			if (!SwagDataTools.isXML(settingsData)) {
				return (null);	
			}//if
			if (!SwagDataTools.isXML(settingsData.menus)) {
				return (null);	
			}//if
			var menusNode:XML=settingsData.menus[0] as XML;
			var menusChildNodes:XMLList=menusNode.children();
			for (var count:uint=0; count<menusChildNodes.length(); count++) {
				var currentMenuNode:XML=menusChildNodes[count] as XML;
				if (SwagDataTools.isXML(currentMenuNode.@group)) {
					var menuGroup:String=String(currentMenuNode.@group);
					if (menuGroup==group) {
						return (currentMenuNode);
					}//if
				}//if
			}//for
			return (null);
		}//get getMenuDataByGroup	
		
		/**
		 * Sets emulation behaviour (how the application will run) in various runtimes. Any classes
		 * that use <code>SwagSystem</code> to determine their runtime will be affected.
		 *  
		 * @param profile The profile to assign to the application. Valid values are "mobile", "web", or "air". Not case-sensitive
		 * and any extraneous characters will be stripped out.
		 * 
		 * @return <em>True</em> if the emulation type was recognized and set, <em>false</em> otherwise. 
		 * 
		 */
		public static function setEmulation(profile:String=null):Boolean {
			if ((profile=="") || (profile==null)) {
				return (false);
			}//if
			var profileString:String=new String();
			profileString=profile;
			profileString=profileString.toLowerCase();
			profileString=SwagDataTools.stripOutsideChars(profileString, SwagDataTools.SEPARATOR_RANGE);
			switch (profileString) {
				case "mobileapp":
					SwagSystem.forceSetting("isAIR", true);
					SwagSystem.forceSetting("isMobile", true);
					SwagSystem.forceSetting("isWeb", false);
					SwagSystem.forceSetting("isStandalone", true);
					break;			
				case "mobile":
					SwagSystem.forceSetting("isAIR", true);
					SwagSystem.forceSetting("isMobile", true);
					SwagSystem.forceSetting("isWeb", false);
					SwagSystem.forceSetting("isStandalone", true);
					break;
				case "air":
					SwagSystem.forceSetting("isAIR", true);
					SwagSystem.forceSetting("isMobile", false);
					SwagSystem.forceSetting("isWeb", false);
					SwagSystem.forceSetting("isStandalone", true);
					break;
				case "airmobile":
					SwagSystem.forceSetting("isAIR", true);
					SwagSystem.forceSetting("isMobile", true);
					SwagSystem.forceSetting("isWeb", false);
					SwagSystem.forceSetting("isStandalone", true);
					break;
				case "airdesktop":
					SwagSystem.forceSetting("isAIR", true);
					SwagSystem.forceSetting("isMobile", false);
					SwagSystem.forceSetting("isWeb", false);
					SwagSystem.forceSetting("isStandalone", true);
					break;
				case "desktopapp":
					SwagSystem.forceSetting("isAIR", true);
					SwagSystem.forceSetting("isMobile", false);
					SwagSystem.forceSetting("isWeb", false);
					SwagSystem.forceSetting("isStandalone", true);
					break;
				case "desktop":
					SwagSystem.forceSetting("isAIR", true);
					SwagSystem.forceSetting("isMobile", false);
					SwagSystem.forceSetting("isWeb", false);
					SwagSystem.forceSetting("isStandalone", true);
					break;
				case "desktopweb":
					SwagSystem.forceSetting("isAIR", false);
					SwagSystem.forceSetting("isMobile", false);
					SwagSystem.forceSetting("isWeb", true);
					SwagSystem.forceSetting("isStandalone", false);
					break;				
				case "os":
					SwagSystem.forceSetting("isAIR", true);
					SwagSystem.forceSetting("isMobile", false);
					SwagSystem.forceSetting("isWeb", false);
					SwagSystem.forceSetting("isStandalone", true);
					break;
				case "osweb":
					SwagSystem.forceSetting("isAIR", true);
					SwagSystem.forceSetting("isMobile", false);
					SwagSystem.forceSetting("isWeb", true);
					SwagSystem.forceSetting("isStandalone", false);
					break;
				case "www":
					SwagSystem.forceSetting("isAIR", true);
					SwagSystem.forceSetting("isMobile", false);
					SwagSystem.forceSetting("isWeb", true);
					SwagSystem.forceSetting("isStandalone", false);
					break;
				case "web":
					SwagSystem.forceSetting("isAIR", false);
					SwagSystem.forceSetting("isMobile", false);
					SwagSystem.forceSetting("isWeb", true);
					SwagSystem.forceSetting("isStandalone", false);
					break;
				case "mobileweb":
					SwagSystem.forceSetting("isAIR", false);
					SwagSystem.forceSetting("isMobile", true);
					SwagSystem.forceSetting("isWeb", true);
					SwagSystem.forceSetting("isStandalone", false);
					break;
				case "browser":
					SwagSystem.forceSetting("isAIR", true);
					SwagSystem.forceSetting("isMobile", false);
					SwagSystem.forceSetting("isWeb", true);
					SwagSystem.forceSetting("isStandalone", false);
					break;
				//Use whatever was detected!
				case "native":					
					return (true);
					break;
				case "none":					
					return (true);
					break;
				case "":					
					return (true);
					break;
				default:
					return (false);
					break;
			}//switch
			return (false);
		}//setEmulation
		
		public static function get defaultEmulationProfile():String {
			var emulationProfile:String=new String();
			if (!SwagDataTools.isXML(settingsData.emulate)) {
				return (emulationProfile);	
			}//if	
			var emulationNode:XML=settingsData.emulate[0] as XML;
			emulationProfile=String(emulationNode.children().toString());
			emulationProfile=SwagDataTools.stripOutsideChars(emulationProfile, SwagDataTools.SEPARATOR_RANGE);
			emulationProfile=emulationProfile.toLowerCase();
			return (emulationProfile);
		}//get emulationProfile
		
		public static function get silentStartupPanelIDs():Array {
			var returnPanelArray:Array=new Array();
			if (!SwagDataTools.isXML(settingsData)) {
				return (returnPanelArray);	
			}//if
			if (!SwagDataTools.isXML(settingsData.panels)) {
				return (returnPanelArray);	
			}//if
			if (!SwagDataTools.isXML(settingsData.panels)) {
				return (returnPanelArray);	
			}//if			
			if (SwagDataTools.hasData(settingsData.panels.@silentstart)) {
				//Use "silent" attribute
				var panelIDs:String=new String();
				panelIDs=String(settingsData.panels.@silentstart);
				returnPanelArray=panelIDs.split(";");
			}//if
			return (returnPanelArray);
		}//get silentStartupPanelIDs
		
		public static function get startupPanelClass():Class {			
			if (startupPanelID==null) {
				return (null);
			}//if
			var startupClass:Class=getPanelClassByID(startupPanelID);
			return (startupClass);
		}//get startupPanelClass
		
		public static function get silentStartupPanelClasses():Array {	
			var returnPanelClasses:Array=new Array();
			var panelIDs:Array=silentStartupPanelIDs;
			if (panelIDs.length==0) {
				return (returnPanelClasses);
			}//if
			for (var count:uint=0; count<panelIDs.length; count++) {
				var currentID:String=panelIDs[count] as String;
				var silentClass:Class=getPanelClassByID(currentID);
				returnPanelClasses.push(silentClass);
			}//for			
			return (returnPanelClasses);
		}//get silentStartupPanelClasses	
		
		public static function getSCID():String {
			var useLSO:Boolean=false;
			if (SwagSystem.isAIR) {
				if (EncryptedLocalStore.isSupported) {
					var SCIDValue:ByteArray=EncryptedLocalStore["getItem"]("__$¢1D ");
					//Use the following instead if special characters aren't translating properly.
					//var SCIDValue:ByteArray=EncryptedLocalStore["getItem"]("__$"+String.fromCharCode(155)+"1D"+String.fromCharCode(255));
					if (SCIDValue!=null) {
						return (SCIDValue.toString());
					} else {					
						if (getCCID()==null) {
							return (null);
						} else { 
							var SCIDString:String=SCID.generate(getCCID());
							saveSCID(SCIDString);
							return (SCIDString);
						}//else
					}//else
				} else {
					useLSO=true;
				}//else
			} else {
				useLSO=true;
			}//else
			if (useLSO) {
				SCIDString=loadFromSharedObject("__$¢1D ", "__scratchdisk");
				//Use the following instead if special characters aren't translating properly.				
				//SCIDString=loadFromSharedObject("__$"+String.fromCharCode(155)+"1D"+String.fromCharCode(255), "__scratchdisk");
				if ((SCIDString!=null) && (SCIDString!="")) {
					return (SCIDString);
				}//if
				SCIDString=SCID.generate(getCCID());
				saveSCID(SCIDString);
				return (SCIDString);
			}//if
			return (null);
		}//getSCID
		
		public static function getCCID():String {
			return (SwagCloud.connectionPeerID);
		}//getCCID
		
		private static function saveSCID(SCIDString:String):void {
			if ((SCIDString==null) || (SCIDString=="")) {
				return;
			}//if
			var useLSO:Boolean=false;
			if (SwagSystem.isAIR) {
				if (EncryptedLocalStore.isSupported) {
					var SCIDBA:ByteArray=new ByteArray();
					SCIDBA.writeUTFBytes(SCIDString);
					EncryptedLocalStore["setItem"]("__$¢1D ", SCIDBA, false);
					//Use the following instead if special characters aren't translating properly.
					//EncryptedLocalStore["setItem"]("__$"+String.fromCharCode(155)+"1D"+String.fromCharCode(255), SCIDBA, false);
				} else {
					useLSO=true;
				}//else
			} else {
				useLSO=true;
			}//else
			if (useLSO) {
				saveToSharedObject(SCIDString, "__$¢1D ", "__scratchdisk");
				//Use the following instead if special characters aren't translating properly.
				//saveToSharedObject(SCIDString, "__$"+String.fromCharCode(155)+"1D"+String.fromCharCode(255), "__scratchdisk");
			}//if
		}//saveSCID
		
		/** 
		 * @return The Live Timeline definition included in the settings data (as a <livetimeline> node),
		 * or a minimal default live timeline definition if none exists. This definition is a reference
		 * to the XML node within the main settings data so any changes made to it can potentially be 
		 * saved to the settings.
		 */
		static public function get liveTimelineXML():XML {
			var returnXML:XML=verifyChildNode(settingsData, "livetimeline");
			return (returnXML);
		}//get liveTimelineXML
				
		private static function get EncryptedLocalStore():Class {
			if (!SwagSystem.isAIR) { 
				return (null);
			}//if
			var ELSClass:Class=SwagSystem.getDefinition("flash.data.EncryptedLocalStore") as Class;
			return (ELSClass);
		}//get EncryptedLocalStore
		
	}//Settings class
	
	
}//package