package swag.core.instances {
	
	import swag.core.SwagDataTools;
	import swag.events.SwagEvent;
	import swag.interfaces.core.instances.ISwagEventListener;
	import swag.interfaces.events.ISwagEvent;	
	import flash.utils.getQualifiedSuperclassName;
	import flash.utils.getQualifiedClassName;
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
	public final class SwagEventListener	{
		
		/**
		 * @private 
		 */		
		private var _eventType:String=null;
		/**
		 * @private 
		 */
		private var _eventMethod:Function=null;
		/**
		 * @private 
		 */
		private var _methodParameters:Array=null;
		/**
		 * @private 
		 */
		private var _sourceObject:*=null;
		/**
		 * @private 
		 */
		private var _sourceContainer:*=null;
		
		/**
		 * Default constructor for the <code>SwagEventListener</code> class. 
		 * 
		 * @param eventType The type of event to create a listener for. While this may be a standard string, it's advisable to use 
		 * one of the defined <code>SwagEvent</code> constant strings in order to easily propagate changes throughout an application should
		 * the event string constants ever change.
		 * @param eventMethod The method to assign to the listener (i.e. the method to invoke when the matching event is dispatched).
		 * @param thisRef A reference to the object (class, instance, etc.), that contains the <code>eventMethod</code>. If valid, the
		 * event dispatch will try to intelligently invoke methods that are not correctly formatted (e.g. don't have a <code>SwagEvent</code>-
		 * type object as the first parameter). If ommitted, or <em>null</em>, the listening method <strong>must</strong> be properly
		 * formatted or the event invokation will result in a runtime error. 
		 * @param sourceObject The object(s) from which the dispatched event is/are allowed. This may either be a singular object reference
		 * or an array of objects. If this value is <em>null</em>, all events of <code>eventType</code> will be considered a match.
		 * 
		 * @see swag.core.SwagDispatcher
		 */
		public function SwagEventListener(eventType:String=null, eventMethod:Function=null, thisRef:*=null, sourceObject:*=null)	{
			this.type=eventType;
			this._sourceContainer=thisRef;
			this.method=eventMethod;
			this.source=sourceObject;			
		}//constructor
		
		/**
		 * The event type string associated with the listener.
		 * <p>This value may also be set within the class constructor.</p>
		 *  
		 * @param typeSet The event type associated with this event. It's advisable to use one of the defined <code>SwagEvent</code> 
		 * (or derived), event constants rather than a basic string for easy maintainability and future compatibility.
		 * 
		 */
		public function set type(typeSet:String):void {
			this._eventType=typeSet;
		}//set type
		
		/**
		 * @private
		 * 
		 */		
		public function get type():String {
			return (this._eventType);
		}//get type
		
		/**
		 * The method to invoke when a matching event is dispatched.
		 *  
		 * @param methodSet The method to associate with the event (the method to invoke when the matching event is dispatched).
		 * 
		 */
		public function set method(methodSet:Function):void {
			this._eventMethod=methodSet;
			if (this._sourceContainer!=null) {
				this._methodParameters=SwagDataTools.getMethodParameters(this._eventMethod, this._sourceContainer);
			}//if
		}//set eventMethod
		
		/**
		 * @private
		 */
		public function get method():Function {
			return (this._eventMethod);
		}//get eventMethod
		
		/**
		 * The source object(s) for the listener.
		 * <p>The listener is only invoked if the source is <em>null</em>, or if the source matches the dispatching object(s). 
		 * This value may either be a singular object reference or an array of object references.</p>
		 *  
		 * @param sourceSet The source object(s) associated with the listener, or <em>null</em> to associate with all events
		 * that match the event <code>type</code>.
		 * 
		 */
		public function set source(sourceSet:*):void {
			this._sourceObject=sourceSet;
		}//set source
		
		/**
		 * @private 
		 */
		public function get source():* {
			return (this._sourceObject);
		}//get source
		
		/**
		 * @private
		 */
		private function get sourceContainer():* {
			return (this._sourceContainer);
		}//get sourceContainer
		
		/**
		 * @private
		 */
		private function get methodParameters():Array {
			return (this._methodParameters);
		}//get methodParameters
		
		/**
		 * @private
		 */
		private function get methodParameterInstances():Array {
			if (this.methodParameters==null) {
				return (null);
			}//if
			if (this.methodParameters.length==0) {
				return (new Array());
			}//if
			var returnArray:Array=new Array();
			for (var count:uint=0; count<this.methodParameters.length; count++) {
				var currentParameterType:Class=this.methodParameters[count] as Class;
				if (currentParameterType==null) {
					returnArray.push(null);	
				} else {					
					returnArray.push(new currentParameterType());				
				}//else
			}//for
			return (returnArray);
		}//get methodParameterInstances
		
		/**
		 * Invokes the event by calling the associated <code>method</code>.
		 *  
		 * @param event The event (implementation of <code>ISwagEvent</code>), to dispatch.
		 * @param source A reference to the source object invoking this event. 
		 * @return <em>True</em> if the event was successfully dispatched, <em>false</em> if there was an error (for example,
		 * no <code>method</code> was defined for the listener).
		 * 
		 * @see swag.interfaces.events.ISwagEvent
		 */
		public function invoke(event:ISwagEvent, source:*):Boolean {			
			if (this.method==null) {
				return (false);
			}//if			
			event.source=source;			
			if (this.methodParameters==null) {					
				try {
					this.method(event);
					return (true);
				} catch (e:ArgumentError) {
					trace (e);	
					trace ("Solutions:");
					trace ("   1. Update the listening method to include only a SwagEvent-type object as its first parameter.");
					trace ("   2. Include a reference to the method's containing object (usually \"this\"), in the third parameter ");
					trace ("(\"thisRef\"), when calling the SwagDispatcher.addEventListener() method.");
					trace ("   3. Ensure that the listening method is declared as public (private method parameters can't be detected).");
					return (false);
				}//catch
			}//if
			if (this.methodParameters.length==0) {				
				try {
					this.method();
					return (true);
				} catch (e:ArgumentError) {
					trace (e);	
					trace ("Solutions:");
					trace ("   1. Update the listening method to include only a SwagEvent-type object as its first parameter.");
					trace ("   2. Include a reference to the method's containing object (usually \"this\"), in the third parameter ");
					trace ("(\"thisRef\"), when calling the SwagDispatcher.addEventListener() method.");
					trace ("   3. Ensure that the listening method is declared as public (private method parameters can't be detected).");
					return (false);
				}//catch
			}//if
			if ((this.methodParameters[0] is ISwagEvent) || (this.methodParameters[0] is SwagEvent) 
				||(getQualifiedSuperclassName(event) == getQualifiedClassName(SwagEvent)) ) {				
				try {					
					this.method(event);
					return (true);
				} catch (e:ArgumentError) {
					trace (e);	
					trace ("Solutions:");
					trace ("   1. Update the listening method to include only a SwagEvent-type object as its first parameter.");
					trace ("   2. Include a reference to the method's containing object (usually \"this\"), in the third parameter ");
					trace ("(\"thisRef\"), when calling the SwagDispatcher.addEventListener() method.");
					trace ("   3. Ensure that the listening method is declared as public (private method parameters can't be detected).");
					return (false);
				}//catch
			} else {				
				if (this.sourceContainer!=null) {
					try {						
						this.method.apply(this.sourceContainer, this.methodParameterInstances);
						return (true);
					} catch (e:ArgumentError) {
						trace (e);	
						trace ("Solution:");
						trace ("   Ensure that the third parameter of the SwagDispatcher.addEventListener() method is a valid ");
                        trace ("reference to the object containing the listening method.");						
						return (false);
					}//catch
				} else {
					try {	
						trace ("Now sending event with source ref="+event.source);
						this.method(event);
						return (true);
					} catch (e:ArgumentError) {
						trace (e);	
						trace ("Solutions:");
						trace ("   1. Update the listening method to include only a SwagEvent-type object as its first parameter.");
						trace ("   2. Include a reference to the method's containing object (usually \"this\"), in the third parameter ");
						trace ("(\"thisRef\"), when calling the SwagDispatcher.addEventListener() method.");
						trace ("   3. Ensure that the listening method is declared as public (private method parameters can't be detected).");
						return (false);
					}//catch
				}//else
			}//else
			return (false);
		}//invoke
				
		
	}//SwagEventListener class
	
}//package