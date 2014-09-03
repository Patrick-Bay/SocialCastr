package swag.events {
	
	import flash.display.InteractiveObject;
	
	import swag.events.SwagEvent;
	import swag.interfaces.events.ISwagMouseEvent;
	
	/**
	 * Used to dispatch mouse related events for the SwAG toolkit.
	 * <p>SwAG mouse events are similar, and often mimic, the functionality of the standard Flash MouseEvent, but
	 * also provide additional features and information.</p>
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
	public class SwagMouseEvent extends SwagEvent implements ISwagMouseEvent	{		
		
		/**
		 * Mimics the functionality of the standard MouseEvent.CLICK event 
		 */
		public static const CLICK:String="SwagEvent.SwagMouseEvent.CLICK";
		/**
		 * Mimics the functionality of the standard MouseEvent.DOUBLE_CLICK event, also enabling and
		 * setting any required properties for the associated display object. 
		 */
		public static const DOUBLE_CLICK:String="SwagEvent.SwagMouseEvent.DOUBLE_CLICK";
		/**
		 * Mimics the functionality of the standard MouseEvent.MOUSE_DOWN event. 
		 */
		public static const DOWN:String="SwagEvent.SwagMouseEvent.DOWN";
		/**
		 * Mimics the functionality of the standard MouseEvent.MOUSE_UP event. 
		 */
		public static const UP:String="SwagEvent.SwagMouseEvent.UP";
		/**
		 * Mimics the functionality of the standard MouseEvent.MOUSE_OVER event. 
		 */
		public static const OVER:String="SwagEvent.SwagMouseEvent.OVER";
		/**
		 * Mimics the functionality of the standard MouseEvent.MOUSE_OUT event. 
		 */
		public static const OUT:String="SwagEvent.SwagMouseEvent.OUT";
		/**
		 * Mimics the functionality of the standard MouseEvent.ROLL_OVER event. 
		 */
		public static const ROLL_OVER:String="SwagEvent.SwagMouseEvent.ROLL_OVER";
		/**
		 * Mimics the functionality of the standard MouseEvent.ROLL_OUT event. 
		 */
		public static const ROLL_OUT:String="SwagEvent.SwagMouseEvent.ROLL_OUT";
		/**
		 * Mimics the functionality of the standard MouseEvent.MOUSE_WHEEL event. 
		 */
		public static const WHEEL:String="SwagEvent.SwagMouseEvent.WHEEL";		
		
		/**
		 * Default constructor for the event class.
		 *  
		 * @param eventType The event type to create. Use one of the associated class constants to associate
		 * with the event instance.
		 * 
		 */
		public function SwagMouseEvent(eventType:String=null) {
			this.type=eventType;
		}//constructor	
		
	}//SwagMouseEvent class
	
}//package