package socialcastr.ui {
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.None;
	import fl.transitions.easing.Strong;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.utils.getTimer;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.events.PanelEvent;
	import socialcastr.interfaces.ui.IPanel;
	import socialcastr.interfaces.ui.IPanelContent;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.core.instances.SwagMovieClip;
	import swag.core.instances.SwagSequence;
	import swag.events.SwagSequenceEvent;
	
	/*
	 * Manages the functionality and content of a single panel within PanelManager.
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
	public class Panel extends MovieClip implements IPanel {
		
		private const defaultPanelAnimationSpeed:Number=0.7;
		
		private var _content:IPanelContent;
		private var _panelContentClass:Class=null;
		private var _contextXAdjust:Number;
		private var _contextYAdjust:Number;	
		private var _originalXPosition:Number;
		private var _originalYPosition:Number;
		private var _restoreXPosition:Number;
		private var _restoreYPosition:Number;
		private var _restoreXRotation:Number;
		private var _restoreYRotation:Number;
		private var _animationDelay:SwagSequence;
		private var _motionBlurFilter:BlurFilter;
		private var _horizontalTween:Tween;
		private var _verticalTween:Tween;
		private var _horizontalRotationTween:Tween;
		private var _verticalRotationTween:Tween;
		private var _alphaTween:Tween;
		private var _playback:SwagMovieClip=null;
		private var _panelActive:Boolean=false;		
		private var _panelSuspended:Boolean=false;
		private var _mouseMotionInitX:Number;
		private var _mouseMotionInitY:Number;
		private var _primaryMotionDirection:String=new String("");
		private var _motionPercentCompleted:Number=0;
		private var _motionMonitorTimeStamp:int=0;
		private var _clickedOnPanelBackground:Boolean=false; //Prevents clicks intended for the main menu to be processed as a "restoreToShow" action
		private var _panelIsSilent:Boolean=false;
		//Panel attached to this one during a swipe operation (panel being revealed or opened);
		private var _chainedPanel:Panel=null;				
		
		private static var _panels:Vector.<Panel>=new Vector.<Panel>();
		private static var _modalPanelActive:Boolean=false;
		private static var _restorePanel:String=new String("");
		
		public function Panel(panelContentClass:Class)	{
			this._panelContentClass=panelContentClass;			
			this.setDefaults();
			this.addListeners();
			this.createPanelContent();
			super();
		}//constructor
		
		private function createPanelContent():IPanelContent {
			if (this._panelContentClass!=null) {
				this._content=new this._panelContentClass(this);
				this._content.parentPanel=this;
			}//if							
			this.storeContentDimensions();
			this.alignPanelContent();			
			return (this._content);
		}//createPanelContent
						
		private function storeContentDimensions():void {
			if (this.contentDisplayObject!=null) {
				this._contextXAdjust=this.contentDisplayObject.width/2;
				this._contextYAdjust=this.contentDisplayObject.height/2;
			}//if
		}//storeContentDimensions		
				
		private function alignPanelContent():void {
			if (this.contentDisplayObject!=null) {
				this.contentDisplayObject.x-=this._contextXAdjust;
				this.contentDisplayObject.y-=this._contextYAdjust;
			}//if
		}//alignPanelContent
		
		/**
		 * @param value The X position of the panel, adjusted for the dimensions of the content to allow
		 * for 3D transformation around the content's center point.
		 */
		public override function set x(value:Number):void {			
			super.x=value+this._contextXAdjust;		
		}//set x
		
		/**		 
		 * @private 		 
		 */
		public override function get x():Number {
			return (super.x-this._contextXAdjust);			
		}//get x
		
		/**
		 * @param value The Y position of the panel, adjusted for the dimensions of the content to allow
		 * for 3D transformation around the content's center point.
		 */
		public override function set y(value:Number):void {
			super.y=value+this._contextYAdjust;
		}//set y
				
		/**		 
		 * @private 		 
		 */
		public override function get y():Number {
			return (super.y-this._contextYAdjust);			
		}//get y
		
		public function get panelName():String {
			if (this.content.panelData!=null) {
				var panelData:XML=this.content.panelData;
				if (SwagDataTools.isXML(panelData.@name)) {
					return (String(panelData.@name));
				}//if
			}//if
			return ("");
		}//get panelName
		
		public function get panelID():String {			
			if (this.content.panelData!=null) {
				var panelData:XML=this.content.panelData;
				if (SwagDataTools.isXML(panelData.@id)) {
					return (String(panelData.@id));
				}//if
			}//if
			return ("");
		}//get panelID
		
		private function parsePositionData():void {			
			var panelData:XML=this.content.panelData;
			if (SwagDataTools.hasData(panelData.@x)) {
				var xString:String=String(panelData.@x);				
				this._originalXPosition=Number(xString);
			}//if
			if (SwagDataTools.hasData(panelData.@y)) {
				var yString:String=String(panelData.@y);				
				this._originalYPosition=Number(yString);
			}//if
		}//parsePositionData
		
		public function playVerticalAnimation(... args):void {				
			if (this._animationDelay!=null) {
				this._animationDelay.stop();
				this._animationDelay=null;
			}//if
			if (this._verticalTween!=null) {					
				this._verticalTween.rewind(0);	
				this._verticalTween.resume();
				this.play();
			}//if
			if (this._verticalRotationTween!=null) {				
				this._verticalRotationTween.rewind(0);
				this._verticalRotationTween.resume();
				this.play();
			}//if
			if (this._alphaTween!=null) {
				this._alphaTween.rewind(0);
				this._alphaTween.resume();									
				this.play();
			}//if
			this.startMotionMonitor();
		}//playVerticalAnimation
		
		public function playHorizontalAnimation(... args):void {
			if (this._animationDelay!=null) {
				this._animationDelay.stop();
				this._animationDelay=null;
			}//if
			if (this._horizontalTween!=null) {				
				this._horizontalTween.rewind(0);
				this._horizontalTween.resume();
				this.play();
			}//if
			if (this._horizontalRotationTween!=null) {						
				this._horizontalRotationTween.rewind(0);
				this._horizontalRotationTween.resume();
				this.play();
			}//if
			if (this._alphaTween!=null) {								
				this._alphaTween.resume();
				this._alphaTween.rewind(0);
				this.play();
			}//if
			this.startMotionMonitor();
		}//playHorizontalAnimation
		
		public function updateHorizontalAnimation(timeValue:Number):void {
			if (this._animationDelay!=null) {
				this._animationDelay.stop();
				this._animationDelay=null;
			}//if
			if (this._horizontalTween!=null) {				
				this._horizontalTween.time=timeValue;
			}//if
			if (this._horizontalRotationTween!=null) {
				this._horizontalRotationTween.time=timeValue;				
			}//if
			if (this._alphaTween!=null) {
				this._alphaTween.time=timeValue;
			}//if
		}//updateHorizontalAnimation
		
		private function startMotionMonitor(... args):void {
			this.stopMotionMonitor();
			this._motionMonitorTimeStamp=getTimer();
			this.addEventListener(Event.ENTER_FRAME, this.motionMonitor);
		}//startMotionMonitor
		
		private function stopMotionMonitor(... args):void {
			this.removeEventListener(Event.ENTER_FRAME, this.motionMonitor);
		}//stopMotionMonitor
		
		private function motionMonitor(eventObj:Event):void {
			//removeAllTweenListeners
			var timeElapsed:Number=Number(getTimer()-this._motionMonitorTimeStamp)/1000;
			this._motionMonitorTimeStamp=getTimer();
			var tweenActive:Boolean=false;			
			if (this._horizontalTween!=null) {				
				if (this._horizontalTween.position==this._horizontalTween.finish) {					
					this._horizontalTween.stop();
					this._horizontalTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
					this._horizontalTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
					this._horizontalTween=null;
				} else {
					this._horizontalTween.resume();					
					tweenActive=true;
				}//else
			}//if
			if (this._horizontalRotationTween!=null) {				
				if (this._horizontalRotationTween.position==this._horizontalRotationTween.finish) {					
					this._horizontalRotationTween.stop();
					this._horizontalRotationTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
					this._horizontalRotationTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
					this._horizontalRotationTween=null;
				} else {
					this._horizontalRotationTween.resume();					
					tweenActive=true;
				}//else
			}//if
			if (this._verticalTween!=null) {				
				if (this._verticalTween.position==this._verticalTween.finish) {					
					this._verticalTween.stop();
					this._verticalTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
					this._verticalTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
					this._verticalTween=null;
				} else {
					this._verticalTween.resume();					
					tweenActive=true;
				}//else
			}//if
			if (this._verticalRotationTween!=null) {				
				if (this._verticalRotationTween.position==this._verticalRotationTween.finish) {					
					this._verticalRotationTween.stop();
					this._verticalRotationTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
					this._verticalRotationTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
					this._verticalRotationTween=null;
				} else {
					this._verticalRotationTween.resume();					
					tweenActive=true;
				}//else
			}//if
			if (this._alphaTween!=null) {				
				if (this._alphaTween.position==this._alphaTween.finish) {					
					this._alphaTween.stop();
					this._alphaTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
					this._alphaTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
					if (this.alpha==0) {
						this.onHideDone(new TweenEvent(TweenEvent.MOTION_FINISH, this._alphaTween.time, this._alphaTween.position));
					} else {
						this.onShowDone(new TweenEvent(TweenEvent.MOTION_FINISH, this._alphaTween.time, this._alphaTween.position));
					}//else
					this._alphaTween=null;
				} else {
					this._alphaTween.resume();					
					tweenActive=true;
				}//else
			}//if
			if (!tweenActive) {
				this.stopMotionMonitor();
			}//if
		}//motionMonitor
		
		public function updateVerticalAnimation(timeValue:Number):void {			
			if (this._animationDelay!=null) {
				this._animationDelay.stop();
				this._animationDelay=null;
			}//if
			if (this._verticalTween!=null) {					
				this._verticalTween.time=timeValue;
			}//if
			if (this._verticalRotationTween!=null) {
				this._verticalRotationTween.time=timeValue;				
			}//if
			if (this._alphaTween!=null) {
				this._alphaTween.time=timeValue;
			}//if
		}//updateVerticalAnimation
		
		public function clearAllAnimations():void {
			if (this._animationDelay!=null) {
				this._animationDelay.stop();
				this._animationDelay=null;
			}//if
			if (this._horizontalTween!=null) {
				this._horizontalTween.stop();
				this._horizontalTween=null;
			}//if
			if (this._horizontalRotationTween!=null) {
				this._horizontalRotationTween.stop();
				this._horizontalRotationTween=null;
			}//if
			if (this._verticalTween!=null) {				
				this._verticalTween.stop();
				this._verticalTween=null;
			}//if
			if (this._verticalRotationTween!=null) {
				this._verticalRotationTween.stop();
				this._verticalRotationTween=null;
			}//if
			if (this._alphaTween!=null) {
				this._alphaTween.stop();
				this._alphaTween=null;
			}//if
		}//clearAllAnimations
		
		public function suspend(hideDirection:String):void {			
			if (modalPanelActive) {
				return;
			}//if
			this._panelSuspended=true;
			this.hide(hideDirection);
		}//suspend
		
		public function resume(showDirection:String):void {
			if (modalPanelActive) {
				return;
			}//if
			if (this._panelSuspended) {
				this.show(showDirection);
			}//if
		}//resume		
		
		public function onShowDone(eventObj:TweenEvent):void {
			if (this._alphaTween!=null) {
				this._alphaTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
			}//if			
			this._panelActive=true;
			this._panelSuspended=false;
			this.cacheAsBitmap=false;		
			var panelEvent:PanelEvent=new PanelEvent(PanelEvent.ONSHOW);
			SwagDispatcher.dispatchEvent(panelEvent, this);			
			this.addSwipeHandlers();
			if (this.content!=null) {
				this.content.onShowDone();
			}//if
		}//onShowDone
		
		public function onHideDone(eventObj:TweenEvent):void {
			if (this._alphaTween!=null) {
				this._alphaTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
			}//if			
			_restorePanel=this.panelID;
			this._panelActive=false;
			var panelEvent:PanelEvent=new PanelEvent(PanelEvent.ONHIDE);
			SwagDispatcher.dispatchEvent(panelEvent, this);			
			this.removeSwipeHandlers();
			if (this.content!=null) {
				this.content.onHideDone();
			}//if
		}//onHideDone
		
		/**
		 * Currently disabled (needs work!).
		 * 
		 * Checks the dimensions of the host window (if this is an AIR application) to ensure that if the content grows
		 * larger than the containing window, the window is stretched out. If this is a mobile application, the listener
		 * is removed from the host tweening object and the method ends (no resizing will take place).
		 * 
		 * @param eventObj A TweenEvent object.
		 * 
		 * 
		 * 
		 */
		private function checkAppWindowDimensions(eventObj:TweenEvent):void {
			if (SwagSystem.isMobile) {
				//Remove listener from any source!
				eventObj.target.removeEventListener(eventObj.type, this.checkAppWindowDimensions);
				return;
			}//if
			if (!SwagSystem.isAIR) {
				//Maybe we can support resizing the container in HTML in the future, but not now.
				eventObj.target.removeEventListener(eventObj.type, this.checkAppWindowDimensions);
				return;
			}//if
			try {
				var nativeWindow:*=this.stage["nativeWindow"];			
				if (nativeWindow==null) {				
					eventObj.target.removeEventListener(eventObj.type, this.checkAppWindowDimensions);
					return;
				}//if
				this.stage.scaleMode=StageScaleMode.NO_SCALE; //Extremely important!
				if (nativeWindow.width<this.width) {				
					nativeWindow.width=this.stage.width;
				}//if	
				if (nativeWindow.height<this.height) {				
					nativeWindow.height=this.stage.height;					
				}//if
			} catch (e:*) {
				trace ("Panel.checkAppWindowDimensions(): tried to access the stage.nativeWindow object and failed. Wrong runtime!");
			}//catch
		}//checkAppWindowDimensions
		
		/**
		 * Shows the panel in the direction (style) specified, at a specified speed, and with a specified delay.
		 *  
		 * @param showStyle The style or direction in which to show the panel. This string is not case sensitive
		 * and will be stripped of any extraneous space or saparator characters. Valid values are "fromtop", "fromleft",
		 * "fromright", and "frombottom". If the string specified does not match one of these patterns, the panel is simply
		 * shown by setting all transforms to 0 and alpha to 1, visible to true. 
		 * @param speed The speed, in seconds, in which to display the panel. If omitted, the defaultPanelAnimationSpeed constant
		 * is assumed.
		 * @param delay The delay, in seconds, to wait before showing the panel. If 0, the panel is shown immediately. If less than 0,
		 * no animation takes place and the <code>playHorizontalAnimation</code> or <code>playVerticalAnimation</code> methods must
		 * be called manually -- the method to invoke depends on the direction of the <code>showStyle</code> parameter.
		 * @param easing The easing equation to use for the animation. If not specified, the <code>Strong.easeInOut</code> function is
		 * used bu default.
		 * 
		 */
		public function show(showStyle:String="", speed:Number=this.defaultPanelAnimationSpeed, delay:Number=0, easing:Function=null):void {
			if (modalPanelActive) {				
				return;
			}//if
			if (this.isModal) {				
				_modalPanelActive=true;
			}//if
			if (this._animationDelay!=null) {
				this._animationDelay.stop();
				this._animationDelay=null;
			}//if
			if (this._verticalTween!=null) {				
				this._verticalTween.stop();
				this._verticalTween=null;
			}//if	
			if (this._verticalRotationTween!=null) {
				this._verticalRotationTween.stop();
				this._verticalRotationTween=null;
			}//if	
			if (this._horizontalTween!=null) {
				this._horizontalTween.stop();
				this._horizontalTween=null;
			}//if	
			if (this._horizontalRotationTween!=null) {
				this._horizontalRotationTween.stop();
				this._horizontalRotationTween=null;
			}//if	
			var showStyleString:String=new String();
			showStyleString=showStyle;
			showStyleString=showStyleString.toLowerCase();
			if (easing==null) {
				easing=Strong.easeInOut;
			}//if
			this.clearAllAnimations();
			if (this.content!=null) {
				this.content.onShow();
			}//if
			switch (showStyleString) {
				default: 						
					if (!SwagSystem.isMobile) {
						this.rotationX=0;
						this.rotationY=0;
						this.rotationZ=0;
					}//if
					this._restoreXPosition=this.x;
					this._restoreYPosition=this.y;
					this._restoreXRotation=this.rotationX;
					this._restoreYRotation=this.rotationY;
					this.x=this._originalXPosition;
					this.y=this._originalYPosition;	
					this.alpha=1;
					this.visible=true;					
					break;
				case "fromtop":					
					this.x=this._originalXPosition;
					this.y=this._originalYPosition;						
					this.y-=this.contentDisplayObject.height;
					this._restoreXPosition=this.x;
					this._restoreYPosition=this.y;
					this._restoreXRotation=this.rotationX;
					this._restoreYRotation=this.rotationY;
					this.alpha=1;
					this.visible=true;
					this._verticalTween=new Tween(this, "y", easing, this.y, this._originalYPosition, speed, true);					
					this._verticalTween.stop();
					if (!SwagSystem.isMobile) {
						this.rotationX=-90;	
						this.rotationY=0;
						this._verticalRotationTween=new Tween(this, "rotationX", easing, this.rotationX, 0 , speed, true);
						this._verticalRotationTween.stop();
					}//if
					this._alphaTween=new Tween(this, "alpha", easing, 0, 1 , speed, true);
					this._alphaTween.stop();
					this._alphaTween.addEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
					//this._alphaTween.addEventListener(TweenEvent.MOTION_CHANGE, this.checkAppWindowDimensions);
					if (delay > 0) {
						this._animationDelay=new SwagSequence(this.playVerticalAnimation, delay);
						this._animationDelay.start();
					} else if (delay==0) {
						this.playVerticalAnimation();
					}//else
					break;
				case "fromleft":					
					this.x=this._originalXPosition;
					this.y=this._originalYPosition;	
					this.x-=this.contentDisplayObject.width;
					this._restoreXPosition=this.x;
					this._restoreYPosition=this.y;
					this._restoreXRotation=this.rotationX;
					this._restoreYRotation=this.rotationY;
					this.alpha=0;
					this.visible=true;
					this._horizontalTween=new Tween(this, "x", easing, this.x, this._originalXPosition, speed, true);
					this._horizontalTween.stop();
					if (!SwagSystem.isMobile) {
						this.rotationX=0;
						this.rotationY=90;
						this._horizontalRotationTween=new Tween(this, "rotationY", easing, this.rotationY, 0 , speed, true);
						this._horizontalRotationTween.stop();
					}//if
					this._alphaTween=new Tween(this, "alpha", easing, 0, 1 , speed, true);
					this._alphaTween.stop();
					this._alphaTween.addEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
					//this._alphaTween.addEventListener(TweenEvent.MOTION_CHANGE, this.checkAppWindowDimensions);
					if (delay > 0) {
						this._animationDelay=new SwagSequence(this.playHorizontalAnimation, delay);
						this._animationDelay.start();
					} else if (delay==0) {
						this.playHorizontalAnimation();
					}//else
					break;
				case "frombottom":					
					this.x=this._originalXPosition;
					this.y=this._originalYPosition;										
					this.y+=this.contentDisplayObject.height;
					this._restoreXPosition=this.x;
					this._restoreYPosition=this.y;
					this._restoreXRotation=this.rotationX;
					this._restoreYRotation=this.rotationY;
					this.alpha=0;
					this.visible=true;
					this._verticalTween=new Tween(this, "y", easing, this.y, this._originalYPosition, speed, true);
					this._verticalTween.stop();
					if (!SwagSystem.isMobile) {
						this.rotationX=90;		
						this.rotationY=0;
						this._verticalRotationTween=new Tween(this, "rotationX", easing, this.rotationX, 0 , speed, true);
						this._verticalRotationTween.stop();
					}//if
					this._alphaTween=new Tween(this, "alpha", easing, 0, 1 , speed, true);
					this._alphaTween.stop();
					this._alphaTween.addEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
					//this._alphaTween.addEventListener(TweenEvent.MOTION_CHANGE, this.checkAppWindowDimensions);
					if (delay > 0) {
						this._animationDelay=new SwagSequence(this.playVerticalAnimation, delay);
						this._animationDelay.start();
					} else if (delay==0) {
						this.playVerticalAnimation();
					}//else
					break;
				case "fromright":					
					this.x=this._originalXPosition;
					this.y=this._originalYPosition;
					this.x+=this.contentDisplayObject.width;
					this._restoreXPosition=this.x;
					this._restoreYPosition=this.y;
					this._restoreXRotation=this.rotationX;
					this._restoreYRotation=this.rotationY;
					this.alpha=0;
					this.visible=true;
					this._horizontalTween=new Tween(this, "x", easing, this.x, this._originalXPosition, speed, true);
					this._horizontalTween.stop();
					if (!SwagSystem.isMobile) {
						this.rotationX=0;
						this.rotationY=-90;
						this._horizontalRotationTween=new Tween(this, "rotationY", easing, this.rotationY, 0 , speed, true);
						this._horizontalRotationTween.stop();
					}//if
					this._alphaTween=new Tween(this, "alpha", easing, 0, 1 , speed, true);
					this._alphaTween.stop();
					this._alphaTween.addEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
					//this._alphaTween.addEventListener(TweenEvent.MOTION_CHANGE, this.checkAppWindowDimensions);
					if (delay > 0) {
						this._animationDelay=new SwagSequence(this.playHorizontalAnimation, delay);
						this._animationDelay.start();
					} else if (delay==0) {
						this.playHorizontalAnimation();
					}//else
					break;
			}//switch			
		}//show
		
		/**
		 * Hides the panel in the direction (style) specified, at a specified speed, and with a specified delay.
		 *  
		 * @param hideStyle The style or direction in which to hide the panel. This string is not case sensitive
		 * and will be stripped of any extraneous space or saparator characters. Valid values are "totop", "toleft",
		 * "toright", and "tobottom". If the string specified does not match one of these patterns, the panel is simply
		 * hidden by setting alpha to 0 and visible to false. 
		 * @param speed The speed, in seconds, in which to display the panel. If omitted, the defaultPanelAnimationSpeed constant
		 * is assumed.
		 * @param delay The delay, in seconds, to wait before hiding the panel. If 0, the panel is hidden immediately. If less than 0,
		 * no animation takes place and the <code>playHorizontalAnimation</code> or <code>playVerticalAnimation</code> methods must
		 * be called manually -- the method to invoke depends on the direction of the <code>hideStyle</code> parameter.
		 * @param easing The easing equation to use for the animation. If not specified, the <code>Strong.easeInOut</code> function is
		 * used bu default.
		 * 
		 */
		public function hide(hideStyle:String="", speed:Number=this.defaultPanelAnimationSpeed, delay:Number=0, easing:Function=null):void {				
			if (this._animationDelay!=null) {
				this._animationDelay.stop();
				this._animationDelay=null;
			}//if
			if (this._verticalTween!=null) {
				this._verticalTween.stop();
				this._verticalTween=null;
			}//if	
			if (this._verticalRotationTween!=null) {
				this._verticalRotationTween.stop();
				this._verticalRotationTween=null;
			}//if	
			if (this._horizontalTween!=null) {
				this._horizontalTween.stop();
				this._horizontalTween=null;
			}//if	
			if (this._horizontalRotationTween!=null) {
				this._horizontalRotationTween.stop();
				this._horizontalRotationTween=null;
			}//if			
			var hideStyleString:String=new String();
			hideStyleString=hideStyle;
			hideStyleString=hideStyleString.toLowerCase();	
			if (easing==null) {
				easing=Strong.easeInOut;
			}//if
			this.clearAllAnimations();
			if (this.content!=null) {
				this.content.onHide();
			}//if
			switch (hideStyleString) {
				default:					
					this.alpha=0;
					this.visible=false;
					break;
				case "totop":					
					this.x=this._originalXPosition;
					this.y=this._originalYPosition;
					var targetPosition:Number=this.y-this.contentDisplayObject.height;					
					this._restoreXPosition=this.x;
					this._restoreYPosition=this.y;
					this._restoreXRotation=this.rotationX;
					this._restoreYRotation=this.rotationY;
					this.alpha=1;
					this.visible=true;
					this._verticalTween=new Tween(this, "y", easing, this._originalYPosition, targetPosition, speed, true);					
					this._verticalTween.stop();
					if (!SwagSystem.isMobile) {
						this.rotationX=0;
						this._verticalRotationTween=new Tween(this, "rotationX", easing, this.rotationX, -90 , speed, true);
						this._verticalRotationTween.stop();
					}//if
					this._alphaTween=new Tween(this, "alpha", easing, 1, 0 , speed, true);
					this._alphaTween.stop();
					this._alphaTween.addEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
					//this._alphaTween.addEventListener(TweenEvent.MOTION_CHANGE, this.checkAppWindowDimensions);
					if (delay > 0) {
						this._animationDelay=new SwagSequence(this.playVerticalAnimation, delay);
						this._animationDelay.start();
					} else if (delay==0) {						
						this.playVerticalAnimation();
					}//else
					break;
				case "toleft":					
					this.x=this._originalXPosition;
					this.y=this._originalYPosition;
					this._restoreXPosition=this.x;
					this._restoreYPosition=this.y;
					this._restoreXRotation=this.rotationX;
					this._restoreYRotation=this.rotationY;
					targetPosition=this.x-this.contentDisplayObject.width;
					this.alpha=1;
					this.visible=true;
					this._horizontalTween=new Tween(this, "x", easing, this.x, targetPosition, speed, true);
					this._horizontalTween.stop();
					if (!SwagSystem.isMobile) {
						this.rotationY=0;
						this._horizontalRotationTween=new Tween(this, "rotationY", easing, this.rotationY, 90 , speed, true);
						this._horizontalRotationTween.stop();
					}//if
					this._alphaTween=new Tween(this, "alpha", easing, 1, 0 , speed, true);
					this._alphaTween.stop();
					this._alphaTween.addEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
					//this._alphaTween.addEventListener(TweenEvent.MOTION_CHANGE, this.checkAppWindowDimensions);
					if (delay > 0) {
						this._animationDelay=new SwagSequence(this.playHorizontalAnimation, delay);
						this._animationDelay.start();
					} else if (delay==0) {
						this.playHorizontalAnimation();
					}//else
					break;
				case "tobottom":						
					this.x=this._originalXPosition;
					this.y=this._originalYPosition;
					this._restoreXPosition=this.x;
					this._restoreYPosition=this.y;
					this._restoreXRotation=this.rotationX;
					this._restoreYRotation=this.rotationY;
					targetPosition=this.y+this.contentDisplayObject.height;					
					this.alpha=1;
					this.visible=true;
					this._verticalTween=new Tween(this, "y", easing, this.y, targetPosition, speed, true);
					this._verticalTween.stop();
					if (!SwagSystem.isMobile) {
						this.rotationX=0;
						this._verticalRotationTween=new Tween(this, "rotationX", easing, this.rotationX, 90 , speed, true);
						this._verticalRotationTween.stop();
					}//if
					this._alphaTween=new Tween(this, "alpha", easing, 1, 0 , speed, true);
					this._alphaTween.stop();
					this._alphaTween.addEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
					//this._alphaTween.addEventListener(TweenEvent.MOTION_CHANGE, this.checkAppWindowDimensions);
					if (delay > 0) {
						this._animationDelay=new SwagSequence(this.playVerticalAnimation, delay);
						this._animationDelay.start();
					} else if (delay==0) {
						this.playVerticalAnimation();
					}//else
					break;
				case "toright":					
					this.x=this._originalXPosition;
					this.y=this._originalYPosition;
					this._restoreXPosition=this.x;
					this._restoreYPosition=this.y;
					this._restoreXRotation=this.rotationX;
					this._restoreYRotation=this.rotationY;
					targetPosition=this.x+this.contentDisplayObject.width;
					this.alpha=1;
					this.visible=true;
					this._horizontalTween=new Tween(this, "x", easing, this.x, targetPosition, speed, true);
					this._horizontalTween.stop();
					if (!SwagSystem.isMobile) {
						this.rotationY=0;
						this._horizontalRotationTween=new Tween(this, "rotationY", easing, this.rotationY, -90 , speed, true);
						this._horizontalRotationTween.stop();
					}//if
					this._alphaTween=new Tween(this, "alpha", easing, 1, 0 , speed, true);
					this._alphaTween.stop();
					this._alphaTween.addEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
					//this._alphaTween.addEventListener(TweenEvent.MOTION_CHANGE, this.checkAppWindowDimensions);
					if (delay > 0) {
						this._animationDelay=new SwagSequence(this.playHorizontalAnimation, delay);
						this._animationDelay.start();
					} else if (delay==0) {
						this.playHorizontalAnimation();
					}//else
					break;
			}//switch
		}//hide
		
		public static function getPanelsByID(id:String, inactiveOnly:Boolean=false):Array {
			var returnArray:Array=new Array();
			if ((id=="") || (id==null)) {
				return (returnArray);	
			}//if
			for (var count:uint=0; count<_panels.length; count++) {
				var currentPanel:Panel=_panels[count] as Panel;
				if (id==currentPanel.panelID) {
					if (inactiveOnly) {
						if (currentPanel.active==false) {
							returnArray.push(currentPanel);	
						}//if
					} else {				
						returnArray.push(currentPanel);
					}//if
				}//if
			}//for
			return (returnArray);
		}//getPanelsByID
		
		public static function getPanelsByName(name:String, inactiveOnly:Boolean=false):Array {
			var returnArray:Array=new Array();
			if ((name=="") || (name==null)) {
				return (returnArray);	
			}//if
			for (var count:uint=0; count<_panels.length; count++) {
				var currentPanel:Panel=_panels[count] as Panel;
				if (name==currentPanel.panelID) {
					if (inactiveOnly) {
						if (currentPanel.active==false) {
							returnArray.push(currentPanel);	
						}//if
					} else {				
						returnArray.push(currentPanel);
					}//if
				}//if
			}//for
			return (returnArray);
		}//getPanelsByName
		
		public function get defaultShowDirection():String {
			if (this.content.panelData!=null) {
				var panelData:XML=this.content.panelData;
				if (SwagDataTools.isXML(panelData.@show)) {
					var returnShowDirection:String=new String(panelData.@show);
					returnShowDirection=returnShowDirection.toLowerCase();
					returnShowDirection=SwagDataTools.stripChars(returnShowDirection, SwagDataTools.SEPARATOR_RANGE);
					switch (returnShowDirection) {
						case "top": 
							returnShowDirection="fromtop";
							break;
						case "bottom": 
							returnShowDirection="frombottom";
							break;
						case "left": 
							returnShowDirection="fromleft";
							break;
						case "right": 
							returnShowDirection="fromright";
							break;
						default: 
							if (returnShowDirection=="") {
								returnShowDirection="fromright";
							}//if
							break;
					}//switch
					return (returnShowDirection);
				} else {
					return ("fromright");
				}//else
			}//if
			return ("fromright");
		}//get defaultShowDirection
		
		public function get defaultHideDirection():String {
			switch (this.defaultShowDirection) {
				case "fromtop" :
					return ("totop");
					break;
				case "frombottom" :
					return ("tobottom");
					break;
				case "fromleft" :
					return ("toleft");
					break;
				case "fromright" :
					return ("toright");
					break;
				default: 
					return ("toleft");
					break;
			}//switch
			return ("toleft");
		}//get defaultHideDirection
		
		public function get oppositeHideDirection():String {
			switch (this.defaultShowDirection) {
				case "fromtop" :
					return ("tobottom");
					break;
				case "frombottom" :
					return ("totop");
					break;
				case "fromleft" :
					return ("toright");
					break;
				case "fromright" :
					return ("toleft");
					break;
				default: 
					return ("toright");
					break;
			}//switch
			return ("toright");
		}//get oppositeHideDirection
		
		public function get oppositeShowDirection():String {
			switch (this.defaultShowDirection) {
				case "fromtop" :
					return ("frombottom");
					break;
				case "frombottom" :
					return ("fromtop");
					break;
				case "fromleft" :
					return ("fromright");
					break;
				case "fromright" :
					return ("fromleft");
					break;
				default: 
					return ("fromright");
					break;
			}//switch
			return ("fromright");
		}//get oppositeShowDirection
		
		private function onMousePress(eventObj:MouseEvent):void {			
			if (this.handlesMouseEvents(eventObj.target)) {
				this._clickedOnPanelBackground=false;
				return;
			} //if
			this._clickedOnPanelBackground=true;
			this._mouseMotionInitX=eventObj.stageX;
			this._mouseMotionInitY=eventObj.stageY;
			this._primaryMotionDirection="";
			this.clearAllAnimations();
			if (!SwagSystem.isMobile) {
				this.rotationX=0;
				this.rotationY=0;
			}//if
			this.alpha=1;
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMotion);
		}//onMousePress
		
		private function handlesMouseEvents(targetObject:*):Boolean {			
			if (targetObject==null) {
				return (false);
			}//if
			if ((targetObject is EventDispatcher)==false) {
				return (false);
			}//if
			if (targetObject is TextField) {
				return (true);
			}//if
			if (targetObject.hasEventListener(MouseEvent.CLICK)) {
				return (true);
			}//if
			if (targetObject.hasEventListener(MouseEvent.DOUBLE_CLICK)) {
				return (true);
			}//if			
			if (targetObject.hasEventListener(MouseEvent.MOUSE_DOWN)) {
				return (true);
			}//if
			if (targetObject.hasEventListener(MouseEvent.MOUSE_UP)) {
				return (true);
			}//if
			if (targetObject.hasEventListener(MouseEvent.MOUSE_MOVE)) {
				return (true);
			}//if
			if (targetObject.hasEventListener(MouseEvent.MOUSE_OVER)) {
				return (true);
			}//if
			if (targetObject.hasEventListener(MouseEvent.MOUSE_OUT)) {
				return (true);
			}//if
			if (targetObject.hasEventListener(MouseEvent.MOUSE_WHEEL)) {
				return (true);
			}//if			
			return (false);
		}//handlesMouseEvents
		
		private function onMouseRelease(eventObj:MouseEvent):void {
			if (!this._clickedOnPanelBackground) {
				//Avoids launching a "revert" operation if a user clicks on something other than the background (the menu, for example).
				//Without this the panel believes it's been clicked on and won't properly hide.
				this._mouseMotionInitX=eventObj.stageX;
				this._mouseMotionInitY=eventObj.stageY;		
				this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMotion);			
				return;
			}//if
			this._mouseMotionInitX=eventObj.stageX;
			this._mouseMotionInitY=eventObj.stageY;		
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMotion);
			if (this._motionPercentCompleted>0.5) {
				//User let go and panel is more than halfway (complete)...
				this.completeHide();
				if (this._chainedPanel!=null) {
					this._chainedPanel.completeShow();
				}//if
			} else {				
				//User let go and panel is less than halfway (restore)...
				this.restoreToShow();	
				if (this._chainedPanel!=null) {
					this._chainedPanel.restoreToHide();
				}//if
			}//else
			this._primaryMotionDirection="";
		}//onMouseRelease
		
		private function onMouseMotion(eventObj:MouseEvent):void {
			if ((this._primaryMotionDirection=="") || (this._primaryMotionDirection==null)) {
				//Primary motion hasn't been established yet. Calculate which direction user has initiated movement in...
				var hDelta:Number=eventObj.stageX-this._mouseMotionInitX;
				var vDelta:Number=eventObj.stageY-this._mouseMotionInitY;
				if (Math.abs(vDelta)>Math.abs(hDelta)) {
					if (vDelta>0) {
						if (this.panelUp=="") {
							this._primaryMotionDirection="";
							return;
						}//if
						this._chainedPanel=References.panelManager.getPanelByID(this.panelUp) as Panel;
						if (this._chainedPanel!=null) {
							this._chainedPanel.show("fromtop", this.defaultPanelAnimationSpeed, -1, None.easeNone);	
						}//if
						this.hide("tobottom", this.defaultPanelAnimationSpeed, -1, None.easeNone);
						this._primaryMotionDirection="down";					
					} else {
						if (this.panelDown=="") {
							this._primaryMotionDirection="";
							return;
						}//if
						this._chainedPanel=References.panelManager.getPanelByID(this.panelDown) as Panel;
						if (this._chainedPanel!=null) {
							this._chainedPanel.show("frombottom", this.defaultPanelAnimationSpeed, -1, None.easeNone);	
						}//if
						this.hide("totop", this.defaultPanelAnimationSpeed, -1, None.easeNone);
						this._primaryMotionDirection="up";
					}//else
				} else {
					if (hDelta>0) {
						if (this.panelLeft=="") {
							this._primaryMotionDirection="";
							return;
						}//if
						this._chainedPanel=References.panelManager.getPanelByID(this.panelLeft) as Panel;
						if (this._chainedPanel!=null) {
							this._chainedPanel.show("fromleft", this.defaultPanelAnimationSpeed, -1, None.easeNone);	
						}//if
						this.hide("toright", this.defaultPanelAnimationSpeed, -1, None.easeNone);
						this._primaryMotionDirection="right";
					} else {
						if (this.panelRight=="") {
							this._primaryMotionDirection="";
							return;
						}//if
						this._chainedPanel=References.panelManager.getPanelByID(this.panelRight) as Panel;
						if (this._chainedPanel!=null) {
							this._chainedPanel.show("fromright", this.defaultPanelAnimationSpeed, -1, None.easeNone);	
						}//if
						this.hide("toleft", this.defaultPanelAnimationSpeed, -1, None.easeNone);
						this._primaryMotionDirection="left";
					}//else
				}//else
			} else {
				//Motion has been established. Move panel in that direction to match mouse position...
				switch (this._primaryMotionDirection) {
					case "right":						
						this._motionPercentCompleted=(eventObj.stageX-this._mouseMotionInitX)/(stage.stageWidth-this._mouseMotionInitX);
						if (this._motionPercentCompleted<=0) {							
							this.clearAllAnimations();
							if (this._chainedPanel!=null) {
								this._chainedPanel.clearAllAnimations();
								this._chainedPanel=null;
							}//if
							this._primaryMotionDirection="";
							return;
						}//if
						if (this._motionPercentCompleted>1) {
							this._motionPercentCompleted=1;							
						}//if						
						var time:Number=this.defaultPanelAnimationSpeed*this._motionPercentCompleted;
						time/=1.25;						
						this.updateHorizontalAnimation(time);
						if (this._chainedPanel!=null) {
							this._chainedPanel.updateHorizontalAnimation(time);
						}//if
						break;
					case "left":
						this._motionPercentCompleted=(this._mouseMotionInitX-eventObj.stageX)/this._mouseMotionInitX;
						if (this._motionPercentCompleted<=0) {
							this.clearAllAnimations();
							if (this._chainedPanel!=null) {
								this._chainedPanel.clearAllAnimations();
								this._chainedPanel=null;
							}//if
							this._primaryMotionDirection="";
							return;
						}//if
						if (this._motionPercentCompleted>1) {
							this._motionPercentCompleted=1;							
						}//if						
						time=Math.abs(this.defaultPanelAnimationSpeed*this._motionPercentCompleted);
						time/=1.25;						
						this.updateHorizontalAnimation(time);
						if (this._chainedPanel!=null) {
							this._chainedPanel.updateHorizontalAnimation(time);
						}//if
						break;
					case "up":						
						this._motionPercentCompleted=(stage.stageHeight-eventObj.stageY)/stage.stageHeight;
						if (this._motionPercentCompleted<=0) {							
							this.clearAllAnimations();
							if (this._chainedPanel!=null) {
								this._chainedPanel.clearAllAnimations();
								this._chainedPanel=null;
							}//if
							this._primaryMotionDirection="";
							return;
						}//if
						if (this._motionPercentCompleted>1) {
							this._motionPercentCompleted=1;							
						}//if						
						time=this.defaultPanelAnimationSpeed*this._motionPercentCompleted;
						time/=1.25;						
						this.updateVerticalAnimation(time);
						if (this._chainedPanel!=null) {							
							this._chainedPanel.updateVerticalAnimation(time);
						}//if
						break;						
					case "down":
						this._motionPercentCompleted=(eventObj.stageY-this._mouseMotionInitY)/(stage.stageHeight-this._mouseMotionInitY);
						if (this._motionPercentCompleted<=0) {							
							this.clearAllAnimations();
							if (this._chainedPanel!=null) {
								this._chainedPanel.clearAllAnimations();
								this._chainedPanel=null;
							}//if
							this._primaryMotionDirection="";
							return;
						}//if
						if (this._motionPercentCompleted>1) {
							this._motionPercentCompleted=1;							
						}//if						
						time=this.defaultPanelAnimationSpeed*this._motionPercentCompleted;
						time/=1.25;						
						this.updateVerticalAnimation(time);
						if (this._chainedPanel!=null) {							
							this._chainedPanel.updateVerticalAnimation(time);
						}//if					
						break;
					default:
						//This should never happen, but if it does then clean up the mostion and just reset everything.
						this._primaryMotionDirection="";
						this.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMotion);
						this.restoreToShow();
						break;
				}//switch
			}//else
		}//onMouseMotion
		
		public function completeHide(easingFunction:Function=null):void {			
			if (easingFunction==null) {
				easingFunction=Strong.easeInOut;
			}//if		
			if (this._horizontalTween!=null) {					
				this._horizontalTween.resume();
			}//if
			if (this._horizontalRotationTween!=null) {					
				this._horizontalRotationTween.resume();
			}//if							
			if (this._verticalTween!=null) {					
				this._verticalTween.resume();
			}//if
			if (this._verticalRotationTween!=null) {					
				this._verticalRotationTween.resume();
			}//if			
			if (this._alphaTween!=null) {				
				this._alphaTween.resume();
			}//if
		}//completeHide
		
		public function completeShow(easingFunction:Function=null):void {			
			//This is essentially the same functionality...just complete the action
			this.completeHide(easingFunction)
		}//completeShow
		
		private function removeAllTweenListeners():void {
			if (this._horizontalTween!=null) {
				this._horizontalTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
				this._horizontalTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
			}//if
			if (this._horizontalRotationTween!=null) {
				this._horizontalRotationTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
				this._horizontalRotationTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
			}//if
			if (this._verticalTween!=null) {				
				this._verticalTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
				this._verticalTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
			}//if
			if (this._verticalRotationTween!=null) {
				this._verticalRotationTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
				this._verticalRotationTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
			}//if
			if (this._alphaTween!=null) {
				this._alphaTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);			
				this._alphaTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
			}//if
		}//removeAllTweenListeners
		
		public function restoreToShow(easingFunction:Function=null):void {			
			this.removeAllTweenListeners();
			if (easingFunction==null) {
				easingFunction=Strong.easeInOut;
			}//if					
			if (this._horizontalTween!=null) {
				this._horizontalTween.stop();				
				this._horizontalTween.continueTo(0, (this._horizontalTween.duration-this._horizontalTween.time));
			}//if
			if (this._horizontalRotationTween!=null) {	
				this._horizontalRotationTween.stop();
				this._horizontalRotationTween.continueTo(0, (this._horizontalRotationTween.duration-this._horizontalRotationTween.time));
			}//if							
			if (this._verticalTween!=null) {					
				this._verticalTween.stop();
				this._verticalTween.continueTo(0, (this._verticalTween.duration-this._verticalTween.time));
			}//if
			if (this._verticalRotationTween!=null) {
				this._verticalRotationTween.stop();
				this._verticalRotationTween.continueTo(0, (this._verticalRotationTween.duration-this._verticalRotationTween.time));
			}//if			
			if (this._alphaTween!=null) {	
				this._alphaTween.stop();
				this._alphaTween.continueTo(1, (this._alphaTween.duration-this._alphaTween.time));
			}//if
		}//restoreToShow
		
		public function restoreToHide(easingFunction:Function=null):void {			
			this.removeAllTweenListeners();
			if (easingFunction==null) {
				easingFunction=Strong.easeInOut;
			}//if			
			if (this._horizontalTween!=null) {
				this._horizontalTween.stop();
				this._horizontalTween.continueTo(this._restoreXPosition, (this._horizontalTween.duration-this._horizontalTween.time));			
			}//if
			if (this._horizontalRotationTween!=null) {	
				this._horizontalRotationTween.stop();
				this._horizontalRotationTween.continueTo(this._restoreXRotation, (this._horizontalRotationTween.duration-this._horizontalRotationTween.time));				
			}//if							
			if (this._verticalTween!=null) {					
				this._verticalTween.stop();
				this._verticalTween.continueTo(this._restoreYPosition, (this._verticalTween.duration-this._verticalTween.time));								
			}//if
			if (this._verticalRotationTween!=null) {
				this._verticalRotationTween.stop();
				this._verticalRotationTween.continueTo(this._restoreYRotation, (this._verticalRotationTween.duration-this._verticalRotationTween.time));				
			}//if			
			if (this._alphaTween!=null) {	
				this._alphaTween.stop();
				this._alphaTween.continueTo(0, (this._alphaTween.duration-this._alphaTween.time));
			}//if			
		}//restoreToHide
		
		public function get panelRight():String {
			var returnPanelID:String=new String("");
			if (this.content==null) {
				return (returnPanelID);
			}//if
			if (this.content.panelData==null) {
				return (returnPanelID);
			}//if
			var panelData:XML=this.content.panelData;
			if (SwagDataTools.isXML(panelData.@panelright)) {
				returnPanelID=String(panelData.@panelright);
				returnPanelID=SwagDataTools.stripOutsideChars(returnPanelID, " ");
				returnPanelID=this.getMetaPanelID(returnPanelID);
			}//if
			return (returnPanelID);
		}//get panelRight
		
		public function get panelLeft():String {
			var returnPanelID:String=new String("");
			if (this.content==null) {
				return (returnPanelID);
			}//if
			if (this.content.panelData==null) {
				return (returnPanelID);
			}//if
			var panelData:XML=this.content.panelData;
			if (SwagDataTools.isXML(panelData.@panelleft)) {
				returnPanelID=String(panelData.@panelleft);
				returnPanelID=SwagDataTools.stripOutsideChars(returnPanelID, " ");
				returnPanelID=this.getMetaPanelID(returnPanelID);
			}//if
			return (returnPanelID);
		}//get panelLeft
		
		public function get panelUp():String {
			var returnPanelID:String=new String("");
			if (this.content==null) {
				return (returnPanelID);
			}//if
			if (this.content.panelData==null) {
				return (returnPanelID);
			}//if
			var panelData:XML=this.content.panelData;
			if (SwagDataTools.isXML(panelData.@panelup)) {
				returnPanelID=String(panelData.@panelup);
				returnPanelID=SwagDataTools.stripOutsideChars(returnPanelID, " ");
				returnPanelID=this.getMetaPanelID(returnPanelID);				
			}//if
			return (returnPanelID);
		}//get panelUp
		
		public function get panelDown():String {
			var returnPanelID:String=new String("");
			if (this.content==null) {
				return (returnPanelID);
			}//if
			if (this.content.panelData==null) {
				return (returnPanelID);
			}//if
			var panelData:XML=this.content.panelData;
			if (SwagDataTools.isXML(panelData.@paneldown)) {
				returnPanelID=String(panelData.@paneldown);
				returnPanelID=SwagDataTools.stripOutsideChars(returnPanelID, " ");
				returnPanelID=this.getMetaPanelID(returnPanelID);
			}//if
			return (returnPanelID);
		}//get panelDown
		
		private function getMetaPanelID(panelID:String):String {
			var metaID:String=new String();
			metaID=panelID;
			metaID=metaID.toLowerCase();
			switch (metaID) {
				case "%previous%" :
					return (_restorePanel);
					break;
				case "%start%":
					return (Settings.startupPanelID);
					break;
				default: 
					return (panelID);
					break;
			}//switch
			return (panelID);
		}//getMetaPanelID
		
		public static function get modalPanelActive():Boolean {
			return (_modalPanelActive);			
		}//get modalPanelActive
		
		public function setModalMode(mode:Boolean):void {
			_modalPanelActive=mode;
		}//setModalMode
		
		public function destroy():void {
			this.content.destroy();
			this.removePanelFromList();
			this.removeListeners();
			this._playback.target=null;
			this._playback=null;
			if (this.parent.contains(this)) {
				this.parent.removeChild(this);
			}//if
		}//destroy
		
		public function initialize():void {
			if (this.content!=null) {
				this.addChild(this.content as DisplayObject);
				this.parsePositionData();
				this.content.initialize();				
			} else {
				//broadcast error
			}//else			
			this.x=this._originalXPosition;
			this.y=this._originalYPosition;			
			this.visible=false;
			this.alpha=0;
		}//initialize
		
		public function set content(contentSet:IPanelContent):void {
			this._content=contentSet;
		}//set content
		
		public function get content():IPanelContent {
			return (this._content);
		}//get content
		
		public function get contentDisplayObject():DisplayObjectContainer {
			return (this._content as DisplayObjectContainer);
		}//get contentDisplayObject
		
		public function get isSilent():Boolean {
			return (this._panelIsSilent);
		}//get isSilent
		
		public function set isSilent(silentSet:Boolean):void {
			this._panelIsSilent=silentSet;
		}//set isSilent
		
		public static function get panels():Vector.<Panel> {
			if (_panels==null) {
				_panels=new Vector.<Panel>();
			}//if
			return (_panels);
		}//get panels
		
		public static function get activePanels():Array {
			var activePanelList:Array=new Array();
			for (var count:uint=0; count<_panels.length; count++) {
				var currentPanel:Panel=_panels[count] as Panel;
				if (currentPanel.active) {
					activePanelList.push(currentPanel);
				}//if
			}//for
			return (activePanelList);
		}//get activePanels
		
		public function get isModal():Boolean {
			if (this.content.panelData!=null) {
				var panelData:XML=this.content.panelData;
				if (SwagDataTools.isXML(panelData.@modal)) {
					var modalString:String=new String(panelData.@modal);
					modalString=SwagDataTools.stripChars(modalString, SwagDataTools.SEPARATOR_RANGE);
					modalString=modalString.toLowerCase();
					switch (modalString) {
						case "true" :
							return (true);
							break;
						case "false" :
							return (false);
							break;
						case "t" :
							return (true);
							break;
						case "f" :
							return (false);
							break;
						case "1" :
							return (true);
							break;
						case "0" :
							return (false);
							break;
						case "yes" :
							return (true);
							break;
						case "no" :
							return (false);
							break;
						case "y" :
							return (true);
							break;
						case "n" :
							return (false);
							break;
						case "on" :
							return (true);
							break;
						case "off" :
							return (false);
							break;
						default:
							return (false);
							break;
					}//switch					
				}//if
			}//if
			return (false);
		}//get isModal
		
		public static function isPanelActive(id:String):Boolean {
			if ((id=="") || (id==null)) {
				return (false);
			}//if
			for (var count:uint=0; count<_panels.length; count++) {
				var currentPanel:Panel=_panels[count] as Panel;
				if (id==currentPanel.panelID) {
					if (currentPanel.active) {
						return (true);
					}//if
				}//if
			}//for
			return (false);
		}//isPanelActive
		
		public static function panelExists(id:String):Boolean {			
			if ((id=="") || (id==null)) {
				return (false);
			}//if			
			for (var count:uint=0; count<_panels.length; count++) {
				var currentPanel:Panel=_panels[count] as Panel;				
				if (id==currentPanel.panelID) {					
					return (true);					
				}//if
			}//for			
			return (false);
		}//panelExists
		
		public function get active():Boolean {
			return (this._panelActive);
		}//active
		
		public function get suspended():Boolean {
			return (this._panelSuspended);
		}//suspended
		
		private function addPanelToList(... args):void {
			_panels.push(this);		
		}//addPanelToList
		
		private function removePanelFromList(... args):void {
			for (var count:uint=0; count<_panels.length; count++) {
				var currentPanel:Panel=_panels[count] as Panel;
				if (currentPanel!=null) {
					if (currentPanel==this) {
						_panels.splice(count, 1);
					}//if
				}//if
			}//for
		}//removePanelFromoActiveList
		
		private function addSwipeHandlers():void {
			this.stage.addEventListener(MouseEvent.MOUSE_DOWN, this.onMousePress);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, this.onMouseRelease);
		}//addSwipeHandlers
		
		private function removeSwipeHandlers():void {
			this.stage.removeEventListener(MouseEvent.MOUSE_DOWN, this.onMousePress);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, this.onMouseRelease);
		}//removeSwipeHandlers
		
		private function addListeners():void {
			this.addEventListener(Event.ADDED_TO_STAGE, this.addPanelToList);
			this.addEventListener(Event.REMOVED_FROM_STAGE, this.removePanelFromList);				
			this.mouseChildren=true;
			this.useHandCursor=false;
		}//addListeners
		
		private function removeListeners():void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.addPanelToList);
			this.removeEventListener(Event.REMOVED_FROM_STAGE, this.removePanelFromList);
		}//removeListeners
		
		private function setDefaults():void {	
			this._playback=new SwagMovieClip(this);
		}//setDefaults
		
	}//Panel class
	
}//package