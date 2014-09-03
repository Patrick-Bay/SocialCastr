package socialcastr {
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.None;
	import fl.transitions.easing.Strong;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.media.Camera;
	import flash.media.scanHardware;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.events.ApplicationEvent;
	import socialcastr.interfaces.IMain;
	import socialcastr.ui.components.AccordionMenu;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDebug;
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.core.instances.SwagDiscovery;
	import swag.core.instances.SwagLoader;
	import swag.events.SwagErrorEvent;
	import swag.events.SwagLoaderEvent;
	import swag.events.SwagMovieClipEvent;
	
	/**
	 * Main SocialCastr application class.
	 * 
	 * This class covers main application functionality, including startup, variable loading, etc. for both the desktop and
	 * online versions of the application, but some features may be automatically disabled depending on the runtime.
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
	public class Main extends MovieClip implements IMain {
		
		public static const version:String="1.1";
		/**
		 * Forces a re-load of the default XML configuration data on next application startup. Similar functionality
		 * added to debug panel.
		 */
		public var resetSettings:Boolean=true;
		private var _mainMenu:AccordionMenu;
		private var _squeezeTween:Tween;
		private var _originalHeight:Number;
		
		public function Main() {			
			References.main=this;
			this.setDefaults();	
			SwagDispatcher.addEventListener(ApplicationEvent.SHUTDOWN, this.onShutDown, this, null);
			SwagDispatcher.addEventListener(ApplicationEvent.MINIMIZE, this.onMinimize, this, null);
			this.addEventListener(Event.ADDED_TO_STAGE, this.initialize);
			References.debug ("SocialCastr \"Main\" class (version "+version+") instantiated.");
			CONFIG::RECEIVR {
				trace ("\"CONFIG::RECEIVR\" compiler directive detected.");	
				//Add special startup code here
			}//CONFIG::RECEIVR			
			CONFIG::BROADCASTR {
				trace ("\"CONFIG::BROADCASTR\" compiler directive detected.");
				//Add special startup code here
			}//CONFIG::BROADCASTR
			scanHardware(); //Runs the detection mechanism early to prevent any null values.
			super();
		}//constructor	
		
		/**
		 * Begins the process of starting the application.
		 * <p>This includes things like loading application startup data, connecting to associated networks, etc.</p>
		 * <p>Once the whole process is completed, the <code>startApplication</code> method is invoked to actually
		 * start the application going.</p>
		 * <p>The application includes a fallback mechanism	used while loading settings data in which the settings file
		 * is first loaded from the relative path "xml/settings.xml". If it can't be found, it's loaded from the relative location
		 * "settings.xml". Finally, if that fails the application attempts to load "/settings.xml". If all three attempts should fail,
		 * the application won't be started.</p>
		 */
		public function initialize(... args):void {
			References.debug ("Main: Initializing.");			
			//Restore window to last known location on screen...
			if (resetSettings) {
				Settings.resetWindowLocation();
			}//if
			this.alpha=0;
			this.visible=false;
			var windowLocation:Point=Settings.windowLocation;
			if ((windowLocation!=null) && (SwagSystem.isAIR)) {
				this.stage["nativeWindow"].x=windowLocation.x;
				this.stage["nativeWindow"].y=windowLocation.y;
			}//if			
			this.visible=true;
			this.alpha=1;
			this.removeEventListener(Event.ADDED_TO_STAGE, this.initialize);
			this.addListeners();	
			this.loadSettings();
		}//initialize
		
		/**
		 * Begins loading the application settings from XML.		 
		 */
		public function loadSettings():void {
			Settings.settingsFile=Settings.defaultSettingsFile;
			Settings.loadSettings(false, !resetSettings, resetSettings);
		}//loadSettings
		
		public function playIntroAnimation():void {
			this.alpha=1;
			this.visible=true;			
			References.debug ("Main: playIntroAnimation.");
			SwagDispatcher.addEventListener(SwagMovieClipEvent.END, this.onIntroAnimationComplete, this, References.introAnimation);
			References.introAnimation.visible=true;
			References.introAnimation.alpha=1;			
			if (Settings.getWebParameter("logo")=="false") {
				//Need a few frames to get the application running.
				References.introAnimation.playRange("nologobegin","nologofinish",false);
			} else {
				References.introAnimation.playRange("begin","finish",false);
			}//else
		}//playIntroAnimation
		
		public function onIntroAnimationComplete():void {			
			this.addEventListener(Event.ENTER_FRAME, this.startUpFadeLoop);
			References.debug ("Main: onIntroAnimationComplete.");
			this.showDesktopChrome();
			SwagDispatcher.removeEventListener(SwagMovieClipEvent.END, this.onIntroAnimationComplete, References.introAnimation);				
		}//onIntroAnimationComplete
		
		public function hideDesktopChrome():void {
			for (var count:uint=0; count<References.desktopChromeElements.length; count++) {
				var currentElement:DisplayObject=References.desktopChromeElements[count] as DisplayObject;
				if (currentElement!=null) {
					var tween:Tween=new Tween(currentElement, "alpha", None.easeNone, currentElement.alpha, 0, 0.3, true);
				}//if
			}//for
		}//hideDesktopChrome
		
		public function showDesktopChrome():void {
			for (var count:uint=0; count<References.desktopChromeElements.length; count++) {
				var currentElement:DisplayObject=References.desktopChromeElements[count] as DisplayObject;
				if (currentElement!=null) {
					currentElement.alpha=0;
					currentElement.visible=true;
					//Tween is simply not reliable at this point.
					currentElement.addEventListener(Event.ENTER_FRAME, this.targetFadeInLoop);
					//var tween:Tween=new Tween(currentElement, "alpha", None.easeNone, currentElement.alpha, 1, 15, false);
				}//if
			}//for
		}//showDesktopChrome
		
		public function targetFadeInLoop(eventObj:Event):void {
			if (eventObj.target.alpha>=1) {
				eventObj.target.alpha=1;
				eventObj.target.removeEventListener(Event.ENTER_FRAME, this.targetFadeInLoop);
				return;
			}//if
			eventObj.target.alpha+=0.1;
		}//targetFadeInLoop
		
		/**
		 * Starts the application's main functionality. Called by the <Settings> class after all data is loaded and parsed.
		 * <p>It is assumed that all required startup data has been loaded, all required network connections have
		 * been established, and so on, so the application is fully ready to start at this point.</p> 		 
		 */
		public function startApplication():void {
			References.debug ("Main: Starting application.");
			References.panelManager.target=this;
			References.panelManager.createSilentPanels();									
			References.debug ("__/ DIAGNOSTICS \\__");
			References.debug("Runtime Version: "+Capabilities.version);			
			if (SwagSystem.isMobile) {
				References.debug("OS: "+Capabilities.os+" (mobile)");
			} else {
				References.debug("OS: "+Capabilities.os+" (desktop or web)");
			}//else
			References.debug("Host Architecture: "+Capabilities.cpuArchitecture);
			References.debug("Functional Runtime Emulation: "+Settings.defaultEmulationProfile);
			if (SwagSystem.isAIR) {
				References.debug("* Configuration File *\n   Symbolic: "+Settings.settingsFile+"\n   Native: "+SwagLoader.resolveToAppStorage(Settings.settingsFile)["nativePath"]);
			} else {
				References.debug("* Configuration File *\n   Symbolic: "+Settings.settingsFile+"\n");
			}//else
			References.debug(" ");
			References.debug(Settings.settingsData.toXMLString());
			References.debug(" ");
			References.debug("____________");		
			References.announceChannel.initialize();
			References.debug("Main: Starting up main UI...");	
			this.visible=true;
			this.playIntroAnimation();			
		}//startApplication
		
		private function startUpFadeLoop(eventObj:Event):void {			
			this.alpha+=0.05;
			if (this.alpha>=1) {			
				this.removeEventListener(Event.ENTER_FRAME, this.startUpFadeLoop);				
				this.filters=[];
				this.onApplicationVisible();
			}//if
		}//startUpFadeLoop
		
		private function onApplicationVisible():void {
			References.debug("Main: Application UI ready. Creating startup panel \""+Settings.startupPanelID+"\".");
			References.panelManager.createStartupPanel();
			if (SwagSystem.isMobile) {
				//Create a device menu instead.
			} else {
				if (Settings.getWebParameter("appmenu", true, true)=="false") {					
				} else {
					this._mainMenu=new AccordionMenu("main");
					this.addChild(this._mainMenu);
				}//else
			}//else
		}//onApplicationVisible		
				
		public function onShutDown(eventObj:ApplicationEvent):void {			
			References.debug("Main: Application is shutting down.");
			if (SwagSystem.isAIR) {
				Settings.windowLocation=new Point(this.stage["nativeWindow"].x, this.stage["nativeWindow"].y);
			}//if
			Settings.saveSettings();
			this.destroy();
			//this.addEventListener(Event.ENTER_FRAME, this.shutDownFadeLoop);			
		}//onShutDown
		
		public function onMinimize(eventObj:ApplicationEvent):void {	
			References.debug("Main: Application is minimizing.");
			if (SwagSystem.isAIR) {
				Settings.windowLocation=new Point(this.stage["nativeWindow"].x, this.stage["nativeWindow"].y);
			}//if
			Settings.saveSettings();
			this.stage.scaleMode=StageScaleMode.SHOW_ALL;
			this._originalHeight=this.stage.stageHeight;
			this._squeezeTween=new Tween(this.stage, "stageHeight", Strong.easeInOut, this.stage.stageHeight, 1, 0.35, true);
			this._squeezeTween.addEventListener(TweenEvent.MOTION_FINISH, this.minimizeHostWindow);
		}//onMinimize
		
		private function minimizeHostWindow(eventObj:TweenEvent):void {
			this._squeezeTween.removeEventListener(TweenEvent.MOTION_FINISH, this.minimizeHostWindow);
			this._squeezeTween=null;
			Settings.windowLocation=new Point(this.stage["nativeWindow"].x, this.stage["nativeWindow"].y);
			if (SwagSystem.isAIR) {
				this.stage["nativeWindow"].minimize();
				this.stage.scaleMode=StageScaleMode.NO_SCALE;
				this.stage.stageHeight=this._originalHeight;
			}//if
		}//minimizeHostWindow
		
		private function shutDownFadeLoop(eventObj:Event):void {			
			this.alpha-=0.2;
			if (this.alpha<=0) {
				this.visible=false;
				this.removeEventListener(Event.ENTER_FRAME, this.shutDownFadeLoop);
				this.destroy();
			}//if
		}//shutDownFadeLoop
		
		private function closeHostWindow():void {
			if (SwagSystem.isAIR) {
				NativeApplication.nativeApplication.exit(0);
			}//if
		}//closeHostWindow
		
		public function onMainWindowClosing(eventObj:Event):void {
			if (SwagSystem.isAIR) {
				Settings.windowLocation=new Point(this.stage["nativeWindow"].x, this.stage["nativeWindow"].y);
			}//if
			Settings.saveSettings();
		}//onMainWindowClosing
		
		public static function get NativeApplication():Class {
			if (!SwagSystem.isAIR) {
				return (null);
			}//if
			var NativeApplicationClass:Class=SwagSystem.getDefinition("flash.desktop.NativeApplication") as Class;
			return (NativeApplicationClass);
		}//get NativeApplication		
		
		private function addListeners():void {
			if (SwagSystem.isAIR) {
				if (NativeApplication.activeWindow!=null) {
					NativeApplication.activeWindow.addEventListener(Event["CLOSING"], this.onMainWindowClosing);
				}//if
			} else {
				
			}//else
		}//addListeners
		
		public function destroy():void {
			this.filters=[];
			this.closeHostWindow();
		}//destroy
		
		private function setDefaults():void {	
			this.visible=false;
			this.alpha=0;
		}//setDefaults
		
	}//Main class
	
}//package