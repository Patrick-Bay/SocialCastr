package socialcastr.ui.components {
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.Strong;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextField;
	
	import fl.transitions.easing.Strong;
	
	import socialcastr.events.AccordionMenuButtonEvent;
	import socialcastr.events.MovieClipButtonEvent;
	import socialcastr.interfaces.ui.input.IMovieClipButton;
	import socialcastr.ui.components.Tooltip;
	import socialcastr.ui.input.MovieClipButton;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.instances.SwagSequence;
	
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
	public class AccordionMenuButton extends MovieClipButton implements IMovieClipButton {
		
		private static var _buttonGroups:Array=new Array();
		
		private var _buttonXMLData:XML=null;
		private var _buttonIndex:uint;
		
		private var _slideXTween:Tween=null;
		private var _slideYTween:Tween=null;
		private var _group:String=new String();
		
		private var _targetState:String=new String();		
		
		public var faceText:TextField;
		private var _buttonText:String=new String();
		private var _hintText:String=new String();
		private var _buttonData:*=null;	
		private var _tooltip:Tooltip=null;			
		private var _static:Boolean=false; //Does button stay on screen / Is it excluded from motion, hiding, showing, etc.?
		
		private var _delay:SwagSequence;
		
		public function AccordionMenuButton(group:String, buttonXMLData:XML=null)	{			
			this._group=group;
			this.addButtonToGroup(this._group);
			this._buttonXMLData=buttonXMLData;			
			super();
		}//constructor
		
		public function showTo(xPosition:Number, yPosition:Number, easingFunction:Function=null):void {			
			if (this._slideXTween!=null) {
				this._slideXTween.stop();
				this._slideXTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onSlideDone);
				this._slideXTween=null;
			}//if
			if (this._slideYTween!=null) {
				this._slideYTween.stop();
				this._slideYTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onSlideDone);
				this._slideYTween=null;
			}//if
			if (easingFunction==null) {
				easingFunction=Strong.easeOut;
			}//if				
			super.show();
			this._targetState="show";
			if ((xPosition==this.x) && (yPosition==this.y)) {
				this.onSlideDone();
				return;
			}//if
			if (xPosition!=this.x) {
				this._slideXTween=new Tween(this, "x", easingFunction, this.x, xPosition, 0.3, true);
				this._slideXTween.addEventListener(TweenEvent.MOTION_FINISH, this.onSlideDone);
			}//if
			if (yPosition!=this.y) {
				this._slideYTween=new Tween(this, "y", easingFunction, this.y, yPosition, 0.3, true);
				this._slideYTween.addEventListener(TweenEvent.MOTION_FINISH, this.onSlideDone);
			}//if
		}//showTo
				
		public function hideTo(xPosition:Number, yPosition:Number, easingFunction:Function=null):void {			
			if (this._slideXTween!=null) {
				this._slideXTween.stop();
				this._slideXTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onSlideDone);
				this._slideXTween=null;
			}//if
			if (this._slideYTween!=null) {
				this._slideYTween.stop();
				this._slideYTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onSlideDone);
				this._slideYTween=null;
			}//if
			if (easingFunction==null) {
				easingFunction=Strong.easeIn;
			}//if			
			super.hide();
			this._targetState="hide";
			if ((xPosition==this.x) && (yPosition==this.y)) {
				this.onSlideDone();
				return;
			}//if
			if (xPosition!=this.x) {
				this._slideXTween=new Tween(this, "x", easingFunction, this.x, xPosition, 0.3, true);
				this._slideXTween.addEventListener(TweenEvent.MOTION_FINISH, this.onSlideDone);
			}//if
			if (yPosition!=this.y) {
				this._slideYTween=new Tween(this, "y", easingFunction, this.y, yPosition, 0.3, true);
				this._slideYTween.addEventListener(TweenEvent.MOTION_FINISH, this.onSlideDone);
			}//if
		}//hideTo		
		
		public function onMenuButtonClick(eventObj:MovieClipButtonEvent):void {
			var event:AccordionMenuButtonEvent=new AccordionMenuButtonEvent(AccordionMenuButtonEvent.CLICK);
			SwagDispatcher.dispatchEvent(event, this);
			this.focusRect=false;
			this.stage.focus=this;
		}//onMenuButtonClick
		
		public function set text(textSet:String):void {			
			this._buttonText=textSet;
			if (this.faceText!=null) {
				this.faceText.text=this._buttonText;
			}//if
		}//set text
		
		public function get text():String {
			return (this._buttonText);
		}//get text
		
		public function set hint(hintSet:String):void {			
			if (this._tooltip!=null) {
				this._tooltip.destroy();
				this._tooltip=null;
			}//if		
			this._hintText=hintSet;
			if ((this._hintText!=null) && (this._hintText!="")) {
				this._tooltip=new Tooltip(this, this._hintText);
			}//if
		}//set hint
		
		public function get hint():String {
			return (this._hintText);
		}//get hint
		
		public function get panel():String {
			if (this._buttonXMLData==null) {
				return (null);
			}//if
			if (SwagDataTools.isXML(this._buttonXMLData.@panel)) {
				var panelString:String=new String(this._buttonXMLData.@panel);
			}//if
			return (panelString);
		}//get panel	
		
		public function get group():String {
			return (this._group);
		}//get group
		
		public function set data(dataSet:*):void {
			this._buttonData=dataSet;			
		}//set data
		
		public function get data():* {
			return (this._buttonData);
		}//get data
		
		public function set isStatic (staticSet:Boolean):void {
			this._static=staticSet;
		}//set isStatic
		
		public function get isStatic ():Boolean {
			return (this._static);
		}//get isStatic
		
		public static function get groups():Array {
			return (_buttonGroups);
		}//get groups
		
		public static function get buttons():Array {
			var buttonArray:Array=new Array();
			for (var item in _buttonGroups) {
				var currentGroup:Array=_buttonGroups[item] as Array;
				if (currentGroup!=null) {
					for (var count:uint=0; count<currentGroup.length; count++) {
						var currentButton:AccordionMenuButton=currentGroup[count] as AccordionMenuButton;
						if (currentButton!=null) {
							buttonArray.push(currentButton);
						}//if
					}//for
				}//if
			}//for
			return (buttonArray);
		}//get groups
		
		public static function getButtonGroup(group:String):Array {
			if (_buttonGroups[group]==undefined) {
				return (null);
			}//if
			return (_buttonGroups[group] as Array);
		}//getButtonGroup
		
		private function onSlideDone(... args):void {
			if (this._slideXTween!=null) {
				this._slideXTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onSlideDone);
				this._slideXTween=null;
			}//if
			if (this._slideYTween!=null) {
				this._slideYTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onSlideDone);
				this._slideYTween=null;
			}//if
			if (this._targetState=="show") {
				var event:AccordionMenuButtonEvent=new AccordionMenuButtonEvent(AccordionMenuButtonEvent.SHOW);
				SwagDispatcher.dispatchEvent(event, this);
			} else if (this._targetState=="hide") {
				event=new AccordionMenuButtonEvent(AccordionMenuButtonEvent.HIDE);
				SwagDispatcher.dispatchEvent(event, this);
			} else {
				this.alpha=1;
				this.visible=true;
				event=new AccordionMenuButtonEvent(AccordionMenuButtonEvent.SHOW);
				SwagDispatcher.dispatchEvent(event, this);
			}//else
		}//onSlideDone
		
		private function addButtonToGroup(group:String):void {
			for (var item in _buttonGroups) {
				if (item==group) {
					_buttonGroups[group].push(this);
					var groupArray:Array=_buttonGroups[group] as Array;
					this._buttonIndex=groupArray.length-1;					
					return;
				}//if				
			}//for
			_buttonGroups[group]=new Array();
			_buttonGroups[group].push(this);			
			groupArray=_buttonGroups[group] as Array;
			this._buttonIndex=groupArray.length-1;				
		}//addButtonToGroup
		
		private function removeButtonFromGroup(group:String):void {
			var _updatedGroups:Array=new Array();
			for (var item in _buttonGroups) {
				_updatedGroups[item]=new Array();
				var groupArray:Array=_buttonGroups[item] as Array;				
				for (var count:uint=0; count<groupArray.length; count++) {
					var currentButton:AccordionMenuButton=groupArray[count] as AccordionMenuButton;
					if (currentButton!=this) {
						_updatedGroups[item].push(currentButton);
					}//if
				}//for					
			}//for			
			_buttonGroups=_updatedGroups;
			rescanAllButtonIndexes(this);
		}//removeButtonFromGroup		
		
		public function get index():uint {
			return (this._buttonIndex);
		}//get index
				
		
		public static function rescanAllButtonIndexes(excludeButton:AccordionMenuButton=null):void {
			for (var item in _buttonGroups) {				
				var groupArray:Array=_buttonGroups[item] as Array;				
				for (var count:uint=0; count<groupArray.length; count++) {
					var currentButton:AccordionMenuButton=groupArray[count] as AccordionMenuButton;
					if (excludeButton!=null) {
						if (currentButton!=excludeButton) {
							currentButton.rescanButtonIndex();						
						}//if
					} else {
						currentButton.rescanButtonIndex();
					}//else
				}//for					
			}//for			
		}//rescanAllButtonIndexes
		
		public function rescanButtonIndex():void {
			for (var item in _buttonGroups) {				
				var groupArray:Array=_buttonGroups[item] as Array;				
				for (var count:uint=0; count<groupArray.length; count++) {
					var currentButton:AccordionMenuButton=groupArray[count] as AccordionMenuButton;
					if (currentButton==this) {
						this._buttonIndex=count;						
						return;
					}//if
				}//for					
			}//for			
		}//rescanButtonIndex
		
		private function parseButtonXMLData():void {
			if (this._buttonXMLData==null) {
				return;
			}//if
			if (SwagDataTools.isXML(this._buttonXMLData.@text)) {
				this.text=String(this._buttonXMLData.@text);
			}//if
			if (SwagDataTools.isXML(this._buttonXMLData.@tip)) {
				this.hint=String(this._buttonXMLData.@tip);
			} else if (SwagDataTools.isXML(this._buttonXMLData.@hint)) {
				this.hint=String(this._buttonXMLData.@hint);
			} else if (SwagDataTools.isXML(this._buttonXMLData.@tooltip)) {
				this.hint=String(this._buttonXMLData.@tooltip);
			}//else if			
		}//parseButtonXMLData
		
		public function showWithDelay(delay:Number=0):void {
			if (this._delay!=null) {
				this._delay.stop();
				this._delay=null;
			}//if
			if (this.isStatic) {
				this.showNextButton(delay);
				return;
			}//if
			if (delay>0) {
				this._delay=new SwagSequence(this.onShowDelay);
				this._delay.start(delay);
			} else {				
				this.onShowDelay(this._delay);
			}//else
		}//showWithDelay
		
		private function showNextButton(animationDelay:Number):void {
			var buttonGroup:Array=getButtonGroup(this._group);			
			try {
				var nextButton:AccordionMenuButton=buttonGroup[this.index+1] as AccordionMenuButton;
				nextButton.showWithDelay(animationDelay);				
			} catch (e:*) {
				return;
			}//catch
		}//showNextButton
		
		public function onShowDelay(sequenceObj:SwagSequence):void {			
			var animationDelay:Number=0;
			if (this._delay!=null) {
				this._delay.stop();
				animationDelay=this._delay.delay;
				this._delay=null;
			}//if
			var targetYPosition:Number=this.height*this.index; //We're assuming all the buttons are the same height
			var targetXPosition:Number=0; //No gutter at this time
			this.showTo(targetXPosition, targetYPosition);	
			this.showNextButton(animationDelay);
		}//onShowDelay
		
		private function hidePreviousButton(animationDelay:Number):void {
			var buttonGroup:Array=getButtonGroup(this._group);			
			try {
				if (this.index>0) {
					var nextButton:AccordionMenuButton=buttonGroup[this.index-1] as AccordionMenuButton;
					if (nextButton!=null) {
						nextButton.hideWithDelay(animationDelay);
					}//if
				}//if
			} catch (e:*) {
				return;
			}//catch			
		}//hidePreviousButton
		
		public function hideWithDelay(delay:uint=0):void {
			if (this._delay!=null) {
				this._delay.stop();				
				this._delay=null;
			}//if
			if (this.isStatic) {
				this.hidePreviousButton(delay);
				return;
			}//if
			if (delay>0) {
				this._delay=new SwagSequence(this.onHideDelay);
				this._delay.start(delay);
			} else {				
				this.onHideDelay(this._delay);
			}//else
		}//hideWithDelay
		
		public function onHideDelay(sequenceObj:SwagSequence):void {			
			var animationDelay:Number=0;
			if (this._delay!=null) {
				this._delay.stop();
				animationDelay=this._delay.delay;
				this._delay=null;
			}//if
			var targetYPosition:Number=0;
			var targetXPosition:Number=0;
			this.hideTo(targetXPosition, targetYPosition);	
			this.hidePreviousButton(animationDelay);
		}//onShowDelay
				
		/**
		 * Opens the associated group of accordion buttons.
		 * <p>If no associated button group can be found, nothing happens.</p>
		 *  
		 * @param group The group of buttons to open.
		 * @param animationDelay The cascading delay between buttons in milliseconds. All buttons will 
		 * animate at the same time if this value is 0.
		 * 
		 */
		public static function openGroup(group:String, animationDelay:Number=0):void {			
			var buttonGroup:Array=getButtonGroup(group);			
			if (buttonGroup==null) {
				return;
			}//if
			if (buttonGroup.length==0) {
				return;
			}//if			
			var initialButton:AccordionMenuButton=buttonGroup[0] as AccordionMenuButton;			
			initialButton.showWithDelay(animationDelay);
		}//openGroup
		
		/**
		 * Closes the associated group of accordion buttons.
		 * <p>If no associated button group can be found, nothing happens.</p>
		 *  
		 * @param group The group of buttons to close.
		 * @param animationDelay The cascading delay between buttons in milliseconds. All buttons will 
		 * animate at the same time if this value is 0.
		 * 
		 */
		public static function closeGroup(group:String, animationDelay:Number=0):void {			
			var buttonGroup:Array=getButtonGroup(group);			
			if (buttonGroup==null) {
				return;
			}//if
			if (buttonGroup.length==0) {
				return;
			}//if
			var endButtonIndex:uint=buttonGroup.length-1;
			var initialButton:AccordionMenuButton=buttonGroup[endButtonIndex] as AccordionMenuButton;			
			initialButton.hideWithDelay(animationDelay);
		}//closeGroup
		
		override public function setDefaults(eventObj:Event):void {
			this.visible=false;
			this.alpha=0;
			this.parseButtonXMLData();
			super.setDefaults(eventObj);			
		}//setDefaults
		
		override public function addListeners():void {
			SwagDispatcher.addEventListener(MovieClipButtonEvent.ONCLICK, this.onMenuButtonClick, this, this);
			super.addListeners();
		}//addListeners
		
		override public function removeListeners():void {
			SwagDispatcher.removeEventListener(MovieClipButtonEvent.ONCLICK, this.onMenuButtonClick, this);
			super.removeListeners();
		}//removeListeners
		
		override public function destroy(... args):void {
			this.removeButtonFromGroup(this._group);
			this._group=null;
			this._buttonData=null;
			this._buttonXMLData=null;
			if (this._tooltip!=null) {
				this._tooltip.destroy();
				this._tooltip=null;
			}//if
			this.removeListeners();
			super.destroy.call(super, args);
		}//destroy
		
	}//AccordionMenuButton class
	
}//package