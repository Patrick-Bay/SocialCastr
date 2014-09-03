package socialcastr.ui.components {
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.None;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import socialcastr.Settings;
	
	import swag.core.SwagSystem;
	
	/**
	 * A simple, self-adjusting tooltip class to be associated with a <code>MovieClip</code> instance.
	 * The movie clip must contain a dynamic text field with the instance name "tipText", to act as the text for the tool tip, 
	 * and a <code>MovieClip</code> instance named "tipFace" which acts as the background, or face, for the tooltip. Both are
	 * adjusted together and should be sized as thinly (smallest width), as possible for proper handling.</p>	 
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
	public class Tooltip extends MovieClip {
		
		private static var _tooltips:Vector.<Tooltip>=new Vector.<Tooltip>();
		
		private var _tipText:String;
		private var _associatedDisplayObj:DisplayObject;
		private var _fadeTween:Tween;
		
		public var tipText:TextField;
		public var tipFace:MovieClip;
		
		/**
		 * Constructor method for the Tooltip object.
		 *  
		 * @param associatedDisplayObject The active display object with which to associate the tooltip. This
		 * object will be continuously scanned until it is attached to the stage. At that point, the tooltip instance
		 * will automatically attach itself above it.
		 * @param tipText The initial text to assign to the tooltip. Alternately, this can be done by updating the 
		 * <code>text</code> property.
		 * @param overrideSettings If <em>true</em>, the tooltip will be attached and displayed along with its associated
		 * display object regardless of what the current tooltip settings are in the application.
		 * 
		 */
		public function Tooltip(associatedDisplayObject:DisplayObject, tipText:String, overrideSettings:Boolean=false) {			
			var useTooltip:Boolean=true;			
			if (SwagSystem.isMobile) {
				if (!Settings.useTooltipsOnMobile) {
					//Disable tooltips if runtime is mobile and Settings.useTooltipsOnMobile is false.
					useTooltip=false;
				}//if
			}//if
			if (!Settings.tooltipEnabled) {
				//Allow override throgh XML setting. The application XML can contain either a <tip>on</tip> or 
				//<tooltip>off</tooltip> node (the contents may be varied as Settings.tooltipEnabled also resolves 
				//node attribute values of "enabled", "disabled", "1", "0", "yes", and "no" as Boolean true or false).
				//
				useTooltip=false;
			}//if
			if (overrideSettings) {
				useTooltip=true;
			}//if
			if (useTooltip) {
				_tooltips.push(this);
				this._associatedDisplayObj=associatedDisplayObject;
				this._tipText=tipText;
				SwagSystem.onExists("stage", this._associatedDisplayObj, this.addToStage, false);
				super();
			}//if
		}//constructor
		
		/**
		 * @param textSet The text displayed in the tooltip. The tooltip automatically re-sizes itself whenever new text is
		 * assigned, but hint text should be limited since multiline isn't supported (and it's supposed to be a "tip"!).		 
		 */
		public function set text(textSet:String):void {
			this._tipText=textSet;
			this.tipText.autoSize=TextFieldAutoSize.LEFT;
			this.tipText.text=this._tipText;
			this.tipText.x=2;
			this.tipFace.width=this.tipText.width+5;
		}//set text
		
		public function get text():String {
			return (this._tipText);
		}//get text
		
		/**
		 * @return The display object associated with this tooltip instance (may be <em>null</em>).		 
		 */
		public function get associatedDisplayObj():DisplayObject {
			return (this._associatedDisplayObj);
		}//_associatedDisplayObj
		
		/**
		 * Returns a reference to the <code>Tooltip</code> instance associated with a particular display object,
		 * or <em>null</em> if none exists.
		 *  
		 * @param targetDisplayObject The display object with which the tooltip is associated.
		 * 
		 * @return The <code>Tooltip</code> instance associated with the display object, or <em>null</em> if none exists. 
		 * 
		 */
		public static function getTipFor(targetDisplayObject:DisplayObject):Tooltip {
			if (targetDisplayObject==null) {
				return (null);
			}//if
			for (var count:uint=0; count<_tooltips.length; count++) {
				var currentTip:Tooltip=_tooltips[count] as Tooltip;
				if (currentTip.associatedDisplayObj==targetDisplayObject) {
					return (currentTip);
				}//if
			}//for
			return (null);
		}//getForDisplayObject
		
		/**
		 * @private 
		 */
		private function alignTo(xPos:Number, yPos:Number):void {
			this.x=xPos-(this.width/2);
			if (this.x<0) {
				this.x=0;
			}//if
			if ((this.x+this.width)>this.stage.stageWidth) {
				this.x=this.stage.stageWidth-this.width;
			}//if
			this.y=yPos-this.height-5;
			if (this.y<0) {
				this.y=yPos+this.height;
			}//if
		}//alignTo
		
		/**
		 * @private 
		 */
		private function onMove(eventObj:MouseEvent):void {
			if (this._associatedDisplayObj.visible==false) {
				this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMove);
				this.alpha=0;
				this.visible=false;
				return;
			}//if
			this.alignTo(eventObj.stageX, eventObj.stageY);
		}//onMove
		
		/**
		 * @private 
		 */
		private function onTargetRollOver(eventObj:MouseEvent):void {
			this.visible=true;
			if (this._fadeTween!=null) {
				this._fadeTween.stop();
				this._fadeTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onFadeOut);
				this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMove);
				this._fadeTween=null;
			}//if
			if (this._associatedDisplayObj.visible==false) {
				return;
			}//if
			this.alignTo(eventObj.stageX, eventObj.stageY);
			this.swapWithTop();
			this._fadeTween=new Tween(this, "alpha", None.easeNone, this.alpha, 1, 0.3, true);
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onMove);
		}//onTargetRollOver
		
		/**
		 * @private 
		 */
		private function onTargetRollOut(eventObj:MouseEvent):void {
			if (this._fadeTween!=null) {
				this._fadeTween.stop();
				this._fadeTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onFadeOut);
				this._fadeTween=null;
			}//if
			if (this._associatedDisplayObj.visible==false) {
				return;
			}//if
			this._fadeTween=new Tween(this, "alpha", None.easeNone, this.alpha, 0, 0.3, true);
			this._fadeTween.addEventListener(TweenEvent.MOTION_FINISH, this.onFadeOut);
		}//onTargetRollOut
		
		/**
		 * @private 
		 */
		private function onFadeOut(eventObj:TweenEvent):void {
			this.visible=false;
			this._fadeTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onFadeOut);
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMove);
		}//onFadeOut
		
		/**
		 * @private 
		 */
		private function addListeners():void {
			this._associatedDisplayObj.addEventListener(Event.REMOVED_FROM_STAGE, this.removefromStage);
			this._associatedDisplayObj.addEventListener(MouseEvent.MOUSE_OVER, this.onTargetRollOver);
			this._associatedDisplayObj.addEventListener(MouseEvent.MOUSE_OUT, this.onTargetRollOut);
		}//addListeners
		
		/**
		 * @private 
		 */
		private function removeListeners():void {
			this._associatedDisplayObj.removeEventListener(Event.REMOVED_FROM_STAGE, this.removefromStage);
			this._associatedDisplayObj.removeEventListener(MouseEvent.MOUSE_OVER, this.onTargetRollOver);
			this._associatedDisplayObj.removeEventListener(MouseEvent.MOUSE_OUT, this.onTargetRollOut);
		}//removeListeners
		
		/**
		 * @private 
		 */
		private function addToStage():void {
			this._associatedDisplayObj.stage.addChild(this);
			this.text=this._tipText;
			this.alpha=0;
			this.addListeners();
		}//addToStage
		
		/**
		 * @private 
		 */
		private function swapWithTop():void {
			if (this.stage==null) {
				return;
			}//if			
			var swapIndex:int=this.stage.numChildren-1;
			try {
				this.stage.setChildIndex(this, swapIndex);
			} catch (error:*) {
				if (error is RangeError) {
					//Index isn't correct
				} else if (error is ArgumentError) {
					//Target isn't a child of the container
				} else {
					//Unknown
				}//else
			}//catch
		}//swapWithTop
		
		/**
		 * @private 
		 */
		private function removefromStage(... args):void {
			this.removeListeners();
			this.stage.removeChild(this);
		}//removeFromStage
		
		/**
		 * Destroys the instance and removes it from the stage's display list.		 
		 */		
		public function destroy():void {
			var compactTips:Vector.<Tooltip>=new Vector.<Tooltip>();
			for (var count:uint=0; count<_tooltips.length; count++) {
				var currentTip:Tooltip=_tooltips[count] as Tooltip;
				if (currentTip!=this) {
					compactTips.push(currentTip);
				}//if
			}//for
			_tooltips=compactTips;
			this.removefromStage();
		}//destroy
		
	}//Tooltip class
	
}//package