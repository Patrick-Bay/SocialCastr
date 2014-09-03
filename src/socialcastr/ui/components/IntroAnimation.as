package socialcastr.ui.components {
	
	import flash.events.Event;
	import swag.core.SwagSystem;
	import socialcastr.References;
	
	import swag.core.instances.SwagMovieClip;
	
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
	public class IntroAnimation extends SwagMovieClip {
		
		public function IntroAnimation() {
			References.debug ("IntroAnimation: created.");
			References.introAnimation=this;
			this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			super(this);
		}//constructor
		
		public function setDefaults(eventObj:Event):void {			
			this.visible=false;
			this.alpha=1;
			this.gotoAndStop(1);
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			//References.main.loadSettings();
		}//setDefaults
		
	}//IntroAnimation class
	
}//package