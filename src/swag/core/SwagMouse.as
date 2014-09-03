package swag.core {
		
	import flash.display.InteractiveObject;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	
	import swag.events.SwagMouseEvent;
	import swag.interfaces.core.ISwagMouse;
	
	/**
	 * Provides extended functionality and properties related to the mouse.
	 * <p>This is similar to standard Flash mouse event handlers, but the <code>SwagMouse</code> class includes more features
	 * and shortcuts.</p>
	 * <p>Most events associated with this instance are passed through to the requesting object as is. The <code>SwagMouse</code>
	 * instance can, however, also be inspected when various properties are required, and will also pass along
	 * extra information whenever available.</p>
	 * <p>Unlike traditional Flash mouse events, listeners are associated with <code>SwagMouse</code> instances rather than
	 * the dispatching <code>InteractiveObject</code>s themselves. This allows the <code>SwagMouse</code> class to inspect the mouse 
	 * events and provide additional information before handing the events on to your class. However, if this extended functionality is 
	 * not required, standard Flash mouse events are recommended as <code>SwagMouse</code> will add some processing overhead.</p>
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
	public class SwagMouse implements ISwagMouse {
		
		/**
		 * @private 
		 */
		private var _targetObject:InteractiveObject=null;
		
		/**
		 * Default constructor for the class instance.
		 *  
		 * @param targetObject The <code>InteractiveObject</code> object to associate with this mouse handler instance.
		 * 
		 */
		public function SwagMouse(targetObject:InteractiveObject)	{
			this._targetObject=targetObject;			
		}//constructor
		
		/**
		 * Associates an event listening method with the <code>SwagMouseEvent.CLICK</code> event.
		 * <p>The associated method is treated as a standard <code>SwagEvent</code> event listener and
		 * so should have a <code>SwagMouseEvent</code> parameter as its first parameter.</p>
		 * <p>Like standard event listeners, multiple listeners may be registered for the same event, on
		 * the same object, and in the same class, so use with caution.</p>
		 * 
		 * @param methodRef The method to invoke whenever a <code>SwagMouseEvent.CLICK</code> event is
		 * disatched.
		 * 
		 */
		public function onClick(methodRef:Function):void {
			if (this._targetObject==null) {
				//dispatch error
			}//if
			this._targetObject.addEventListener(MouseEvent.CLICK, this.onClickHandler);
		}//onClick
		
		/**
		 * @private 		 		 
		 */
		private function onClickHandler(eventObj:MouseEvent):void {
			var event:SwagMouseEvent=new SwagMouseEvent(SwagMouseEvent.CLICK);
			event.source=this._targetObject;			
		}//onClickHandler
		
		/**
		 * The target <code>InteractiveObject</code> instance associated with this class.		 
		 */
		public function get target():InteractiveObject {
			return (this._targetObject);
		}//get target
		
	}//SwagMouse class
	
}//package