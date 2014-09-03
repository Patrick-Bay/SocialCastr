package swag.events {
	
	import swag.interfaces.events.ISwagEvent;
	
	/**
	 * The base class for all Swag events. This class may be sub-classed, or sent directly, to the <code>SwagDispatcher</code>.
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
	public class SwagEvent implements ISwagEvent {
		
		/**
		 * The default <code>SwagEvent</code> type. The string value "swagDefaultEvent" may also be used but
		 * using this constant value is advisable in order to prevent potentially numerous code updates if it ever changes. 
		 */
		public static const DEFAULT:String="SwagEvent.DEFAULT";
		/**
		 * @private 
		 */
		private var _type:String=null;
		/**
		 * @private 
		 */
		private var _source:*=null;
		
		/**
		 * The default constructor for the SwagEvent class. 
		 *  
		 * @param eventType The type of event to create. It's highly advisable to use one of the event constant strings 
		 * provided with the various event types in order to easily maintain code changes (especially if event types 
		 * change in future revisions).
		 * 
		 * @see swag.core.SwagDispatcher
		 */
		public function SwagEvent(eventType:String=null) {
			this.type=eventType;
		}//constructor		
		
		/**
		 * 
		 * The event type string, typically one of the <code>SwagEvent</code>-derived types defined in the toolkit.
		 * 
		 */
		public function get type():String {
			return (this._type);
		}//get type
		
		public function set type(typeSet:String):void {
			this._type=typeSet;
		}//set type
		
		/**
		 * 
		 * A reference to the source object that dispatched this event instance.
		 * 
		 */
		public function get source():* {
			return (this._source);
		}//get source
		
		public function set source(sourceSet:*):void {
			this._source=sourceSet;
		}//set source
		
	}//SwagEvent class
	
}//package