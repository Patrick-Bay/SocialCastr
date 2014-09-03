package socialcastr.events {
	
	import swag.events.SwagEvent;
	
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
	public class LoadingIndicatorEvent extends SwagEvent {
		
		/**
		 * Causes the loading indicator to show itself.   
		 */
		public static const SHOW:String="SwagEvent.LoadingIndicatorEvent.SHOW";
		/**
		 * Broadcast when the loading indicator has completed showing itself.
		 */
		public static const ONSHOW:String="SwagEvent.LoadingIndicatorEvent.ONSHOW";
		/**
		 * Causes the loading indicator to hide itself.   
		 */
		public static const HIDE:String="SwagEvent.LoadingIndicatorEvent.HIDE";
		/**
		 * Broadcast when the loading indicator has completed hiding itself.
		 */
		public static const ONHIDE:String="SwagEvent.LoadingIndicatorEvent.ONHIDE";
		/**
		 * Causes the loading indicator to begin its loading animation(s).   
		 */
		public static const START:String="SwagEvent.LoadingIndicatorEvent.START";
		/**
		 * Causes the loading indicator to stop its loading animation(s).   
		 */
		public static const STOP:String="SwagEvent.LoadingIndicatorEvent.STOP";
		/**
		 * Updates the loading indicator with a new text value. The variable <code>updateText</code> is used
		 * to store this value (it is ignored for all other loading indicator events).   
		 */
		public static const UPDATE:String="SwagEvent.LoadingIndicatorEvent.STOP";
		
		public var updateText:String=new String();
		
		public function LoadingIndicatorEvent(eventType:String=null) {
			super(eventType);
		}//constructor
		
	}//LoadingIndicatorEvent class
	
}//package