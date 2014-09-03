package socialcastr.ui.input {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import swag.effects.SwagColour;
	
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
	public class TextInputBackground extends MovieClip	{
		
		var _colourObj:SwagColour;
		
		public function TextInputBackground() {
			this.addEventListener(Event.ADDED, this.setDefaults);
			super();			
		}//constructor
		
		public function setTint(tintColour:uint):void {					
			this._colourObj.RGB=tintColour;
			this._colourObj.applyTint(this);		
		}//setTint
		
		private function frameLoop(eventObj:Event):void {
			if (this.parent["editMode"]!=undefined) {
				if (this.parent["editMode"]) {					
					if (this.parent["editColour"]!=undefined) {
						this.setTint(this.parent["editColour"]);
					}//if
				} else {					
					if (this.parent["backgroundColour"]!=undefined) {
						this.setTint(this.parent["backgroundColour"]);
					}//if
				}//else
			}//if			
		}//frameLoop
		
		public function setDefaults(eventObj:Event):void {			
			this.removeEventListener(Event.ADDED, this.setDefaults);			
			this.addEventListener(Event.ENTER_FRAME, this.frameLoop);		
			this._colourObj=new SwagColour();
		}//setDefaults
		
	}//TextInputBackground class
	
}//package