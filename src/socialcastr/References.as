package socialcastr {
	
	import socialcastr.core.AnnounceChannel;
	import socialcastr.interfaces.IReferences;
	import socialcastr.ui.PanelManager;
	import socialcastr.ui.components.IntroAnimation;
	import socialcastr.ui.panels.DebugPanel;
	import socialcastr.ui.panels.IdentityPanel;
	import socialcastr.ui.panels.TextChatPanel;
	import socialcastr.ui.panels.VideoChatPanel;
	
	import swag.core.SwagSystem;
	
	/**
	 * Stores references to any static class instances or references for the application.
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
	public class References implements IReferences {
	
		private static var _main:Main=null;
		private static var _panelManager:PanelManager=null;
		private static var _debugPanel:DebugPanel=null;
		private static var _identityPanel:IdentityPanel=null;
		private static var _introAnimation:IntroAnimation=null;
		private static var _announceChannel:AnnounceChannel=null;
		private static var _textChatChannel:TextChatPanel=null;
		private static var _desktopChromeElements:Array=new Array();
		
		public static function get panelManager():PanelManager {
			if (_panelManager==null) {
				_panelManager=new PanelManager();
			}//if
			return (_panelManager);
		}//get panelManager
		
		public static function set main(mainSet:Main):void { 
			//Make sure we can only set this once...
			if (_main==null) {
				_main=mainSet;
			}//if
		}//set main
		
		public static function get main():Main {
			return (_main);
		}//get main
		
		public static function set identityPanel(panelSet:IdentityPanel):void {
			_identityPanel=panelSet;
		}//get identityPanel
		
		public static function get identityPanel():IdentityPanel {
			return (_identityPanel);
		}//get identityPanel	
		
		public static function set debugPanel(panelSet:DebugPanel):void {
			_debugPanel=panelSet;
		}//get debugPanel
		
		public static function get debugPanel():DebugPanel {
			if (_debugPanel==null) {
				_debugPanel=new DebugPanel(null);
			}//if
			return (_debugPanel);
		}//get debugPanel	
		
		public static function set textChatChannel(panelSet:TextChatPanel):void {
			_textChatChannel=panelSet;
		}//get textChatChannel
		
		public static function get textChatChannel():TextChatPanel {
			return (_textChatChannel);
		}//get textChatChannel
		
		public static function set introAnimation(clipSet:IntroAnimation):void {
			if (_introAnimation==null) {
				_introAnimation=clipSet;
			}//if
		}//get debugPanel
		
		public static function get introAnimation():IntroAnimation {
			return (_introAnimation);
		}//get introAnimation	
		
		/**
		 * @return A list of all the current desktop chrome elements like the close / minimize buttons and the
		 * window drag bar. Add any UI items added to the window chrome to this array to have the application
		 * manage their visibility.		 
		 */
		public static function get desktopChromeElements():Array {
			return (_desktopChromeElements);
		}//get desktopChromeElemenets
			
		
		
		public static function get announceChannel():AnnounceChannel {
			if (_announceChannel==null) {
				_announceChannel=new AnnounceChannel();				
			}//if
			return (_announceChannel);
		}//get announceChannel	
		
		public static function set announceChannel(set:AnnounceChannel):void {
			debug("References: Setting static AnnounceChannel is not allowed.");
		}//set announceChannel		
		
		
		/**
		 * Catch-all debugging function. If the debug panel is available, messages are sent to it,
		 * otherwise trace actions are used. Update as needed.
		 *  
		 * @param msg The text to trace, or send to the debug panel.
		 * 
		 */
		public static function debug(msg:String=null):void {
			if (_debugPanel!=null) {
				_debugPanel.debug(msg);
			} else {
				trace (msg);
			}//else
		}//debug
	
		//For nice sharing between AIR and the web player
		
		public static function get NativeWindow():Class {
			return (SwagSystem.getDefinition("flash.display.NativeWindow") as Class);	
		}//get NativeWindow
		
		public static function get File():Class {
			return (SwagSystem.getDefinition("flash.filesystem.File") as Class);	
		}//get File
		
		public static function get FileMode():Class {
			return (SwagSystem.getDefinition("flash.filesystem.FileMode") as Class);	
		}//get FileMode
		
		public static function get FileFilter():Class {
			return (SwagSystem.getDefinition("flash.net.FileFilter") as Class);	
		}//get FileFilter
		
		public static function get FileStream():Class {
			return (SwagSystem.getDefinition("flash.filesystem.FileStream") as Class);	
		}//get FileStream
		
	}//Reference class
	
}//package