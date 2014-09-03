package socialcastr.ui.input {
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.None;
	
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import socialcastr.events.MovieClipButtonEvent;
	import socialcastr.interfaces.ui.input.IMovieClipButton;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.instances.SwagMovieClip;
	import swag.events.SwagMovieClipEvent;
	
	/**
	 * May be associated with any movie clip to be used as a button. Simply label frame "up", "down", and "over",
	 * and any animations starting with that frame label will play through to the next frame label (i.e. the
	 * next frame label acts as a stop() action.  
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
	public class MovieClipButton extends MovieClip implements IMovieClipButton {
		
		/**
		 * Function invoked on specific actions. These can be used instead of creating event listeners, if desired. 
		 */
		public var onButtonDown:Function=null;
		public var onButtonUp:Function=null;
		public var onButtonClick:Function=null;
		public var onButtonOver:Function=null;
		public var onButtonOut:Function=null;
		
		private var _playbackControl:SwagMovieClip;
		private var _stateLocked:Boolean=false;
		private var _stateRestoreAction:String=new String();
		private var _stateRestoreFrame:String=new String();
		private var _mouseOver:Boolean=false;
		
		private var _fadeTween:Tween;
		
		public function MovieClipButton() {
			this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			this.addEventListener(Event.REMOVED_FROM_STAGE, this.destroy);
			super();
		}//constructor
		
		private function onOver(eventObj:MouseEvent):void {
			this._mouseOver=true;
			this.invokeMouseCallback(this.onButtonOver,eventObj);
			if (this._stateLocked) {
				if (this._stateRestoreAction==MovieClipButtonEvent.ONOVER) {
					this.unlockState(this._stateRestoreFrame);
				}//if
				return;
			}//if
			var label:String=this.findFrameLabel("over");
			if (label==null) {
				return;
			}//if
			this._playbackControl.playToNextLabel(label, false);
			var event:MovieClipButtonEvent=new MovieClipButtonEvent(MovieClipButtonEvent.ONOVER);
			SwagDispatcher.dispatchEvent(event, this);
		}//onOver
		
		private function onOut(eventObj:MouseEvent):void {
			this._mouseOver=false;	
			this.invokeMouseCallback(this.onButtonOut,eventObj);
			if (this._stateLocked) {
				if (this._stateRestoreAction==MovieClipButtonEvent.ONOUT) {
					this.unlockState(this._stateRestoreFrame);
				}//if
				return;
			}//if
			var label:String=this.findFrameLabel("up");
			if (label==null) {
				return;
			}//if
			this._playbackControl.gotoAndStop(label);
			this._playbackControl.playToNextLabel(label, false);
			var event:MovieClipButtonEvent=new MovieClipButtonEvent(MovieClipButtonEvent.ONOUT);
			SwagDispatcher.dispatchEvent(event, this);
		}//onOut
		
		private function onDown (eventObj:MouseEvent):void {
			this.invokeMouseCallback(this.onButtonDown,eventObj);
			if (this._stateLocked) {
				if (this._stateRestoreAction==MovieClipButtonEvent.ONDOWN) {
					this.unlockState(this._stateRestoreFrame);
				}//if
				return;
			}//if
			var label:String=this.findFrameLabel("down");	
			if (label==null) {
				return;
			}//if
			this._playbackControl.playToNextLabel(label, false);
			var event:MovieClipButtonEvent=new MovieClipButtonEvent(MovieClipButtonEvent.ONDOWN);
			SwagDispatcher.dispatchEvent(event, this);
		}//onDown
		
		private function onUp(eventObj:MouseEvent):void {
			this.invokeMouseCallback(this.onButtonUp,eventObj);
			if (this._stateLocked) {				
				if ((this._stateRestoreAction==MovieClipButtonEvent.ONRELEASE) || (this._stateRestoreAction==MovieClipButtonEvent.ONCLICK)) {
					this.unlockState(this._stateRestoreFrame);
				}//if
				return;
			}//if
			var label:String=this.findFrameLabel("over");	
			if (label==null) {				
				return;
			}//if	
			this.invokeMouseCallback(this.onButtonClick,eventObj);
			this._playbackControl.playToNextLabel(label, false);
			var event:MovieClipButtonEvent=new MovieClipButtonEvent(MovieClipButtonEvent.ONRELEASE);
			SwagDispatcher.dispatchEvent(event, this);
			event=new MovieClipButtonEvent(MovieClipButtonEvent.ONCLICK);
			SwagDispatcher.dispatchEvent(event, this);
		}//onUp
		
		private function invokeMouseCallback(methodRef:Function,eventObj:MouseEvent):void {
			if (methodRef==null) {
				return;
			}//if
			//Try with parameter, then without.
			try {
				methodRef(eventObj);
			} catch (e:*) {
				try {
					methodRef();
				} catch (e2:*) {					
				}//catch
			}//catch
		}//invokeMouseCallback
		
		/**
		 * Locks the button to a specified state with an option to automatically unlock the button on a specified mouse motion.
		 * <p>If no restore options are provided, the button will remain locked in its state until a call to <code>unlockState</code>
		 * is made.</p>
		 *  
		 * @param state The state to lock the button to. This must correspond with an associated label on the <code>MovieClipButton</code>
		 * instance.
		 * @param restoreOnEvent An optional state, matching one of the <code>MovieClipButtonEvent</code> constants, that will automatically unlock the
		 * button.
		 * @param restoreToState If the <code>restoreOn</code> parameter is specified, this is the frame that the button will be restored to. 
		 * Once restored, standard button behaviour will resume. 
		 * 
		 */
		public function lockState(state:String, restoreOnEvent:String="", restoreToState:String=""):void {
			if (restoreOnEvent=="") {
				this.clearButtonMode();
			}//if			
			this._stateRestoreAction=restoreOnEvent;
			this._stateRestoreFrame=restoreToState;
			var stateLabel:String=this.findFrameLabel(state);			
			if (stateLabel==null) {
				return;
			}//if				
			this._stateLocked=true;	
			this._playbackControl.playToNextLabel(stateLabel, false);	
			var event:MovieClipButtonEvent=new MovieClipButtonEvent(MovieClipButtonEvent.ONLOCKSTATE);
			event.state=stateLabel;
			SwagDispatcher.dispatchEvent(event, this);
		}//lockState
		
		/**
		 * Releases a locked state using any default presets that may have been established during the locking operation. 
		 * 
		 */
		public function releaseState():void {
			if (this._stateLocked) {			
				this.unlockState(this._stateRestoreFrame);				
			}//if
		}//releaseState
		
		private function unlockState(restoreToState:String=""):void {
			this.setButtonMode();			
			SwagDispatcher.removeEventListener(SwagMovieClipEvent.END, this.onUnlockState, this._playbackControl);
			if (restoreToState=="") {
				if (this._mouseOver) {
					var label:String=this.findFrameLabel("over");
					if (label!=null) {
						this._playbackControl.playToNextLabel(label, false);
					}//if										
				} else {
					label=this.findFrameLabel("up");
					if (label!=null) {
						this._playbackControl.playToNextLabel(label, false);							
					}//if											
				}//else
				this.onUnlockState();
			} else {
				label=this.findFrameLabel(restoreToState);
				if (label!=null) {
					SwagDispatcher.addEventListener(SwagMovieClipEvent.END, this.onUnlockState, this, this._playbackControl);
					this._playbackControl.playToNextLabel(label, false);										
				} else {
					this.onUnlockState();
				}//else				
			}//else
			var event:MovieClipButtonEvent=new MovieClipButtonEvent(MovieClipButtonEvent.ONUNLOCKSTATE);			
			SwagDispatcher.dispatchEvent(event, this);
		}//unlockState
		
		public function onUnlockState(... args):void {				
			SwagDispatcher.removeEventListener(SwagMovieClipEvent.END, this.onUnlockState, this._playbackControl);
			this._stateLocked=false;
			this._stateRestoreAction="";
			this._stateRestoreFrame="";
		}//onUnlockState
		
		public function swapWithTop():Function {
			return (this._playbackControl.swapWithTop);
		}//swapWithTop
		
		private function setButtonMode():void {
			this.mouseChildren=false;
			this.mouseEnabled=true;
			this.buttonMode=true;
			this.useHandCursor=true;
		}//setButtonMode
		
		private function clearButtonMode():void {
			this.mouseEnabled=false;
			this.buttonMode=false;
			this.useHandCursor=false;
		}//clearButtonMode
		
		public function show():void {
			this.visible=true;
			this.removeListeners();
			this.addListeners();
			if (this._fadeTween!=null) {
				this._fadeTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
				this._fadeTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
				this._fadeTween.stop();
				this._fadeTween=null;
			}//if
			this._fadeTween=new Tween(this, "alpha", None.easeNone, this.alpha, 1, 0.5, true);
			this._fadeTween.addEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
		}//show
		
		public function hide():void {
			this.removeListeners();
			if (this._fadeTween!=null) {
				this._fadeTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
				this._fadeTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
				this._fadeTween.stop();
				this._fadeTween=null;
			}//if
			this._fadeTween=new Tween(this, "alpha", None.easeNone, this.alpha, 0, 0.5, true);
			this._fadeTween.addEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
		}//hide
		
		private function onShowDone(eventObj:TweenEvent):void {
			this._fadeTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onShowDone);
			this.visible=true;
			var event:MovieClipButtonEvent=new MovieClipButtonEvent(MovieClipButtonEvent.ONSHOW);			
			SwagDispatcher.dispatchEvent(event, this);
		}//onShowDone
		
		private function onHideDone(eventObj:TweenEvent):void {
			this._fadeTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onHideDone);
			var event:MovieClipButtonEvent=new MovieClipButtonEvent(MovieClipButtonEvent.ONHIDE);			
			SwagDispatcher.dispatchEvent(event, this);
			this.visible=false;
		}//onHideDone
		
		public function addListeners():void {
			this.addEventListener(MouseEvent.MOUSE_OVER, this.onOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, this.onOut);
			this.addEventListener(MouseEvent.MOUSE_DOWN, this.onDown);
			this.addEventListener(MouseEvent.MOUSE_UP, this.onUp);
			this.setButtonMode();
		}//addListeners
		
		public function removeListeners():void {
			this.removeEventListener(MouseEvent.MOUSE_OVER, this.onOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT, this.onOut);
			this.removeEventListener(MouseEvent.MOUSE_DOWN, this.onDown);
			this.removeEventListener(MouseEvent.MOUSE_UP, this.onUp);			
			this.clearButtonMode();
		}//removeListeners
		
		private function findFrameLabel(frameLabel:String, useDefault:Boolean=true):String {
			if ((frameLabel==null) || (frameLabel=="")) {
				if (useDefault) {
					return (this.currentFrameLabel);
				} else {
					return (null);
				}//else
			}//if
			var labelString:String=new String();
			labelString=frameLabel;			
			labelString=labelString.toLowerCase();			
			for (var count:uint=0; count<this.currentLabels.length; count++) {
				var labelObj:FrameLabel=this.currentLabels[count] as FrameLabel;
				var currentLabelString:String=new String();			
				currentLabelString=labelObj.name;
				currentLabelString=currentLabelString.toLowerCase();
				if (labelString==currentLabelString) {
					return (labelObj.name);
				}//if
			}//for
			if (useDefault) {
				return (this.currentFrameLabel);
			} else {
				return (null);
			}//else
		}//findFrameLabel
		
		public function setDefaults(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			this._playbackControl=new SwagMovieClip(this);
			this.addListeners();
			var label:String=this.findFrameLabel("init");
			if (label==null) {
				label=this.findFrameLabel("up");		
			}//if
			if (label!=null) {
				this.gotoAndStop(label);
			} else {
				this.stop();
			}//else
		}//setDefaults
		
		public function destroy(... args):void {
			this.removeEventListener(Event.REMOVED_FROM_STAGE, this.destroy);
			this.removeListeners();
		}//destroy
		
	}//MovieClipButton class
	
}//package