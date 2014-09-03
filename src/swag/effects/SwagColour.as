package swag.effects {
	
	import flash.display.DisplayObject;
	import flash.geom.ColorTransform;
	import flash.geom.Transform;
	
	import swag.interfaces.effects.ISwagColour;
	/**
	 * Provides methods and properties for adjusting and applying various colour effects and transforms to display objects.
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
	public class SwagColour implements ISwagColour	{
		
		private var _red:uint=new uint();
		private var _green:uint=new uint();
		private var _blue:uint=new uint();
				
		/**
		 * Default constructor for the class. 
		 * 
		 */
		public function SwagColour(rgbValue:uint=0) {
			this.RGB=rgbValue;
		}//constructor
		
		/**
		 * Applies a tint to the specified <code>DisplayObject</code> using the colour values of this <code>SwagColour</code>
		 * instance.		 
		 * 
		 * @param targetObject The <code>DisplayObject</code> to tint.
		 * 
		 */
		public function applyTint(targetObject:DisplayObject=null):void {
			if (targetObject==null) {
				return;
			}//if
			var tintTransform:ColorTransform=new ColorTransform(1,1,1,1,0,0,0,0);
			tintTransform.redOffset=Number(this.red);
			tintTransform.greenOffset=Number(this.green);
			tintTransform.blueOffset=Number(this.blue);
			targetObject.transform.colorTransform=tintTransform;
		}//applyTint
		
		/**
		 * The red component of the SwagColour instance.
		 * <p>This 8-bit value may be set as an <code>int</code>, <code>uint</code>, <code>Number</code>, or <code>String</code>, 
		 * and is returned as an <code>uint</code>.</p>
		 * <p>Any negative value assigned to this property will be made absolute first, a floating-point value will be floored,
		 * and the result will be ANDed with 255 (0xFF) to strip off any bits above the 8th. As a result, this property may have
		 * a different value from that assigned to it.</p>		 		 
		 */
		public function set red(redSet:*):void {
			if ((redSet is uint) || (redSet is int)) {				
				this._red=uint(Math.abs(redSet));
			} else if (redSet is Number) {				
				this._red=uint(Math.abs(Math.floor(redSet)));
			} else if (redSet is String) {				
				this._red=uint(Math.abs(Math.floor(Number(redSet))));
			}//else if			
			this._red=this._red & 0xFF;			
		}//set red
		
		public function get red():uint {
			return (this._red);
		}//get red
		
		/**
		 * The green component of the SwagColour instance.
		 * <p>This 8-bit value may be set as an <code>int</code>, <code>uint</code>, <code>Number</code>, or <code>String</code>, 
		 * and is returned as an <code>uint</code>.</p>
		 * <p>Any negative value assigned to this property will be made absolute first, a floating-point value will be floored,
		 * and the result will be ANDed with 255 (0xFF) to strip off any bits above the 8th. As a result, this property may have
		 * a different value from that assigned to it.</p>		 		 
		 */
		public function set green(greenSet:*):void {
			if ((greenSet is uint) || (greenSet is int)) {				
				this._green=uint(Math.abs(greenSet));
			} else if (greenSet is Number) {				
				this._green=uint(Math.abs(Math.floor(greenSet)));
			} else if (greenSet is String) {				
				this._green=uint(Math.abs(Math.floor(Number(greenSet))));
			}//else if	
			this._green=this._green & 0xFF;
		}//set green
		
		public function get green():uint {
			return (this._green);
		}//get green
		
		/**
		 * The blue component of the SwagColour instance.
		 * <p>This 8-bit value may be set as an <code>int</code>, <code>uint</code>, <code>Number</code>, or <code>String</code>, 
		 * and is returned as an <code>uint</code>.</p>
		 * <p>Any negative value assigned to this property will be made absolute first, a floating-point value will be floored,
		 * and the result will be ANDed with 255 (0xFF) to strip off any bits above the 8th. As a result, this property may have
		 * a different value from that assigned to it.</p>		 		 
		 */
		public function set blue(blueSet:*):void {
			if ((blueSet is uint) || (blueSet is int)) {				
				this._blue=uint(Math.abs(blueSet));
			} else if (blueSet is Number) {				
				this._blue=uint(Math.abs(Math.floor(blueSet)));
			} else if (blueSet is String) {				
				this._blue=uint(Math.abs(Math.floor(Number(blueSet))));
			}//else if	
			this._blue=this._blue & 0xFF;
		}//set blue
		
		public function get blue():uint {
			return (this._blue);
		}//get blue
		
		/**
		 * The combined red, green, and blue (RGB) components of this <code>SwagColour</code> instance.
		 * <p>This value may be used wherever a 24-bit colour value is expected.</p>
		 * <p>Setting this value updates the <code>red</code>, <code>green</code>, and <code>blue</code> components
		 * of the class.</p>		 
		 */
		public function set RGB(RGBSet:uint):void {
			this.red=(RGBSet >>> 16) & 0xFF;
			this.green=(RGBSet >>> 8) & 0xFF;
			this.blue=RGBSet & 0xFF;
		}//set RGB
				
		
		public function get RGB():uint {
			var returnRGB:uint=new uint();
			returnRGB=(this._red << 16) | (this._green << 8) | this._blue;
			return (returnRGB);
		}//get RGB
		
	}//SwagColour class
	
}//package