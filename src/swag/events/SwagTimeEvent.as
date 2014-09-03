package swag.events {
	
	/**
	 * Contains a number of constant properties used by the <code>SwagTime</code> class to dispatch events via the <code>SwagDispatcher</code>.
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
	 * 
	 */
	public class SwagTimeEvent extends SwagEvent {
		
		/**
		 * Dispatched when the associated <code>SwagTime</code> object begins a count down operation. 
		 */
		public static const STARTCOUNTDOWN:String="SwagEvent.SwagTimeEvent.STARTCOUNTDOWN";
		/**
		 * Dispatched on each tick of the associated <code>SwagTime</code>'s timer during a count down operation.
		 * <p>This even may not be dispatched if the count down is launched in <em>silent</em> mode.</p> 
		 */
		public static const ONCOUNTDOWN:String="SwagEvent.SwagTimeEvent.ONCOUNTDOWN";
		/**
		 * Dispatched when the associated <code>SwagTime</code> object's count down is stopped via a method call. 
		 */
		public static const STOPCOUNTDOWN:String="SwagEvent.SwagTimeEvent.STOPCOUNTDOWN";
		/**
		 * Dispatched when the associated <code>SwagTime</code> object ends a count down operation. A
		 * <code>SwagTimeEvent.STOPCOUNTDOWN</code> event is also broadcast at the same time.
		 */
		public static const ENDCOUNTDOWN:String="SwagEvent.SwagTimeEvent.ENDCOUNTDOWN";
		/**
		 * Dispatched when the associated <code>SwagTime</code> object begins a count up operation. 
		 */
		public static const STARTCOUNTUP:String="SwagEvent.SwagTimeEvent.STARTCOUNTUP";
		/**
		 * Dispatched on each tick of the associated <code>SwagTime</code>'s timer during a count up operation.
		 * <p>This even may not be dispatched if the count up is launched in <em>silent</em> mode.</p> 
		 */
		public static const ONCOUNTUP:String="SwagEvent.SwagTimeEvent.ONCOUNTUP";
		/**
		 * Dispatched when the associated <code>SwagTime</code> object's count up is stopped via a method call. 
		 */
		public static const STOPCOUNTUP:String="SwagEvent.SwagTimeEvent.STOPCOUNTUP";
		/**
		 * Dispatched when the associated <code>SwagTime</code> object ends a count up operation. A
		 * <code>SwagTimeEvent.STOPCOUNTUP</code> event is also broadcast at the same time.
		 */
		public static const ENDCOUNTUP:String="SwagEvent.SwagTimeEvent.ENDCOUNTUP";
		/**
		 * Dispatched when the associated <code>SwagTime</code> object's count down operation is reset. 
		 */
		public static const RESETCOUNTDOWN:String="SwagEvent.SwagTimeEvent.RESETCOUNTDOWN";
		/**
		 * Dispatched when the associated <code>SwagTime</code> object's count up operation is reset. 
		 */
		public static const RESETCOUNTUP:String="SwagEvent.SwagTimeEvent.RESETCOUNTUP";
		
		/**
		 * Default constructor for the <code>SwagTimeEvent</code> class.
		 *  
		 * @param eventType The type of event to associate with the instance. It's advisable to use
		 * one of the provided class constants instead of direct string values in order to maintain forward compatibiliy.
		 * @param args Optional parameters to include with the event (passed to super constructor in <code>SwagEvent</code> class).
		 * 
		 * @see swag.events.SwagEvent()
		 * 
		 */
		public function SwagTimeEvent(eventType:String=null)	{
			super(eventType);
		}//constructor
		
	}//SwagTimeEvent class
	
}//package