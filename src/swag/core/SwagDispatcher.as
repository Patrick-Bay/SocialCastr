package swag.core {
		
	import swag.core.instances.SwagEventListener;
	import swag.events.*;
	import swag.interfaces.core.ISwagDispatcher;
	import swag.interfaces.events.ISwagEvent;		
	/**
	 * Provides global event broadcasting capabilities similar to the standard Flash event system.
	 * <p>Unlike Flash events, the SwAG event system is decoupled by default (event listeners are not required to be
	 * bound to specific dispatchers), thereby providing a much greater degree of flexibility. For example, listeners
	 * may be established before the dispatching object exists, which means that an application can be assembled at
	 * runtime without the need for any specific load order. Furthermore, decoupled events allow the application to
	 * dispatch from / listen to static objects, something that is not supported with the standard event system.</p>
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
	public class SwagDispatcher implements ISwagDispatcher {		
		
		private static var _listeners:Vector.<SwagEventListener>;		
		
		/**
		 * Dispatches a standard, de-coupled <code>SwagEvent</code>-type event. 
		 * <p>Like standard Flash events, SwAG events are matched according to their <code>type</code> property.
		 * Unlike standard Flash events, however, SwAG events are not bubbled or propagated through the class inheritance 
		 * chain. Rather, they are broadcast on a first-come, first-serve basis (in the order in which they're added), 
		 * anywhere throughout the application.</p>
		 * 
		 * @param eventObj A <code>SwagEvent</code> instance, extending instance, or implementation of <code>ISwagEvent</code>
		 * @param source The source object (the object / class / instance / etc.) from which the event is being dispatched. Listeners 
		 * that are not bound to a specific dispatcher will be invoked regardless of this parameter, but methods bound to only a specific
		 * dispatcher use this value to determine whether or not they should be invoked. 
		 * 
		 */
		public static function dispatchEvent(eventObj:ISwagEvent, source:*):Boolean {	
			if (eventObj==null) {
				trace ("swag.core.SwagDispatcher.dispatchEvent() error: event object parameter (eventObj) is null!");
				return (false);
			}//if
			if (source==null) {
				trace ("swag.core.SwagDispatcher.dispatchEvent() error: source parameter is null!");
				return (false);
			}//if
			var listenerCount:uint=listeners.length;
			var dispatchSent:Boolean=false;			
			//Prefetch the listener count in case new ones are added or removed while dispatching
			for (var count:uint=0; count<listenerCount; count++) {
				//Array may be manipulated while dispatching so do this check every time.
				if (listeners.length<=count) {
					return (dispatchSent);
				}//if					
				var currentListener:SwagEventListener=listeners[count] as SwagEventListener;				
				if ((eventObj.type==currentListener.type) && sourcesMatch(source, currentListener.source)) {					
					if (currentListener.invoke(eventObj, source)==false) {
						removeEventListener(currentListener.type, currentListener.method);
					} else {
						dispatchSent=true;
					}//else
				}//if
			}//for		
			return (dispatchSent);
		}//dispatchEvent		
		
		/**
		 * Adds an event listener to the <code>SwagDispatcher</code>.
		 * <p>The format of the listener is very similar to a standard Flash event but, because <code>SwagDispatcher</code> events
		 * can be decoupled, it also provides an optional <code>sourceObject</code> property for event filtering based on the dispatcher, as
		 * well as a reference to the containing object (<code>thisRef</code>) which the dispatcher uses to intelligently invoke listening
		 * methods (ones that don't necessarily match the required format -- a <code>SwagEvent</code>-type object as the first parameter).</p>
		 * 
		 * @param eventType The event type to broadcast. While this may be a standard string, it's advisable to use the various event
		 * string constants provided with the event objects in order to prevent having to implement numerous changes if event strings ever change.
		 * @param eventMethod The method to invoke when the <code>eventType</code> is dispatched.
		 * @param thisRef A reference to the object (class, instance, etc.), containing the method to be invoked. If this parameter is not supplied,
		 * or is <em>null</em>, the event is unable to verify that the listening method has the correct parameters and this may result in runtime
		 * errors (i.e. you must be careful to include a <code>SwagEvent</code> or related type as the first parameter). If <code>thisRef</code> is
		 * supplied and contains the target method, the event broadcaster attempts to invoke the event method more intelligently (i.e. the dispatcher
		 * will attempt to invoke the method with the correct parameter types, even if they don't match the standard event listener method format). 
		 * @param sourceObject The object(s) from which the event is expected. If this is <em>null</em>, any object will be considered a match
		 * for the event, otherwise only the specified object(s) will be a match and other events, even if they have the same <code>eventType</code>,
		 * won't invoke the <code>eventMethod</code>. This parameter may either be a singular object or an array of object references.
		 * @return The newly created <code>SwagEventListener</code> instance created, or <em>null</em> if there was a problem creating the listener.
		 * 
		 * @see swag.core.instances.SwagEventListener
		 * 
		 */
		public static function addEventListener(eventType:String, eventMethod:Function, thisRef:*=null, sourceObject:*=null):SwagEventListener {
			if ((eventType==null) || (eventMethod==null)) {
				return (null);
			}//if			
			if (eventType=="") {
				return (null);
			}//if			
			var newEventListener:SwagEventListener=new SwagEventListener(eventType, eventMethod, thisRef, sourceObject);
			listeners.push(newEventListener);
			return (newEventListener);
		}//addEventListener
		
		/**
		 * Removes an event listener created with the <code>addEventListener</code> method.
		 *  
		 * @param eventType The event type to remove. This, along with the <code>eventMethod</code> and, optionally, the 
		 * <code>sourceObject</code>, are used to determine which listener(s) should be removed.
		 * @param eventMethod The method associated with the event to remove.
		 * @param sourceObject The optional source object associated with the event to remove. If this is <em>null</em>,
		 * this parameter is essentially ignored. If this is a singular object reference, it must match the object used
		 * to register the event with the <code>addEventListener</code> call. If this object is an array, any of the objects
		 * in the array are considered a source match for removal.
		 * 
		 * @return <em>True</em> is the listener was successfully removed, <em>false</em> if there was a problem or
		 * no associated listener could be found to remove.
		 * 
		 * @see addEventListener()
		 */
		public static function removeEventListener(eventType:String, eventMethod:Function, sourceObject:*=null):Boolean {
			if ((eventType==null) || (eventMethod==null)) {
				return (false);
			}//if
			if (eventType=="") {
				return (false);
			}//if
			var listenerCount:uint=listeners.length;
			//Prefetch the listener count in case new ones are added or removed while removing
			for (var count:uint=0; count<listenerCount; count++) {
				var currentListener:SwagEventListener=listeners[count] as SwagEventListener;
				if ((currentListener.type==eventType) && (currentListener.method==eventMethod) && (sourcesMatch(sourceObject, currentListener.source))) {
					listeners.splice(count,1);
					return (true);
				}//if
			}//for
			return (false);
		}//removeEventListener
		
		/**
		 * Removes any orphaned event listeners created by the <code>SwagDispatcher</code>. Orphaned listeners are those that still 
		 * exit in memory but whose type or listening methods are <em>null</em> (no longer exist). Removing orphaned listeners helps to 
		 * maintain application memory by removing any references which will no longer be used. 
		 * 
		 */
		public static function removeOrphanedListeners():void {
			var listenerCount:uint=listeners.length;
			for (var count:uint=0; count<listenerCount; count++) {
				var currentListener:SwagEventListener=listeners[count] as SwagEventListener;
				if ((currentListener.type==null)|| (currentListener.method==null)) {
					listeners.splice(count,1);					
				}//if
			}//for
		}//removeOrphanedListeners
		
		/**
		 * Stores a packed vector array of all registered <code>SwagEventListener</code> objects.
		 *  
		 * @return A vector array of <code>SwagEventListener</code> objects.
		 * 
		 * @see swag.core.instances.SwagEventListener
		 */
		public static function get listeners():Vector.<SwagEventListener> {
			if (_listeners==null) {
				_listeners=new Vector.<SwagEventListener>()
			}//if
			return (_listeners);
		}//get listeners
		
		/**
		 * Returns true if the dispatcher object and sourceFilter(s) match. If sourceFilter is an array,
		 * it is assumed that it contains indexed references to check against (if any one matches,
		 * this method returns true).
		 * 
		 * @private
		 */
		private static function sourcesMatch(dispatcher:*, sourceFilter:*):Boolean {
			if (sourceFilter==null) {
				return (true);
			}//if
			if ((dispatcher==null) && (sourceFilter!=null)){
				return (false);
			}//if
			if (sourceFilter is Array) {
				for (var item:* in sourceFilter) {
					if (sourceFilter[item]==dispatcher) {
						return (true);
					}//if
				}//for
			} else {
				if (sourceFilter==dispatcher) {
					return (true);
				}//if
			}//else
			return (false);
		}//sourceMatch
		
	}//SwagDispatcher class

}//package