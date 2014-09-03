package swag.core.instances {
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * Discovers accessible properties in a specified target object. Useful when attempting to find properties (variables / method / etc.),
	 * that are available on a class but may not be visible or publicized.
	 * <p>This class will run through all valid ActionScript combinations and attempt to apply them to the object.
	 * If any are found, they are recorded.</p>
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
	public class SwagDiscovery	{
		
		
		public var onDiscover:Function=null;
		
		private static const validChars:String=new String("$_~1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");
		
		private var _validCharsArray:Array=new Array();
		private var _targetObject:*=null;
		private var _currentCombination:String=new String();
		private var _stringPosition:int=0;
		private var _maxLength:uint=64;
		private var _discoveryTimer:Timer;
		
		public function SwagDiscovery(targetObj:*, startingCombination:String="", maxLength:uint=64)	{
			this._currentCombination=startingCombination;
			this._targetObject=targetObj;
			this._maxLength=maxLength;
			this.startDiscovery();
		}//constructor
		
		private function startDiscovery():void {
			if (this._targetObject==null) {
				return;
			}//if
			this._validCharsArray=validChars.split("");
			this._discoveryTimer=new Timer(1, 0);
			this._discoveryTimer.addEventListener(TimerEvent.TIMER, this.onTimerTick);
			this._discoveryTimer.start();
		}//startDiscovery
		
		private function onTimerTick(eventObj:TimerEvent):void {
			this.updateDiscoveryString()
		}//onTimerTick
		
		private function updateDiscoveryString():void {		
			if (this._currentCombination=="") {
				this._currentCombination=String(this._validCharsArray[0]);				
				return;
			} else {
				this.updateCharAt(this._currentCombination.length-1);								
			}//else
		}//updateDiscoveryString
		
		private function stopDiscovery():void {
			this._discoveryTimer.stop();
			this._discoveryTimer.removeEventListener(TimerEvent.TIMER, this.onTimerTick);
			this._discoveryTimer=null;
		}//stopDiscovery
		
		private function updateCharAt(charPosition:int):* {
			if (charPosition==0) {
				trace ("Combination rolling over upper limit with \""+this._currentCombination+"\"");
			}//if
			if (charPosition<0) {				
				this._currentCombination=(this._validCharsArray[0] as String)+this._currentCombination;
				return;
			}//if			
			var currentChar:String=this._currentCombination.substr(charPosition, 1);
			var index:int=this.findCharIndex(currentChar);			
			if (index==(this._validCharsArray.length-1)) {	
				if (this._currentCombination.length==this._maxLength) {
					this.stopDiscovery();
					return;
				}//if		
				trace ("Character rolling over upper limit with \""+this._currentCombination+"\"");
				this.updateCharAt(charPosition-1);
				var newChar:String=this._validCharsArray[0];				
			} else {
				newChar=this._validCharsArray[index+1];
			}//else
			var replaceArray:Array=this._currentCombination.split("");
			replaceArray[charPosition]=newChar;				
			this._currentCombination=replaceArray.join("");	
			try {
				if (this._targetObject[this._currentCombination]!=undefined) {
					if (this.onDiscover!=null) {
						this.onDiscover(this._currentCombination);
					}//if					
					trace ("Discovered property on "+this._targetObject+": \""+this._currentCombination+"\"");
				}//if
			} catch (e:*) {				
			}//catch
		}//updateharAt
			
		private function findCharIndex(char:String):int {			
			for (var count:int=0; count<this._validCharsArray.length; count++) {
				var currentChar:String=this._validCharsArray[count] as String;
				if (currentChar==char) {
					return (count);
				}//if
			}//for
			return (0);
		}//findCharIndex				
		
	}//SwagDiscovery class
	
}//package