package socialcastr.core {
	
	import flash.utils.ByteArray;
	
	import socialcastr.interfaces.core.ISCID;
	
	import swag.core.SwagDataTools;
	
	/**
	 * Generates SocialCastr IDs from hexadecimal peer ID strings.
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
	public class SCID implements ISCID {
		
		/**
		 * Generates a valid SCID from a supplied hexadecimal-encoded peer ID.
		 *  
		 * @param peerID The hexadecimal peer ID string to convert. This string must always be evenly
		 * divisible by 2 (each hex value has two bytes), and each hex value must be within the valid hexadecimal
		 * range for a byte (00 to FF).
		 * 
		 * @return The encoded SCID, or <em>null</em> if there was an error parsing the input peer ID. 
		 * 
		 */
		public static function generate(peerID:String):String {
			if ((peerID==null) || (peerID=="")) {
				return (null);
			}//if
			var returnSCID:String=new String();
			var peerIDString:String=new String(peerID);
			peerIDString=SwagDataTools.stripChars(peerIDString, SwagDataTools.SEPARATOR_RANGE+SwagDataTools.PUNCTUATION_RANGE);
			if (peerIDString=="") {
				return (null);
			}//if
			var IDLength:Number=peerIDString.length/2;
			//Not evenly divisible by 2
			if (Math.abs(IDLength) != IDLength) {				
				return (null);
			}//if
			var decValues:ByteArray=SwagDataTools.fromHexString(peerIDString, ByteArray);
			var SEK:uint=decValues[0] as uint;			
			var KEK:uint=decValues[decValues.length-1] as uint;
			appendDateTimeStamp(decValues);
			//Encode the SEK...
			var currentValue:uint=SEK ^ KEK ^ 0xAA;			
			currentValue%=26;			
			currentValue+=65;			
			returnSCID=String.fromCharCode(currentValue);
			//Encode the remainder of the string to specification, apply modulo, and convert to ASCII.
			for (var count:uint=1; count<decValues.length; count++) {
				currentValue=decValues[count] as uint;				
				currentValue^=SEK;				
				currentValue%=26;				
				currentValue+=65;				
				returnSCID+=String.fromCharCode(currentValue);
			}//for
			return (returnSCID);
		}//generate
		
		/**
		 * @private 		 		 
		 */
		private static function appendDateTimeStamp(decPID:ByteArray):void {
			if (decPID==null) {
				return;
			}//if
			var dateObj:Date=new Date();
			decPID.writeUnsignedInt(uint(dateObj.hours));			
			decPID.writeUnsignedInt(uint(dateObj.minutes));			
			decPID.writeUnsignedInt(uint(dateObj.seconds));			
			decPID.writeUnsignedInt(uint(dateObj.milliseconds));			
			decPID.writeUnsignedInt(uint(dateObj.date));			
			decPID.writeUnsignedInt(uint(dateObj.month));			
			decPID.writeUnsignedInt(uint(dateObj.fullYear));				
		}//appendDateTimeStamp
		
	}//SCID class
	
}//package