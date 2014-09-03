package swag.events {
	
	import swag.events.SwagEvent;
	import swag.interfaces.core.instances.ISwagZipEvent;
	
	public class SwagZipEvent extends SwagEvent implements ISwagZipEvent {
		
		/**
		 * Invoked when the associated <code>SwagZip</code> object has completed parsing the Zip file's directory info.
		 * <p>The Zip data of the <code>SwagZip</code> can only be used once this information has been
		 * parsed, otherwise it's not possible to know where individual files / directories begin, how
		 * large they are, etc.</p>
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
		public static const PARSEDIRECTORY:String="SwagEvent.SwagZipEvent.PARSEDIRECTORY";
		/**
		 * Invoked when the associated <code>SwagZip</code> object has completed parsing the Zip file's
		 * main header information.
		 * <p>This event will be broadcast first, before <code>SwagZipEvent.PARSEDIRECTORY</code>.</p>
		 */
		public static const PARSEHEADER:String="SwagEvent.SwagZipEvent.PARSEHEADER";
		
		/**
		 * Default constructor for the class.
		 *  
		 * @param eventType The type of event to create.
		 * @param args Additional arguments to provide to the event. These include:
		 * <ul>
		 * <li>parameters (<code>Array</code>) - Optional parameters to pass to the receiving listener. The parameters specified here
		 * are persistent -- they are maintained while the event object remains active. This allows updated values to be passed to
		 * subsequent listeners, but for the same reason the <code>parameters</code> object should not be assumed to have the same
		 * properties as when the event dispatch began.</li>
		 * </ul>
		 * 
		 */
		public function SwagZipEvent(eventType:String=null, ... args) {
			super(eventType, args);
		}//constructor
		
	}//SwagZipEvent class
	
}//package