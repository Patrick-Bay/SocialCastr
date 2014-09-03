package swag.effects {
	
	import swag.interfaces.effects.ISwagTween;
	import swag.core.SwagSystem;	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.None;	

	/**
	 * @private
	 * 
	 * Similar to the standard Flash Tween class but with a variety of additional options and enhancements over the original
	 * animation system.
	 * <p>Use the <code>SwagTween</code> class in the same way as you would a standard Tween instance. Be aware, however, that <code>SwagTween</code>
	 * broadcasts slightly different events and also supports additional properties and methods.</p>
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
	public class SwagTween implements ISwagTween {		
		
		/**
		 * Array of tween objects including references to individual Tween instances, tween properties, and other information
		 * controlled by <code>SwagTween</code>.
		 * @private 
		 */
		private var _tweens:Array;
		
		/**
		 * Default constructor for the <code>SwagTween</code> class.
		 * <p>The class constructor's parameter list is almost identical to a standard Flash <code>Tween</code> instance with the exception of
		 * an additional <code>props</code> paramater which provides support for <code>SwagTween</code>'s extended features.</p>
		 * 
		 * @param obj The object on which to perform the tween (within which the <code>props</code> property / properties reside.
		 * @param props The property or properties to update with the tween. If applying the tween to multiple properties, they must be 
		 * separated by a comma. All properties will be tweened with the same values. Note that this differs from the standard <code>Tween</code> 
		 * instance which only supports one property).
		 * @param func The tweening function (for example, one of the <code>fl.transitions.easing.&#42;</code> classes) to use with the tween. The parameter
		 * may either be a direct reference to the easing class, as in a standard <code>Tween</code> instance, or it may be a string in which case
		 * <code>SwagTween</code> will attempt to retrieve a reference to the class from Flash memory. If none can be found, an error will be dispatched and
		 * no tween will take place.
		 * @param begin The starting value(s) for the tweenable properties. If this value is numeric, it is assumed to apply to all the properies listed in the
		 * <code>props</code> parameter. If it's a string or an array it's assumed to contain a list of values to apply to the properties listed in the 
		 * <code>props</code> parameter in the order in which they appear (values in a string must be comma separated). If the number of values exceeds the 
		 * number of properties, any remaining values are ignored. If the number of values is less than the associated properties, the last value in the list 
		 * is used with the remaining properties. If no value is provided (e.g. <em>null</em>), or the value is of a type that can't be used (e.g. not a 
		 * <code>String</code>, <code>Array</code>, or a numeric type), an error will be dispatched and no tween will take place.
		 * @param finish The ending value(s) for the tweenable properties. If this value is numeric, it is assumed to apply to all the properies listed in the
		 * <code>props</code> parameter. If it's a string or an array it's assumed to contain a list of values to apply to the properties listed in the "props"
		 * parameter in the order in which they appear (values in a string must be comma separated). If the number of values exceeds the number of properties, 
		 * any remaining values are ignored. If the number of values is less than the associated properties, the last value in the list is used with the 
		 * remaining properties. If no value is provided (e.g. <em>null</em>), or the value is of a type that can't be used (e.g. not a <code>String</code>, 
		 * <code>Array</code>, or a numeric type), an error will be dispatched and no tween will take place.
		 * @param duration The duration(s) to apply to the associated tween. If this is a numeric value it's assumed to apply to all of the supplied properties.
		 * If this value is a comma-separated list or an array of values, they are applied in the order in which they appear. If the number of values
		 * exceed the number of properties, the remaining values are ignored. If the number of properties exceeds the number of <code>duration</code> values,
		 * the last value in the list will be applied to remaining properties. If no value is provided (e.g. <em>null</em>), or the value is of a type that 
		 * can't be used (e.g. not a <code>String</code>, <code>Array</code>, or a numeric type), an error will be dispatched and no tween will take place.
		 * @param useSeconds If <em>true</em>, the value(s) specified in the <code>duration</code> property is / are in seconds. If <em>false</em>, the
		 * value(s) are in frames.
		 * @param extras Additional optional properties to include with the tween. These include:
		 * <ul>
		 * <li>delay (<code>Number</code>) - The delay(s), in the units specified by the <code>useSeconds</code> parameter, to hold the tween before
		 * starting it. If this value is numeric it applies to all the tweenable properties. If this is a <code>String</code> or <code>Array</code>,
		 * this property is assumed to hold a list of delays in the same order as the tweenable properties. If there are more delay values than tweenable
		 * properties, remaining delays are ignored. If there are more properties than delays, the last delay in the list applies to all outstanding properties.
		 * </li>
		 * </ul>
		 * 
		 * @see fl.transitions.Tween()
		 * 
		 */
		public function SwagTween(obj:Object, props:String, func:*, begin:*, finish:*, duration:*, useSeconds:Boolean = false, extras:Object=null) {
			if (obj==null) {
				return;
			}//if			
		}//constructor
		
	}//SwagTween class
	
}//package