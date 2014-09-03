package swag.core {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import swag.interfaces.core.ISwagDebug;
		
	/**
	 * Provides debugging and introspection functionality to ActionScript applications.
	 * <p>Do not add this singleton class to the display list. Instead, set the <code>container</code> property
	 * and the debugger will add / remove itself.</p>
	 * <p>Generally speaking, the debugger is used exclusively during development time and is removed before
	 * exporting the project for release as it's possible for the debugger to expose the inner workings
	 * of your application.</p>
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
	public class SwagDebug implements ISwagDebug {		
		
		/**
		 * @private 
		 */
		private static var _container:DisplayObjectContainer=null;
		/**
		 * @private 
		 */
		private static var _stayOnTop:Boolean=new Boolean(true);		
		/**
		 * @private 
		 */
		private static var _debugDisplayContainer:Sprite;
		/**
		 * @private 
		 */
		private static var _debugText:TextField;
		/**
		 * @private
		 */
		private static var _fieldWidth:Number=300;
		/**
		 * @private  
		 */
		private static var _fieldHeight:Number=100;
		/**
		 * Adds a string message to the debug display text area.
		 *  
		 * @param debugMsg The message to add. A new line delimiter is automatically added to the end
		 * of the string unless the second parameter is <em>false</em>.
		 * @param autoNewLine If <em>true</em>, a new line delimiter is automatically added after every message.
		 * 
		 */
		public static function addMsg(debugMsg:String, autoNewLine:Boolean=true):void {
			if (_debugText==null) {
				return;
			}//if
			_debugText.appendText(debugMsg);
			if (autoNewLine) {
				_debugText.appendText("\n");	
			}//if
		}//addMsg
		
		/**
		 * Single purpose method that handles the monitoring of the containing object, its existence on the stage,
		 * and this class' position within the container's display list when everything else is correctly set up.
		 *  
		 * @param args Generic catch-all argument. The type of argument received specifies how the method behaves.
		 * 
		 * @private
		 * 
		 */
		private static function stayOnTopMonitor(... args):void {			
			if (_container==null) {				
				//Container not yet set. Nothing to do!
				return;
			}//if			
			if (_container.stage==null) {				
				//Container set but not yet added to stage.
				_container.addEventListener(Event.ADDED_TO_STAGE, stayOnTopMonitor);
				return;
			}//if
			if (args[0] is Event) {				
				var eventObj:Event=args[0] as Event;
				if (eventObj.type==Event.ADDED_TO_STAGE) {					
					//Container has been added to the stage. Start the monitor.
					_container.removeEventListener(Event.ADDED_TO_STAGE, stayOnTopMonitor);
					_container.addEventListener(Event.ENTER_FRAME, stayOnTopMonitor);
					createDebugger();
				} else if (eventObj.type==Event.ENTER_FRAME) {
					if (_container!=null) {
						pushToTop();						
					} else {
						stayOnTopMonitor();
					}//else
					if (_debugText.width!=_fieldWidth) {
						_debugText.width=_fieldWidth;
					}//if
					if (_debugText.height!=_fieldHeight) {
						_debugText.height=_fieldHeight;
					}//if
				} else if (eventObj.type==Event.REMOVED_FROM_STAGE) {
					_container.removeEventListener(Event.ENTER_FRAME, stayOnTopMonitor);
					_container=null;
					return;
				} else {
					
				}//else
			} else if (args[0]==undefined) {
				if (_container!=null) {
					_container.addEventListener(Event.ADDED_TO_STAGE, stayOnTopMonitor);
				}//if
			}//else if			
		}//stayOnTopMonitor		
		
		/**
		 * @private 		 
		 */
		private static function createDebugger():void {			
			if (_container==null) {
				return;
			}//if
			if (_debugDisplayContainer==null) {
				_debugDisplayContainer=new Sprite();
			}//if
			if (_debugText==null) {
				_debugText=new TextField();				
				_debugText.border=true;
				_debugText.background=true;
				_debugDisplayContainer.addChild(_debugText);
			}//if			
			_container.addChild(_debugDisplayContainer);			
		}//createDebugger
		
		/**
		 * @private
		 */
		private static function pushToTop():void {
			if (_container==null) {
				return;
			}//if
			if (stayOnTop==false) {
				return;
			}//if
			var thisIndex:int=_container.getChildIndex(_debugDisplayContainer);
			if (thisIndex<(_container.numChildren-1)) {
				_container.setChildIndex(_debugDisplayContainer, (_container.numChildren-1));
			}//if
		}//pushToTop
		
		/**
		 * The containing <code>DisplayObjectContainer</code> instance into which the debugger displays its output. 
		 * Usually this will be a reference to the <code>stage</code> instance, but this is not a requirement.
		 * 
		 */
		public static function set container(containerSet:DisplayObjectContainer):void {			
			_container=containerSet;
			stayOnTopMonitor();
		}//set container
		
		public static function get container():DisplayObjectContainer {
			return (_container);
		}//get container
		
		/**
		 * The width, in pixels, of the debug message TextField instance. 		 		 
		 */
		public static function set width(widthSet:Number):void {
			_fieldWidth=widthSet;
		}//set width
		
		public static function get width():Number {
			if (_debugText!=null) {
				return(_fieldWidth);
			} else {
				return (0);
			}//else
		}//get width
		
		/**
		 * The height, in pixels, of the debug message TextField instance. 		 		 
		 */		
		public static function set height(heightSet:Number):void {
			_fieldHeight=heightSet;
		}//set height
		
		public static function get height():Number {
			if (_debugText!=null) {
				return(_fieldHeight);
			} else {
				return (0);
			}//else
		}//get height
		
		/**
		 *  
		 * If <em>true</em>, the debug display will be maintained on top of all the other display objects
		 * in the containing display object container, otherwise no automatic depth / index management
		 * is done.
		 * 
		 */
		public static function set stayOnTop(staySet:Boolean):void {
			_stayOnTop=staySet;
			stayOnTopMonitor();
		}//set stayOnTop
		
		public static function get stayOnTop():Boolean {
			return (_stayOnTop);
		}//get stayOnTop		
		
	}//SwagDebug class
	
}//package