package socialcastr.ui.input {
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.None;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	
	import socialcastr.References;
	import socialcastr.events.TextInputEvent;
	import socialcastr.interfaces.ui.input.ITextInput;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.core.instances.SwagMovieClip;
	import swag.events.SwagMovieClipEvent;
	
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
	public class TextInput extends MovieClip implements ITextInput {
		
		private var _field:TextField=null;
		private var _format:TextFormat;
		private var _font:String="_sans";
		private var _multiline:Boolean=false;
		private var _wordWrap:Boolean=false;
		private var _antiAliasType:String="advanced";
		private var _sharpness:Number=0;
		private var _fontSize:Number=12;
		private var _fontColour:Number=0x000000;
		private var _selectionGlowColour:uint=0xFFFFFF;
		private var _backgroundColour:uint=0x0A0A0A;
		private var _editColour:uint=0xFFFFFF;
		private var _playbackControl:SwagMovieClip;
		private var _glowFilter:GlowFilter;
		private var _glowTween:Tween;		
		private var _enterKeyInput:Boolean=false;
		private var _editModeActive:Boolean=false;
		private var _passwordMode:Boolean=false;
		private var _firstEditActivation:Boolean=true; //Controls where the caret appears if text is already present in the field.
		
		public function TextInput()	{
			this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);			
		}//constructor		
		
		private function onMouseOver(eventObj:MouseEvent):void {			
			this._playbackControl.playToNextLabel("over", false, false);
			if (this._glowFilter==null) {				
				this._glowFilter=new GlowFilter(this.selectionGlowColour, 1, 0, 0, 3, 3, false, false);
			}//if
			if (this._glowTween!=null) {
				this._glowTween.stop();
				this._glowTween=null;
			}//if
			if (this._glowFilter.blurX<5) {
				this._glowTween=new Tween(this._glowFilter, "blurX", None.easeNone, 0, 5, 5, false);
				this._glowTween.addEventListener(TweenEvent.MOTION_CHANGE, this.onBlurFilterUpdate);
			}//if			
		}//onMouseOver
		
		private function onMouseOut(eventObj:MouseEvent):void {
			if (this._editModeActive) {
				return;
			}//if
			this._playbackControl.playToNextLabel("out", false, false);
			if (this._glowFilter==null) {				
				this._glowFilter=new GlowFilter(this.selectionGlowColour, 1, 5, 5, 3, 3, false, false);
			}//if
			if (this._glowTween!=null) {
				this._glowTween.stop();
				this._glowTween=null;
			}//if
			if (this._glowFilter.blurX>0) {
				this._glowTween=new Tween(this._glowFilter, "blurX", None.easeNone, 5, 0, 5, false);
				this._glowTween.addEventListener(TweenEvent.MOTION_CHANGE, this.onBlurFilterUpdate);
			}//if
		}//onMouseOut
		
		private function onClick(eventObj:MouseEvent):void {
			References.debugPanel.debug("Clicked on field: "+this._field.name)
			this.activateEditMode();
		}//onClick
		
		public function set editMode(modeSet:Boolean):void {
			if ((this._editModeActive) && (modeSet==false)) {
				this.deactivateEditMode();
			}//if
			if ((this._editModeActive==false) && (modeSet)) {
				this.activateEditMode();
			}//if
		}//set editMode
		
		public function set text(textSet:*):void {
			this._field.text=String(textSet);
		}//set text
		
		public function get text():String {
			var returnString:String=new String();
			returnString=this._field.text;
			return (returnString);
		}//get text
		
		public function get editMode():Boolean {
			return (this._editModeActive);
		}//get editMode
		
		private function activateEditMode():void {			
			this._editModeActive=true;			
			SwagDispatcher.addEventListener(SwagMovieClipEvent.END, this.onEditModeActivate, this, this._playbackControl);			
			this._playbackControl.playToNextLabel("edit", false, false);
			if (this._glowTween!=null) {
				this._glowTween.stop();
				this._glowTween=null;
			}//if
			if (this._glowFilter.blurX<5) {
				this._glowTween=new Tween(this._glowFilter, "blurX", None.easeNone, 0, 5, 5, false);
				this._glowTween.addEventListener(TweenEvent.MOTION_CHANGE, this.onBlurFilterUpdate);
			}//if	
			this.removeListeners();
			this.applyFormat();		
			this._field.visible=false;				
			var event:TextInputEvent=new TextInputEvent(TextInputEvent.EDIT);
			SwagDispatcher.dispatchEvent(event, this);			
		}//activateEditMode
		
		private function deactivateEditMode(... args):void {
			if (SwagSystem.isMobile) {							
				this._field.removeEventListener(SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE, this.deactivateEditMode);
			}//if
			this._editModeActive=false;
			this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyPress);
			this._field.type=TextFieldType.DYNAMIC;
			this._field.visible=false;
			this.applyFormat();
			SwagDispatcher.addEventListener(SwagMovieClipEvent.END, this.onEditModeDeactivate, this, this._playbackControl);			
			this._playbackControl.playToNextLabel("editEnd", false, false);
			this._glowFilter=new GlowFilter(this.selectionGlowColour, 1, 0, 0, 3, 3, false, false);
			this.filters=[this._glowFilter];
			if (this._glowTween!=null) {
				this._glowTween.stop();
				this._glowTween=null;
			}//if
			this._glowTween=new Tween(this._glowFilter, "blurX", None.easeNone, 5, 0, 5, false);
			this._glowTween.addEventListener(TweenEvent.MOTION_CHANGE, this.onBlurFilterUpdate);			
			this.addListeners();
			var event:TextInputEvent=new TextInputEvent(TextInputEvent.ONEDIT);
			SwagDispatcher.dispatchEvent(event, this);
		}//deactivateEditMode
		
		public function onEditModeActivate(eventObj:SwagMovieClipEvent):void {	
			SwagDispatcher.removeEventListener(SwagMovieClipEvent.END, this.onEditModeActivate, this._playbackControl);			
			this._field.mouseEnabled=true;
			this._field.visible=true;			
			this._field.type=TextFieldType.INPUT;
			if (this._firstEditActivation) {
				this._firstEditActivation=false;
				this._field.setSelection(this.text.length, this.text.length);
			} else {
				this._field.setSelection(this._field.caretIndex,this._field.caretIndex);
			}//else
			if (SwagSystem.isMobile) {			
				//Must be called before setting focus!				
				this._field.addEventListener(SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE, this.deactivateEditMode);
				//For downward compilability (CS5)
				this.stage["softKeyboardInputAreaOfInterest"]=this._field.getBounds(this.stage) as Rectangle;
				this._field["requestSoftKeyboard"]();
			}//if
			this.stage.focus=this._field;			
			if (this._enterKeyInput) {
				this.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyPress);
			}//if
		}//onEditModeActivate
		
		public function onEditModeDeactivate(eventObj:SwagMovieClipEvent):void {			
			SwagDispatcher.removeEventListener(SwagMovieClipEvent.END, this.onEditModeDeactivate, this._playbackControl);	
			SwagDispatcher.removeEventListener(SwagMovieClipEvent.FRAME, this.onEditModeUpdate, this._playbackControl);
			this._field.mouseEnabled=false;
			this._field.visible=true;			
		}//onEditModeDeactivate
		
		public function onEditModeUpdate(evebtObj:SwagMovieClipEvent):void {			
		}//onEditModeUpdate
		
		private function onKeyPress(eventObj:KeyboardEvent):void {
			if (eventObj.keyCode==13) {				
				this.deactivateEditMode();
			}//if
		}//onKeyPress
		
		private function onBlurFilterUpdate(eventObj:TweenEvent):void {
			this._glowFilter.blurY=this._glowFilter.blurX;
			if (this._glowFilter.blurX>0) {
				this.filters=[this._glowFilter];
			} else {
				this.filters=[];
			}//else
		}//onBlurFilterUpdate
		
		[Inspectable (name="Multiline enabled", defaultValue="false")]
		public function set multiline(multilineSet:Boolean):void {
			this._multiline=multilineSet;
			if (this._field!=null) {
				this._field.multiline=multilineSet;
			}//if
		}//set multiline
		
		public function get multiline():Boolean {			
			return (this._multiline);
		}//get multiline
		
		[Inspectable (name="Word wrap enabled", defaultValue="false")]
		public function set wordWrap(wrapSet:Boolean):void {
			this._wordWrap=wrapSet;
			if (this._field!=null) {
				this._field.wordWrap=wrapSet;
			}//if
		}//set wordWrap
		
		public function get wordWrap():Boolean {
			return (this._wordWrap);
		}//get wordWrap
		
		
		[Inspectable (name="Field background colour", type="Color", defaultValue="#000000")]
		public function set backgroundColour(colourSet:Number):void {
			this._backgroundColour=colourSet;		
		}//set backgroundColour
		
		public function get backgroundColour():Number {
			return (this._backgroundColour);
		}//get backgroundColoud
		
		[Inspectable (name="Font colour", type="Color", defaultValue="#000000")]
		public function set fontColour(colourSet:Number):void {
			this._fontColour=colourSet;
			if (this._format==null) {
				this._format=new TextFormat();				
			}//if			
			this._format.color=colourSet;		
			this.applyFormat();
		}//set fontColour
		
		public function get fontColour():Number {			
			return (this._fontColour);
		}//get fontColour
		
		[Inspectable (name="Default font size", defaultValue="12")]
		public function set fontSize(sizeSet:Number):void {
			this._fontSize=sizeSet;
			if (this._format==null) {
				this._format=new TextFormat();				
			}//if
			this._format.size=sizeSet;			
			this.applyFormat();
		}//set fontSize
		
		public function get fontSize():Number {			
			return (this._fontSize);
		}//get fontSize
		
		[Inspectable (name="Antialiasing", type="String", defaultValue="advanced", enumeration="advanced,normal")]
		public function set antiAliasType(typeSet:String):void {
			this._antiAliasType=typeSet;
			if (this._field!=null) {
				this._field.antiAliasType=typeSet;
			}//if			
		}//set antiAliasType
		
		public function get antiAliasType():String {			
			return (this._antiAliasType);
		}//get antiAliasType
		
		[Inspectable (name="Sharpness (-400 to 400)", defaultValue="0")]
		public function set sharpness(sharpSet:Number):void {
			this._sharpness=sharpSet;
			if (this._field!=null) {
				this._field.sharpness=sharpSet;
			}//if				
		}//set sharpness
		
		public function get sharpness():Number {			
			return (this._sharpness);
		}//get sharpness
		
		[Inspectable (name="Embedded font", defaultValue="_sans")]
		public function set font(fontSet:String):void {	
			this._font=fontSet;
			if (this._format==null) {
				this._format=new TextFormat();
			}//if
			this._format.font=fontSet;
			this.applyFormat();
		}//set font
		
		public function get font():String {			
			return (this._font);
		}//get font
		
		[Inspectable (name="ENTER key ends edit", defaultValue="false")]
		public function set enterKeyInput(keySet:Boolean):void {
			this._enterKeyInput=keySet;			
		}//set enterKeyInput
		
		public function get enterKeyInput():Boolean {			
			return (this._enterKeyInput);
		}//get enterKeyInput
		
		[Inspectable (name="Password mode (hide type)", defaultValue="false")]
		public function set password(passwordSet:Boolean):void {
			this._passwordMode=passwordSet;
			if (this._field!=null) {
				this._field.displayAsPassword=this._passwordMode;
			}//if
		}//set password
		
		public function get password():Boolean {			
			return (this._passwordMode);
		}//get password
		
		[Inspectable (name="Selection glow colour", type="Color", defaultValue="#FFFFFF")]
		public function set selectionGlowColour(colourSet:uint):void {
			this._selectionGlowColour=colourSet;		
		}//set selectionGlowColour
		
		public function get selectionGlowColour():uint {			
			return (this._selectionGlowColour);
		}//get selectionGlowColour
		
		public function get usingEmbedFont():Boolean {
			return (this.isEmbeddedFont(this.font));
		}//get usingEmbedFont
		
		private function createInputField():TextField {
			if (this._field!=null) {
				return (this._field);
			}//if
			this._field=new TextField();
			this._field.type=TextFieldType.DYNAMIC;
			this._field.mouseEnabled=false;
			this._field.multiline=this.multiline;
			this._field.wordWrap=this.wordWrap;
			this._field.displayAsPassword=this._passwordMode;
			this._field.width=this.width;
			this._field.height=this.height;				
			//Updated coordinates since it'll be sitting in the parent container...
			this._field.x=this.x-(this.width/2);
			this._field.y=this.y-(this.height/2);
			if (SwagSystem.isMobile) {
				//For downward compatability (CS5)
				this._field["needsSoftKeyboard"]=true;
			}//if
			return (this._field);
		}//createInputField		
		
		private function applyFormat():void {
			if (this._format==null) {				
				this._format=new TextFormat();
				this._format.size=this.fontSize;
				this._format.font=this.getFontByLinkage("Cabin");				
			}//if					
			if (this._field!=null) {					
				this._field.sharpness=this.sharpness;				
				this._field.antiAliasType=this.antiAliasType;
				this._field.wordWrap=this.wordWrap;
				this._field.multiline=this.multiline;
				this._field.displayAsPassword=this._passwordMode;
				if (this.isEmbeddedFont(this.font)) {						
					this._format.font=this.getFontByLinkage("Cabin");
					this._field.embedFonts=true;
				} else {					
					this._field.embedFonts=false;
				}//else				
				this._field.setTextFormat(this._format);
				this._field.defaultTextFormat=this._format;					
			}//if
		}//applyFormat
		
		private function getFontByLinkage(linkageID:String):String {
			var fontClass:Class=SwagSystem.getDefinition(linkageID);		
			if (fontClass==null) {
				return ("");
			}//if
			var fontInstance:Font=new fontClass();						
			return (fontInstance.fontName);
		}//getFontByLinkage
		
		private function isEmbeddedFont(fontName:String):Boolean {
			if ((fontName==null) || (fontName=="")) {
				return (false);
			}//if						
			var fontClass:Class=SwagSystem.getDefinition(fontName);
			if (fontClass!=null) {				
				return (true);
			}//if
			return (false);
		}//isEmbeddedFont
		
		private function addListeners():void {		
			this.addEventListener(MouseEvent.MOUSE_OVER, this.onMouseOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut);
			this.addEventListener(MouseEvent.CLICK, this.onClick);	
		}//addListeners
		
		private function removeListeners():void {			
			this.removeEventListener(MouseEvent.MOUSE_OVER, this.onMouseOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut);
			this.removeEventListener(MouseEvent.CLICK, this.onClick);	
		}//removeListeners
		
		private function setDefaults(eventObj:Event):void {
			this.gotoAndStop(1);
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);						
			this.parent.addChild(this.createInputField());					
			this.applyFormat();
			this._playbackControl=new SwagMovieClip(this);			
			this.addListeners();			
		}//setDefaults
		
		/**
		 * Used to provide backward compatibility with older compilers targetting a newer version of the Flash player.
		 * (Can be removed and the real class imported when available.)
		 *  
		 * @return A reference to the <code>SoftKeyboardEvent</code> class or <em>null</em> if the current runtime doesn't support it.
		 * 
		 */
		public static function get SoftKeyboardEvent():Class {
			return (SwagSystem.getDefinition("flash.events.SoftKeyboardEvent") as Class);
		}//get SoftKeyboardEvent
		
	}//TextInput class
	
}//package