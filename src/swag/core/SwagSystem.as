package swag.core {
	
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.scanHardware;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.Timer;
	import flash.utils.getDefinitionByName;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.events.SwagEvent;
	import swag.interfaces.core.ISwagSystem;	
	/**
	 * Provides or collects a variety of methods and properties that can be used by the developer to deeply inspect and (sometimes)
	 * update the host system settings (the Flash / AIR version, the operating system, browser, etc.), or various core ActionScript 
	 * objects.
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
	public final class SwagSystem extends SwagDispatcher implements ISwagSystem	{
		
		private static const _mobileOSes:Array=["Windows SmartPhone", "Windows PocketPC", "Windows CEPC", "Windows Mobile", "iPhone", "AND"];
		private static const _camResolutions:Array=[
			{width:40,height:30},
			{width:80,height:60},
			{width:160,height:120},
			{width:320,height:240},
			{width:640,height:480},
			{width:720,height:540},
			{width:960,height:720},
			{width:1280,height:960},
			{width:1920,weight:1440},
			{width:2880,height:2160},
			{width:4320,height:3240},					   
		];
		//Setters (where appropriate) & getters are provided for the following properties.
		private static var _initialized:Boolean=false;		
		private static var _settings:Object=new Object();
		private static var _onExistsTimer:Timer=null;
		private static var _onExistsWatches:Array=new Array();
		
							
		/**
		 * 
		 * Returns true if <code>SwagSystem</code> has been initialized, false otherwise. 
		 * <p>If not properly initialized, <code>SwagSystem</code> may not return accurate values because it hasn't 
		 * had a chance to fully query the system.</p> 
		 * 
		 */
		public static function get initialized():Boolean {
			return (_initialized);
		}//get intialized
		
		/**
		 * 
		 * Contains all of the settings detected by <code>SwagSystem</code>. 
		 * 
		 * <p>As well as including all of the properties from the <code>flash.system.Capabilities</code>, 
		 * <code>flash.system.System</code>, and <code>flash.desktop.NativeApplication</code> classes, 
		 * the <code>settings</code> object also includes the following data:
		 * <ul>
		 * <li>isAIR (<code>Boolean</code>) - <em>True</em> if the enclosing runtime is AIR.</li>
		 * <li>isWeb (<code>Boolean</code>) - <em>True</em> if the enclosing runtime is the Flash web player (plugin or ActiveX).</li>
		 * <li>isStandalone (<code>Boolean</code>) - <em>True</em> if the enclosing runtime is the standalone Flash player.</li>
		 * <li>isMobile (<code>Boolean</code>) - <em>True</em> if the enclosing runtime is a mobile version of AIR or the Flash web player.</li>		 
		 * </ul>
		 * </p>
		 * 
		 * <p>Any properties that are not available are set to <em>null</em>; for example, when attempting to read AIR properties from within
		 * the Flash web player.</p>
		 * 
		 * @see flash.system.Capabilities
		 * @see flash.system.System
		 * @see flash.system.NativeApplication
		 */
		public static function get settings():Object {			
			if (!initialized) {
				updateSettingsObject();
			}//if
			return (_settings);
		}//get settings
		
		/**
		 * Forces a setting in the <code>setting</code> object to the desired value. 
		 *  
		 * @param settingName The name of the system setting (e.g. "isAIR"), to set.
		 * @param data The data to assign to the setting.
		 * 
		 * @return <em>True</em> if the setting could be assigned (the setting exists. <em>False</em> is returned if the setting could not 
		 * be assigned for some reason. 
		 * 
		 */
		public static function forceSetting(settingName:String=null, data:*=null):Boolean {
			if ((settingName=="") || (settingName==null)) {
				return (false);
			}//if
			for (var item in settings) {
				if (item==settingName) {
					try {
						settings[item]=data;
					} catch (e:*) {
						return (false);
					}//catch
					return (true);
				}//if
			}//for
			return (false);
		}//forceSetting
		
		/**
		 * 
		 * Returns <em>true</em> if the containing runtime environment is the Adobe Integrated Runtime, <em>false</em> otherwise.
		 * 
		 */
		public static function get isAIR():Boolean {		
			return (settings.isAIR);
		}//get isAIR
		
		/**
		 * 
		 * Returns <em>true</em> if the containing runtime environment is the Flash web player, <em>false</em> otherwise.
		 * 
		 */
		public static function get isWeb():Boolean {		
			return (settings.isWeb);
		}//get isWeb
		
		/**
		 * 
		 * Returns <em>true</em> if the containing runtime environment is the standalone (external) Flash player, <em>false</em> otherwise.
		 * 
		 */
		public static function get isStandalone():Boolean {		
			return (settings.isStandalone);
		}//get isStandalone
		
		/**
		 * 
		 * Returns <em>true</em> if the containing runtime environment is a mobile OS version, <em>false</em> if it's a desktop OS version.
		 * 
		 */
		public static function get isMobile():Boolean {		
			return (settings.isMobile);
		}//get isMobile
		
		/**
		 * Similar to the built-in <code>flash.utils.getDefinitionByName</code> method, this method attemps to find an object definition (protype or
		 * class object), for the specified object name (string).
		 * 
		 * @param definition The name of the object to look up and (if found), return a reference to.
		 * @param appDomain An optional application domain inspect if the initial attempt to discover the <code>definition</code> fails.
		 * 
		 * @return A reference to the found class object for the specified <code>definition</code>, or <em>null</em> if no such object
		 * can be found.
		 * 
		 * @see flash.utils.getDefinitionByName
		 * @see flash.system.ApplicationDomain
		 * 
		 */
		public static function getDefinition(definition:String, appDomain:ApplicationDomain=null):Class {
			if (definition==null) {
				return (null);
			}//if
			var localDefinition:String=new String(definition);
			localDefinition=SwagDataTools.stripOutsideChars(localDefinition, " ");
			if (definition=="") {
				return (null);
			}//if			
			try {				
				var returnClass:Class=getDefinitionByName(localDefinition) as Class;				
				return (returnClass);				
			} catch (e:ReferenceError) {				
				if (appDomain!=null) {					
					try {
						returnClass=appDomain.getDefinition(localDefinition) as Class;
						return (returnClass);
					} catch (e:ReferenceError) {
						return (null);
					}//catch
					return (null);					
				} else {
					return (null);
				}//else
			}//catch
			return (null);
		}//getDefinition
		
		/**
		 * Begins monitoring for the existence of a property within a specific object, and invokes a method
		 * when that property becomes available (is not <em>undefined</em> and, optionally, is not <em>null</em>).
		 * <p><em>Null</em> objects are considered to exist and will trigger the <code>callbackMethod</code> unless
		 * the <code>allowNull</code> parameter is <em>false</em>.</p> 
		 * 
		 * @param property The property to begin monitoring for. Must not be <em>null</em> or an empty string.
		 * @param targetObject The object that is expected to contain the <code>property</code> at some time in the future. Must not
		 * be <em>null</em>.
		 * @param callbackMethod The method to invoke when the specified <code>property</code> within the <code>targetObject</code> becomes
		 * available. The callback method should not expect any parameters.
		 * @param allowNull If <em>true</em>, <em>null</em> objects are considered to exist and will invoke the <code>callbackMethod</code>. 
		 * If <em>false</em>, only non-<em>null</em> and non-<em>undefined</em> objects are considered to exist.
		 * 
		 * @return <em>True</em> if the <code>property</code> monitor was successfully created and started. <em>False</em> is returned if there 
		 * was a problem creating the watch monitor (for example, if one of the supplied parameters is incorrect). 
		 * 
		 */
		public static function onExists(property:String, targetObject:*, callbackMethod:Function, allowNull:Boolean=true):Boolean {
			if (!SwagDataTools.hasData(property)) {
				return (false);
			}//if
			if (property=="") {
				return (false);
			}//if
			if (targetObject==null) {
				return (false);
			}//if
			if (callbackMethod==null) {
				return (false);
			}//if
			if (addOnExistsWatch(property, targetObject, callbackMethod)==false) {
				return (false);
			}//if
			if (startOnExistsTimer()==false) {
				return (false);
			}//if
			return (true);
		}//onExists
		
		/**
		 * Returns an array of objects containing available "width", "height", and "fps" values for a specific camera (the "fps" value
		 * represents the highest possible frames per setting for that resolution).
		 * <p>The returned data includes only the specific modes available for the camera (useful for populating combo boxes, for example).</p>
		 *  
		 * @param camIndex The string numeric index of the camera to retrieve (same as passed to <code>Camera.getCamera</code> method).
		 * 		 
		 * @return An array of objects containing the properties "width", "height" and "fps". These values represent valid modes
		 * for the specified camera device. A <em>null</em> is returned if the camera index is invalid, or cameras are not supported. 
		 * 
		 */
		public static function getCameraResolutions(camIndex:String):Array {
			if (!Camera.isSupported) {
				return (null);
			}//if
			if ((camIndex==null) || (camIndex=="")) {
				return (null);
			}//if
			scanHardware();  
			var returnArray:Array=new Array();
			var cameras:Array=Camera.names;
			var currentCam:Camera=Camera.getCamera(camIndex);
			if (currentCam!=null) {
				for (var count:uint=0; count<_camResolutions.length; count++) {
					var testRes:Object=_camResolutions[count];
					//Use a very high FPS, detection will clip it at highest available value.
					currentCam.setMode(testRes.width, testRes.height, 1024, true);
					//Sometimes this is reported. Clearly not correct...
					if ((currentCam.width>1) && (currentCam.height>1)) {
						if (!cameraModeInArray(currentCam.width, currentCam.height, returnArray)) {
							var infoObject:Object=new Object();
							infoObject.width=currentCam.width;
							infoObject.height=currentCam.height;
							infoObject.fps=currentCam.fps;
							returnArray.push(infoObject);
						}//if
					}//if
				}//for
			} else {
				return (null);
			}//else
			return (returnArray);
		}//getCameraResolutions		
		
		/**
		 * @private 		 		 
		 */
		private static function cameraModeInArray(modeWidth:int, modeHeight:int, arrayObj:Array):Boolean {
			for (var count:uint=0; count<arrayObj.length; count++) {
				var currentObject:Object=arrayObj[count];
				if ((currentObject.width==modeWidth) && (currentObject.height==modeHeight)) {
					return (true);
				}//if
			}//for
			return (false);
		}//cameraModeInArray
				
		/**
		 * @private 		 		 
		 */
		private static function onExistsMonitor(eventObj:TimerEvent):void {
			if (_onExistsWatches==null) {
				stopOnExistsTimer();
			}//if
			if (_onExistsWatches.length==0) {
				stopOnExistsTimer();
			}//if
			for (var count:int=0; count<_onExistsWatches.length; count++) {
				var currentWatch:Object=_onExistsWatches[count] as Object;
				if ((currentWatch.targetObject==null) || (currentWatch.property==null) || (currentWatch.callbackMethod==null)) {
					removeOnExistsWatch(currentWatch);
					return;
				}//if
				if (currentWatch.targetObject[currentWatch.property]!=undefined) {
					if (currentWatch.allowNull==true) {
						currentWatch.callbackMethod();
						removeOnExistsWatch(currentWatch);
					} else {
						if (SwagDataTools.hasData(currentWatch.targetObject[currentWatch.property])) {
							currentWatch.callbackMethod();
							removeOnExistsWatch(currentWatch);
						}//if
					}//else
				}//if
			}//for
		}//onExistsMonitor
		
		/**
		 * @private 		 		 
		 */
		private static function startOnExistsTimer():Boolean {
			stopOnExistsTimer();
			_onExistsTimer=new Timer(10);
			_onExistsTimer.addEventListener(TimerEvent.TIMER, onExistsMonitor);
			_onExistsTimer.start();
			return (true);
		}//startOnExistsTimer
		
		/**
		 * @private 		 		 
		 */
		private static function stopOnExistsTimer():Boolean {
			if (_onExistsTimer!=null) {
				if (_onExistsTimer.running) {
					_onExistsTimer.stop();
				}//if
				_onExistsTimer.removeEventListener(TimerEvent.TIMER, onExistsMonitor);
				_onExistsTimer=null;
				return (true);
			}//if
			return (false);
		}//stopOnExistsTimer
		
		/**
		 * @private 		 		 
		 */
		private static function addOnExistsWatch(property:String, targetObject:*, callbackMethod:Function, allowNull:Boolean=true):Boolean {
			if (_onExistsWatches==null) {
				_onExistsWatches=new Array();
			}//if
			var watchObject:Object=new Object();
			watchObject.property=new String(property);
			watchObject.targetObject=targetObject;
			watchObject.callbackMethod=callbackMethod;
			watchObject.allowNull=allowNull;
			_onExistsWatches.push(watchObject);
			return (true);
		}//addOnExistsWatch
		
		/**
		 * @private 		 		 
		 */
		private static function removeOnExistsWatch(watchObject:Object):Boolean {
			if (_onExistsWatches==null) {
				return (false);
			}//if
			if (_onExistsWatches.length==0) {
				return (false);
			}//if
			for (var count:int=0; count<_onExistsWatches.length; count++) {
				var currentWatch:Object=_onExistsWatches[count] as Object;
				if (currentWatch==watchObject) {
					_onExistsWatches.splice(count, 1);
					return (true);
				}//if
			}//for
			return (false);
		}//removeOnExistsWatch
		
		/**
		 * @private 
		 */		
		private static function updateSettingsObject():void {					
			_settings=new Object();	
			_initialized=true;
			//Push all the public properties from the Capabilities class into the settings object...
			_settings.avHardwareDisable=Capabilities.avHardwareDisable;
			_settings.cpuArchitecture=Capabilities.cpuArchitecture;
			_settings.hasAccessibility=Capabilities.hasAccessibility;
			_settings.hasAudio=Capabilities.hasAudio;
			_settings.hasAudioEncoder=Capabilities.hasAudioEncoder;
			_settings.hasEmbeddedVideo=Capabilities.hasEmbeddedVideo;			
			_settings.hasIME=Capabilities.hasIME;			
			_settings.hasMP3=Capabilities.hasMP3;
			_settings.hasPrinting=Capabilities.hasPrinting;
			_settings.hasScreenBroadcast=Capabilities.hasScreenBroadcast;
			_settings.hasScreenPlayback=Capabilities.hasScreenPlayback;
			_settings.hasStreamingAudio=Capabilities.hasStreamingAudio;
			_settings.hasStreamingVideo=Capabilities.hasStreamingVideo;
			_settings.hasTLS=Capabilities.hasTLS;
			_settings.hasVideoEncoder=Capabilities.hasVideoEncoder;
			_settings.isDebugger=Capabilities.isDebugger;
			_settings.isEmbeddedInAcrobat=Capabilities.isEmbeddedInAcrobat;
			_settings.language=Capabilities.language;
			_settings.localFileReadDisable=Capabilities.localFileReadDisable;
			_settings.manufacturer=Capabilities.manufacturer;
			_settings.maxLevelIDC=Capabilities.maxLevelIDC;
			_settings.os=Capabilities.os;
			_settings.pixelAspectRatio=Capabilities.pixelAspectRatio;
			_settings.playerType=Capabilities.playerType;
			_settings.screenColor=Capabilities.screenColor;
			_settings.screenDPI=Capabilities.screenDPI;
			_settings.screenResolutionX=Capabilities.screenResolutionX;
			_settings.screenResolutionY=Capabilities.screenResolutionY;
			_settings.serverString=Capabilities.serverString;
			_settings.supports32BitProcesses=Capabilities.supports32BitProcesses;
			_settings.supports64BitProcesses=Capabilities.supports64BitProcesses;			
			_settings.version=Capabilities.version;	
			var cleanedVersion:String=SwagDataTools.stripChars(Capabilities.version, 
										SwagDataTools.LOWERCASE_RANGE+SwagDataTools.UPPERCASE_RANGE+SwagDataTools.SEPARATOR_RANGE);
			_settings.parsedVersion=SwagDataTools.parseVersionString(cleanedVersion, ",");
			//Push all the public properties from the System class...			
			try {
				_settings.ime=System.ime; //iPhone export seems to have issues with this.
			} catch (e:*) {
				trace (e);
			}//catch
			_settings.freeMemory=System.freeMemory;
			_settings.privateMemory=System.privateMemory;
			_settings.totalMemoryNumber=System.totalMemoryNumber;			
			_settings.privateMemory=null;
			_settings.totalMemoryNumber=null;			
			_settings.totalMemory=System.totalMemory;			
			_settings.useCodePage=System.useCodePage;
			//Now add custom settings properties...
			_settings.isAIR=new Boolean();
			_settings.isWeb=new Boolean();
			_settings.isStandalone=new Boolean();
			_settings.isMobile=new Boolean();			
			if ((Capabilities.playerType=="ActiveX") || (Capabilities.playerType=="PlugIn")) {
				_settings.isAIR=false;
				_settings.isWeb=true;
				_settings.isStandalone=false;
			}//if
			if (Capabilities.playerType=="Desktop") {
				_settings.isAIR=true;
				_settings.isWeb=false;
				_settings.isStandalone=false;
			}//if
			if ((Capabilities.playerType=="External") || (Capabilities.playerType=="StandAlone")) {
				_settings.isAIR=false;
				_settings.isWeb=false;
				_settings.isStandalone=true;
			}//if
			_settings.isMobile=false;
			if (SwagDataTools.stringContains(_mobileOSes, Capabilities.os, false)) {
				_settings.isMobile=true;
			}//if
			if (SwagDataTools.stringContains(_mobileOSes, Capabilities.version, false)) {
				//Detects "AND" (Android)
				_settings.isMobile=true;
			}//if
			if (Capabilities.cpuArchitecture=="ARM") {
				_settings.isMobile=true;
			}//if
			//Push settings from NativeApplication class if AIR is supported...
			_settings.nativeApplication=null;
			_settings.supportsDefaultApplication=false;
			_settings.supportsStartAtLogin=false;
			_settings.supportsDockIcon=false;
			_settings.supportsMenu=false;
			_settings.supportsSystemTrayIcon=false;			
			_settings.supportsTransparency=false;
			if (isAIR) {
				try {
					var nativeApplicationClass:Class=getDefinitionByName("flash.desktop.NativeApplication") as Class;
					_settings.nativeApplication=nativeApplicationClass.nativeApplication;
					_settings.supportsDefaultApplication=nativeApplicationClass.supportsDefaultApplication;
					_settings.supportsStartAtLogin=nativeApplicationClass.supportsStartAtLogin;					
					_settings.supportsDockIcon=nativeApplicationClass.supportsDockIcon;
					_settings.supportsMenu=nativeApplicationClass.supportsMenu;
					_settings.supportsSystemTrayIcon=nativeApplicationClass.supportsSystemTrayIcon;					
					_settings.supportsTransparency=nativeApplicationClass.supportsTransparency;
				} catch (e:ReferenceError) {
					//broadcast an error here
				}//catch
			}//if
		}//updateSettingsObject
		
	}//SwagSystem class
	
}//package