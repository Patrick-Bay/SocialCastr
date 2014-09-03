package swag.core {	
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.PixelSnapping;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	import swag.core.SwagDispatcher;
	import swag.interfaces.core.ISwagDataTools;
	
	/**
	 * The <code>SwagDataTools</code> class contains a variety of static methods and properties to assist with a variety
	 * of data modification and verification tasks. For the most part, methods and properties can be accessed directly
	 * without first creating an instance of the <code>SwagDataTools</code> class. 
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
	public final class SwagDataTools extends SwagDispatcher implements ISwagDataTools {
		
		/**
		 * Contains the range of all numeric ASCII characters that can be used with various string operations. 
		 */		
		public static const NUMBERS_RANGE:String="0123456789";
		/**
		 * Contains the range of all lowercase ASCII characters that can be used with various string operations. 
		 */		
		public static const LOWERCASE_RANGE:String="abcdefghijklmnopqrstuvwxyz";
		/**
		 * Contains the range of all uppercase ASCII characters that can be used with various string operations. 
		 */		
		public static const UPPERCASE_RANGE:String="ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		/**
		 * Contains the range of all puncuation ASCII characters that can be used with various string operations. 
		 */		
		public static const PUNCTUATION_RANGE:String="~`!@#$%^&*()+-={}[]|:\";'<>,.?";
		
		/**
		 * Contains the range of all separator ASCII characters (space, hyphen, underscore, back slash, forward slash), 
		 * that can be used with various string operations. 
		 */
		public static const SEPARATOR_RANGE:String=" -_\\/\n\r\t";
		/**
		 * Contains the range of all white space ASCII characters (spaces, tabs, newlines, carriage returns), 
		 * that can be used with various string operations. 
		 */
		public static const WHITESPACE_RANGE:String=" \n\r\t";
		
		/**
		 * 
		 * Verifies the supplied <code>property</code> against the supplied <code>type</code>.
		 * 
		 * @param property The property (variable, object, reference, etc.), to check.
		 * @param type The type to check against. If this is an object reference, it is used directly. If this is a string,
		 * a <code>getDefinitionByType</code> call is made to attempt to retrieve the object type first.
		 * @param canBeNull If <em>true</em>, the evaluation will still return <code>true</code> even if the 
		 * supplied <code>property</code> is null. If <em>false</em>, the <code>property</code> must contain a value (i.e. be non-null). 
		 * 
		 * @return <em>true</em> if the supplied <code>property</code> parameter matches the supplied <code>type</code>
		 * parameter, or <em>false</em> if the type doesn't match, or the <code>property</code> is null and <code>canBeNull</code> 
		 * is false.
		 * 
		 */
		public static function isType(property:*=null, type:*=null, canBeNull:Boolean=false):Boolean {
			if ((property==null) && (canBeNull==false)) {
				return (false)
			}//if
			if ((type==null) && (property==null)) {
				return (true);
			}//if
			if (type==String) {
				try {
					var typeClass:Class=getDefinitionByName(type) as Class;
					if (property==typeClass) {
						return (true);
					}//if
				} catch (e:ReferenceError) {
					return (false);
				}//catch
			} else {
				if (property==type) {
					return (true);
				}//if
			}//else
			return (false);
		}//isType
		
		/**
		 * Verifies that the supplied property has data -- is not <em>undefined</em> and not <em>null</em>.
		 *  
		 * @param args The property to check.
		 * 
		 * @return <em>True</em> if the supplied <code>property</code> is not <em>undefined</em> and not <em>null</em>, otherwise
		 * <em>false</em> is returned.
		 * 
		 */
		public static function hasData(... args):Boolean {			
			if (args[0]==undefined) {
				return (false);
			}//if
			if (args[0]==null) {
				return (false);
			}//if
			return (true);
		}//hasData
		
		/**
		 * Verifies that the supplied parameter is one of the valid ActionScript 3 XML objects, or a string that can be converted to a valid XML
		 * object.
		 *  
		 * @param args The first parameter is the argument to validate as either <code>XML</code>, <code>XMLList</code>, <code>XMLDocument</code>, 
		 * <code>XMLNode</code>, or a string with valid XML data if the optional second parameter is <em>true</em> (default is <em>false</em>).
		 * 
		 * @return <em>True</em> if the supplied argument is a valid <code>XML</code>, <code>XMLList</code>, <code>XMLDocument</code>, or 
		 * <code>XMLNode</code> object, or if it's a string that can be converted used as a valid XML object (if the second parameter is <em>true</em>). 
		 * <em>False</em> is returned when none of these conditions are met. 
		 * 
		 */
		public static function isXML(... args):Boolean {
			if (args == null) {				
				return (false);
			}//if
			if (args[0] == undefined) {				
				return (false);
			}//if
			if ((args[0]==String) && (args[1]==true)){
				var localString:String=new String(args[0]);
				try {					
					var testXML:XML=new XML(localString);
					return (true);
				} catch (e:TypeError) {					
					return (false);
				}//catch				
			}//if
			if ((args[0] is XML) || (args[0] is XMLList) || (args[0] is XMLDocument) || (args[0] is XMLNode)) {				
				return (true);
			}//if			
			return (false);
		}//isXML
		
		/**
		 * 
		 * Scans <code>sourceString</code> for occurances of <code>searchString</code> and returns true if found.
		 * <p>Optionally, a case-insensitive search may be performed between the two strings.</p>
		 *  
		 * @param sourceString The string, or strings, to search through. If this parameter is a string, it is used as is. If the parameter is an
		 * array, the contents of the array are analyzed one by one wherever possible. If the parameter is of a type that can be converted to a string
		 * (XML, for example), a conversion will be attempted.
		 * @param searchString The string to find within <code>sourceString</code>.
		 * @param caseSensitive If <em>true</em>, a case-insensitive search is performed, otherwise the strings must match exactly.
		 * 
		 * @return True if the <code>searchString</code> could be found within the <code>sourceString</code>. <em>False</em> is returned if
		 * <code>sourceString</code> or <code>searchString</code> are <em>null</em>, or are of a type that can't be analyzed.		 
		 * 
		 */
		public static function stringContains(sourceString:*, searchString:String, caseSensitive:Boolean=true):Boolean {
			if ((sourceString==null) || (searchString==null)) {
				return (false);
			}//if			
			if (sourceString is String) {
				var localSourceString:String=new String(sourceString);
				var localSearchString:String=new String(searchString);
				if (!caseSensitive) {
					localSourceString=localSourceString.toLowerCase();
					localSearchString=localSearchString.toLowerCase();
				}//if
				if (localSourceString.indexOf(localSearchString)>-1) {
					return (true);
				} else {
					return (false);
				}//else
			} else if (sourceString is Array) {
				localSearchString=new String(searchString);
				if (!caseSensitive) {					
					localSearchString=localSearchString.toLowerCase();
				}//if
				for (var count:uint=0; count<sourceString.length; count++) {
					localSourceString=new String(sourceString[count] as String);
					if (!caseSensitive) {
						localSourceString=localSourceString.toLowerCase();						
					}//if
					if (localSourceString.indexOf(localSearchString)>-1) {
						return (true);
					} else {
						return (false);
					}//else
				}//for
			} else if ((sourceString==XML) || (sourceString==XMLNode)) {
				localSourceString=new String(sourceString.toString());
				localSearchString=new String(searchString);
				if (!caseSensitive) {
					localSourceString=localSourceString.toLowerCase();
					localSearchString=localSearchString.toLowerCase();
				}//if
				if (localSourceString.indexOf(localSearchString)>-1) {
					return (true);
				} else {
					return (false);
				}//else
			} else {
				return (false);
			}//else
			return (false);
		}//stringContains
		
		/**
		 * Strips the leading characters from an input string and returns the newly reformatted string. As soon as a non-stripped
		 * character is encountered, the remainder of the string is left intact.
		 *  
		 * @param inputString The string from which to strip the leading characters. The contents of this parameter are copied
		 * so the original data is not affected.
		 * @param stripChars The character or characters to strip from <code>inputString</code>. Multiple characters may be included
		 * as a string or, alternately, this parameter may be an array of strings.
		 * 
		 * @return A newly created copy of <code>inputString</code> with all the specified characters stripped out.
		 * 
		 * @example The following example strips all punctuation from the beginning of the given input string:
		 * <listing version="3.0">
		 * var sourceString:String = "$-=This should not have puncutation at the beginning.";
		 * var strippedString:String = SwagDataTools.stripLeadingChars(sourceString, SwagDataTools.PUNCTUATION_RANGE);
		 * trace (strippedString); //"This should not have puncutation at the beginning."
		 * </listing>
		 * 
		 */
		public static function stripLeadingChars(inputString:String, stripChars:*=" "):String {
			if (inputString==null) {
				return(new String());
			}//if
			if ((inputString=="") || (inputString.length==0)) {
				return(new String());
			}//if
			if (stripChars==null) {
				return (inputString);
			}//if
			var localStripChars:String=new String();
			if (stripChars==Array) {
				for (var count:uint=0; count<stripChars.length; count++) {
					localStripChars.concat(String(stripChars[count] as String));
				}//for	
			} else if (stripChars==String) {
				localStripChars=new String(stripChars);
			} else {
				return (inputString);
			}//else
			if ((localStripChars=="") || (localStripChars.length==0)) {
				return (inputString);
			}//if
			var localInputString:String=new String(inputString);
			var returnString:String=new String();
			var leadStripped:Boolean=false;
			for (var charCount:Number=0; charCount<localInputString.length; charCount++) {
				var currentChar:String=localInputString.charAt(charCount);				
				if ((localStripChars.indexOf(currentChar)<0) || (leadStripped)) {					
					returnString=returnString.concat(currentChar);	
					leadStripped=true;
				}//if
			}//for
			return (returnString);
		}//stripLeadingChars
		
		/**
		 * Strips the trailing (end) characters from an input string and returns the newly reformatted string. As soon as a non-stripped
		 * character is encountered, the remainder of the string is left intact.
		 *  
		 * @param inputString The string from which to strip the trailing characters. The contents of this parameter are copied
		 * so the original data is not affected.
		 * @param stripChars The character or characters to strip from <code>inputString</code>. Multiple characters may be included
		 * as a string or, alternately, this parameter may be an array of strings.
		 * 
		 * @return A newly created copy of <code>inputString</code> with all the specified characters stripped out.
		 * 
		 * @example The following example strips all lowercase letters and separators from the end of the given input string:
		 * <listing version="3.0">
		 * var sourceString:String = "IF YOU'RE NOT SHOUTING you will not be heard";
		 * var strippedString:String = SwagDataTools.stripTrailingChars(sourceString, SwagDataTools.LOWERCASE_RANGE + SwagDataTools.SEPARATOR_RANGE);
		 * trace (strippedString); //"IF YOU'RE NOT SHOUTING"
		 * </listing>
		 * 
		 */
		public static function stripTrailingChars(inputString:String, stripChars:*=" "):String {
			if (inputString==null) {
				return(new String());
			}//if
			if ((inputString=="") || (inputString.length==0)) {
				return(new String());
			}//if
			if (stripChars==null) {
				return (inputString);
			}//if
			var localStripChars:String=new String();
			if (stripChars==Array) {
				for (var count:uint=0; count<stripChars.length; count++) {
					localStripChars.concat(String(stripChars[count] as String));
				}//for	
			} else if (stripChars==String) {
				localStripChars=new String(stripChars);
			} else {
				return (inputString);
			}//else
			if ((localStripChars=="") || (localStripChars.length==0)) {
				return (inputString);
			}//if
			var localInputString:String=new String(inputString);
			var returnString:String=new String();
			var trailStripped:Boolean=false;
			for (var charCount:Number=(localInputString.length-1); charCount>=0; charCount--) {
				var currentChar:String=localInputString.charAt(charCount);
				if ((localStripChars.indexOf(currentChar)<0) || (trailStripped)) {
					returnString=currentChar+returnString;	
					trailStripped=true;
				}//if
			}//for
			return (returnString);
		}//stripTrailingChars
		
		/**
		 * Strips the outside (leading and trailing) characters from an input string and returns the newly reformatted string. As soon as a 
		 * non-stripped character is encountered from both directions, the remaining middle of the string is left intact.
		 *  
		 * @param inputString The string from which to strip the outside characters. The contents of this parameter are copied
		 * so the original data is not affected.
		 * @param stripChars The character or characters to strip from <code>inputString</code>. Multiple characters may be included
		 * as a string or, alternately, this parameter may be an array of strings.
		 * 
		 * @return A newly created copy of <code>inputString</code> with all the specified characters stripped out.
		 * 
		 * @example The following example strips all punctuation and separators from the beginning and end of the given input string:
		 * <listing version="3.0">
		 * var sourceString:String = "*** No extra stuff here! ***";
		 * var strippedString:String = SwagDataTools.stripOutsideChars(sourceString, SwagDataTools.PUNCTUATION_RANGE + SwagDataTools.SEPARATOR_RANGE);
		 * trace (strippedString); //"No extra stuff here"
		 * </listing>
		 * 
		 */
		public static function stripOutsideChars(inputString:String, stripChars:*):String {
			var returnString:String=new String();
			returnString=stripLeadingChars(inputString, stripChars);
			returnString=stripTrailingChars(returnString, stripChars);
			return (returnString);
		}//stripOutsideChars
		
		/**
		 * Strips all of the specified characters from an input string and returns the newly reformatted string.
		 *  
		 * <p>This method affects the whole string unlike the <code>stripLeadingChars</code>, <code>stripTrailingChars</code>, and
		 * <code>stripOutsideChars</code> methods.</p>
		 *  
		 * @param inputString The string from which to strip the characters. The contents of this parameter are copied
		 * so the original data is not affected.
		 * @param stripChars The character or characters to strip from <code>inputString</code>. Multiple characters may be included
		 * as a string or, alternately, this parameter may be an array of strings.
		 * 
		 * @return A newly created copy of <code>inputString</code> with all the specified characters stripped out.
		 * 
		 * @example The following example strips the uppercase letters from the input string:
		 * <listing version="3.0">
		 * var sourceString:String = "EeVvEeRrYy OoTtHhEeRr LlEeTtTtEeRr IiSs OoKkAaYy";
		 * var strippedString:String = SwagDataTools.stripChars(sourceString, SwagDataTools.UPPERCASE_RANGE);
		 * trace (strippedString); //"every other letter is okay"
		 * </listing>
		 * 
		 */
		public static function stripChars(inputString:String, stripChars:*=" "):String {
			if (inputString==null) {
				return(new String());
			}//if
			if ((inputString=="") || (inputString.length==0)) {
				return(new String());
			}//if
			if (stripChars==null) {
				return (inputString);
			}//if
			var localStripChars:String=new String();
			if (stripChars is Array) {
				for (var count:uint=0; count<stripChars.length; count++) {
					localStripChars.concat(String(stripChars[count] as String));
				}//for	
			} else if (stripChars is String) {
				localStripChars=new String(stripChars);
			} else {
				return (inputString);
			}//else
			if ((localStripChars=="") || (localStripChars.length==0)) {
				return (inputString);
			}//if
			var localInputString:String=new String(inputString);
			var returnString:String=new String();			
			for (var charCount:Number=(localInputString.length-1); charCount>=0; charCount--) {
				var currentChar:String=localInputString.charAt(charCount);
				if (localStripChars.indexOf(currentChar)<0) {
					returnString=currentChar+returnString;						
				}//if
			}//for
			return (returnString);
		}//stripChars
		
		/**
		 * Replaces all occurances of a specified string within a string with another string.
		 *  
		 * @param sourceString The string within which to perform the replacement. The contents of the string are copied so that
		 * the original string is not affected.
		 * @param insertString The string to replace within <code>sourceString</code>.
		 * @param patternString The pattern to replace with <code>insertString</code> within the <code>sourceString</code>.
		 * 
		 * @return A copy of the <code>sourceString</code> with any occurances of <code>patternString</code> replaced with 
		 * <code>insertString</code>.
		 * 
		 * @example The following example replaces all occurances of "%name%" with "Bob".
		 * 
		 * <listing version="3.0">
		 * var sourceString:String = "%name% is an excellent developer, and %name% is also a friend.";
		 * var resultString:String = SwagDataTools.replaceString(sourceString, "Bob", "%name%");
		 * trace (resultString); //"Bob is an excellent developer, and Bob is also a friend."
		 * </listing> 
		 * 
		 */
		public static function replaceString(sourceString:String, insertString:String, patternString:String):String {
			var localSourceString:String=new String(sourceString);
			var replaceSplit:Array=localSourceString.split(patternString);
			var returnString:String=replaceSplit.join(insertString);
			return (returnString);
		}//replaceString
		
		/**
		 * Returns a substring of a string up to, and optionally inluding, a specific matching string.
		 * <p>This method is similar to the <code>String.slice</code>, <code>String.substr</code>, or <code>String.substring</code>
		 * methods except that it uses character matching instead of index values to denote the selected string.</p>
		 * 
		 * @param sourceString The string from which to extract the substring. This value is copied by the method so the original
		 * string will remain unaffacted.
		 * @param patternString The pattern string to find within the <code>sourceString</code>. All the characters in <code>sourceString</code>
		 * up to and (optionally), including <code>patternString</code> will be returned.
		 * @param includePattern If <em>true</em>, the pattern string will be included in the returned string, otherwise only the 
		 * characters up to the <code>patternString</code> will be returned.
		 * @param caseSensitive If <em>true</em>, the pattern and source strings are evaluated as is (case-sensitive). If <em>false</em>,
		 * a non-case-sensitive comparison is done.
		 * 
		 * @return The substring copy of <code>sourceString</code> up to and (optionally) including the <code>patternString</code>. If the
		 * pattern can't be found, or it's empty (null or ""), an empty string is returned. If the method 
		 * encounters any other problem, a <em>null</em> value is returned.
		 * 
		 * @see #getStringAfter()
		 * 
		 */
		public static function getStringBefore(sourceString:String, patternString:String, includePattern:Boolean=false, caseSensitive:Boolean=false):String {
			if (sourceString==null) {
				return (null);
			}//if			
			var localSourceString:String=new String(sourceString);
			if ((patternString==null) || (patternString=="") || (sourceString=="")) {
				return (localSourceString);
			}//if
			var localLCSourceString:String=localSourceString.toLowerCase();
			var localPatternString:String=new String(patternString);			
			var localLCPatternString:String=localPatternString.toLowerCase();
			var returnString:String=new String();;
			if (caseSensitive==true) {
				var patternIndex:int=localSourceString.indexOf(localPatternString);				
			} else {
				patternIndex=localLCSourceString.indexOf(localLCPatternString);			
			}//else
			if (patternIndex>0) {
				if (includePattern) {
					patternIndex+=localPatternString.length;
					returnString=localSourceString.substr(0, patternIndex);
				} else {
					returnString=localSourceString.substr(0, patternIndex);
				}//else
				return (returnString);
			} else {
				return (returnString);
			}//else
			return (returnString);
		}//getStringBefore
		
		/**
		 * Returns a substring of a string after, and optionally inluding, a specific matching string.
		 * <p>This method mimics the functionality of the <code>getStringBefore</code> method but returns the end of the string
		 * up to and (optionally) including the pattern string instead of the beginning.</p>
		 * 
		 * @param sourceString The string from which to extract the substring. This value is copied by the method so the original
		 * string will remain unaffacted.
		 * @param patternString The pattern string to find within the <code>sourceString</code>. All the characters in <code>sourceString</code>
		 * after and (optionally), including <code>patternString</code> will be returned.
		 * @param includePattern If <em>true</em>, the pattern string will be included in the returned string, otherwise only the 
		 * characters after the <code>patternString</code> will be returned.
		 * @param caseSensitive If <em>true</em>, the pattern and source strings are evaluated as is (case-sensitive). If <em>false</em>,
		 * a non-case-sensitive comparison is done.
		 * 
		 * @return The substring copy of <code>sourceString</code> after and (optionally) including the <code>patternString</code>. If the
		 * pattern can't be found, or it's empty (null or ""), an empty string is returned. If the method encounters any other problem, 
		 * a <em>null</em> value is returned.
		 * 
		 */
		public static function getStringAfter(sourceString:String, patternString:String, includePattern:Boolean=false, caseSensitive:Boolean=false):String {
			if (sourceString==null) {
				return (null);
			}//if			
			var localSourceString:String=new String(sourceString);
			if ((patternString==null) || (patternString=="") || (sourceString=="")) {
				return (localSourceString);
			}//if
			var localLCSourceString:String=localSourceString.toLowerCase();
			var localPatternString:String=new String(patternString);			
			var localLCPatternString:String=localPatternString.toLowerCase();
			var returnString:String=new String();;
			if (caseSensitive==true) {
				var patternIndex:int=localSourceString.lastIndexOf(localPatternString);				
			} else {
				patternIndex=localLCSourceString.lastIndexOf(localLCPatternString);			
			}//else		
			patternIndex+=1;
			if (patternIndex>0) {				
				if (includePattern) {
					patternIndex-=localPatternString.length;
					returnString=localSourceString.substr(patternIndex);
				} else {
					returnString=localSourceString.substr(patternIndex);
				}//else
				return (returnString);
			} else {
				return (returnString);
			}//else
			return (returnString);
		}//getStringAfter
		
		/**
		 * Parses / splits a string containing software version information (for example, "3.2.1 b"), into native (numeric / boolean) values.
		 * 
		 * <p>The format of a typical version string is: <strong>majorVersion.minorVersion.buildNumber.internalBuildNumber a / b</strong>, where
		 * "a" signifies an alpha version, and "b" is a beta version. If both "a" and "b" appear in the version information, it's considered
		 * to represent an alpha version.</p>
		 *  
		 * @param versionString The version string to parse. Currently, four levels of revision are supported (i.e. four
		 * separators), as well as optional "b" or "a" on the end to denote beta or alpha versions.
		 * @param separator The separator character between the version numbers (for example, ".").
		 * 
		 * @return An object containing the following properties:
		 * <ul>
		 * <li>major (<code>int</code>) - The parsed major value from the version string.</li>
		 * <li>minor (<code>int</code>) - The parsed minor value from the version string.</li> 
		 * <li>build (<code>int</code>) - The parsed build value from the version string.</li>
		 * <li>internalBuild (<code>int</code>) - The parsed internal build value from the version string.</li>
		 * <li>alpha (<code>Boolean</code>) - The parsed alpha notation setting from the version string.</li>
		 * <li>beta (<code>Boolean</code>) - The parsed beta notation setting from the version string (if <code>alpha</code> 
		 * is <em>true</em>, <code>beta</code> will always be false).</li>
		 * </ul>
		 * Any numeric version values omitted will be returned as <em>-1</em>, and boolean values as <em>false</em>.
		 * 
		 * @see flash.system.Capabilities#version
		 */
		public static function parseVersionString(versionString:String, separator:String="."):Object {			
			var returnObject:Object=new Object();
			returnObject.major=new int(-1);
			returnObject.minor=new int(-1);
			returnObject.build=new int(-1);
			returnObject.internalBuild=new int(-1);
			returnObject.alpha=new Boolean();
			returnObject.alpha=false;
			returnObject.beta=new Boolean();
			returnObject.beta=false;
			if (versionString==null) {
				return (returnObject);
			}//if
			var localVersionString:String=new String(versionString);
			localVersionString=stripOutsideChars(localVersionString, " ");
			if ((localVersionString=="") || ((localVersionString.length==0))) {
				return (returnObject);
			}//if 
			var versionParts:Array=localVersionString.split(separator);
			if (hasData(versionParts[0])) {
				var partString:String=stripChars(versionParts[0], SwagDataTools.LOWERCASE_RANGE+SwagDataTools.UPPERCASE_RANGE);
				returnObject.major=int(partString);
			}//if
			if (hasData(versionParts[1])) {
				partString=stripChars(versionParts[1], SwagDataTools.LOWERCASE_RANGE+SwagDataTools.UPPERCASE_RANGE);
				returnObject.minor=int(partString);
			}//if
			if (hasData(versionParts[2])) {
				partString=stripChars(versionParts[2], SwagDataTools.LOWERCASE_RANGE+SwagDataTools.UPPERCASE_RANGE);
				returnObject.build=int(partString);
			}//if
			if (hasData(versionParts[3])) {
				var finalPart:String=new String(versionParts[3] as String);
				var stripCharacters:String=SwagDataTools.LOWERCASE_RANGE+SwagDataTools.UPPERCASE_RANGE
					+SwagDataTools.PUNCTUATION_RANGE+SwagDataTools.SEPARATOR_RANGE;
				returnObject.internalBuild=int(stripChars(finalPart, stripCharacters));						
			}//if			
			if (stringContains(localVersionString, "a", false)) {
				returnObject.alpha=true;
			} else if (stringContains(localVersionString, "b", false)) {
				returnObject.beta=true;
			}//else if
			return (returnObject);
		}//parseVersionString
		
		/**
		 * Converts a value in radians to its corresponding value in degrees.
		 * 
		 * @param radians The radians value to convert to degrees.
		 * 
		 * @return The degree equivalent of the input radians value. 
		 * 
		 */
		public static function toDegrees(radians:Number):Number {
			var returnDegs:Number=radians*(180/Math.PI);
			return (returnDegs);
		}//toDegrees
		
		/**
		 * Converts a value in degrees to its corresponding value in radians.
		 * 
		 * @param degrees The degrees value to convert to radians.
		 * 
		 * @return The radians equivalent of the input degrees value. 
		 * 
		 */
		public static function toRadians(degrees:Number):Number {
			var returnRads:Number=degrees*(Math.PI/180);
			return (returnRads);
		}//toRadians
		
		/**
		 * Returns a point on an elipse with x and y radii at a specified angle. The elipse
		 * is assumed to have an origin at coordinates 0,0, and the angle (in degrees) begins at
		 * the right-hand edge of the elipse as in standard geometry. If both the x and y radii are
		 * the same, a circlular coordinate is returned. 
		 * 
		 * @param xRadius The x, or horizontal radius of the elipse.
		 * @param yRadius The y, or vertical radius of the elipse.
		 * @param angle The angle of the point, in degrees.
		 * 
		 * @return A point on the specified elipse at the specified angle. Unless this point is offset to
		 * a new x,y location, the returned <code>Point</code> object's <code>length</code> property can
		 * be used to determing the distance, in pixels, from the elipse's origin to the point.
		 * 
		 */
		public static function getElipseCoords(xRadius:Number, yRadius:Number, angle:Number):Point {
			var returnPoint:Point=new Point();
			var radianAngle:Number=toRadians(angle);
			returnPoint.x=xRadius*Math.cos(radianAngle);
			returnPoint.y=yRadius*Math.sin(radianAngle);			
			return (returnPoint);
		}//getElipseCoords
		
		/**
		 * Converts the to its hexadecimal representation as a string. 		 
		 * <p>For example, the input string "Hello" is represented by its hexadecimal values: 48+65+6C+6C+6F to produce the output 
		 * string "48656C6C6F". If the input parameter is a Number, its value (usually 32 bits) will be converted to its hexadecimal
		 * string representation.</p>
		 * <p>Note that the returned string has no standard hexadecimal notation such as "#" or "0x".</p>
		 * 
		 * @param input The string to convert to its hexadecimal representation. Each character in the string will be converted to its
		 * two-digit hexadecimal value. The input string is copied and so the original value won't be affected.
		 * 
		 * @return The hexadecimal string representation of the <code>input</code> string. Any character for which the hexadecimal
		 * value is less than 10 will have a 0 prepended. In this way the length of the returned string will always be double that
		 * of the input string. If the <code>input</code> parameter is invalid, an empty string is returned. 
		 * 
		 * @see #toHexValue()
		 * @see #fromHexString
		 * 
		 * @internal Conversion from negative numeric values not working correctly!
		 * 		 
		 */	
		public static function toHexString(input:*):String {
			if (isType(input, String, false)) {
				var localString:String=new String();
				localString=String(input);
				var outStr:String=new String();
				var tempStr:String=new String();
				var currentChar:Number=new Number();
				for (var count:uint=0;count<localString.length;count++) {
					currentChar=localString.charCodeAt(count);
					tempStr=currentChar.toString(16);
					tempStr=tempStr.toUpperCase();
					if (tempStr.length<2) {
						outStr+='0'+tempStr;
					} else {
						outStr+=tempStr;
					}//else
				}//for
				return (outStr);
			} else if (isType(input, Number, false) || isType(input, int, false) || isType(input, uint, false)) {				
				outStr=input.toString(16);				
				//Is this a Flash bug? There is nothing that should be producing this value but sometimes we get this!
				if (outStr=='-(0000000') {
					outStr='80000000';
				}//if
				outStr=outStr.toUpperCase();
				return (outStr);
			} else {
				return ("");
			}//else
			return ("");
		}//toHexString
		
		
		/**	
		 * Converts a hexadecinal input string to its ordinal representation, either as an ASCII string, or as a native
		 * numeric type.
		 * 
		 * @param input The string to convert to its ordinal representation. 
		 * @param returnType The return type to convert the <code>input</code> string to. If this is a <code>String</code>, it's assumed to
		 * be a string of hexadecimal values with each 2-digit value representing the ordinal number of an ASCII character. For
		 * example, the <code>input</code> string "48656C6C6F" would be converted to "Hello". If this is a numeric type 
		 * (<code>Number</code>, <code>int</code>, or <code>uint</code>), the input string will be converted to the native numeric value 
		 * matching that type. If it's a <code>ByteArray</code> type, the whole hexadecimal string will be converted to native binary
		 * data (<code>uint</code>) in a new <code>ByteArra</code> object.
		 * 
		 * @return The plain text or native numeric value of the hexadecimal input string, or <em>null</em> if there was a problem converting it.
		 * 
		 * @see #toHexString()		 
		 */	
		public static function fromHexString(input:String, returnType:Class):* {
			if (returnType==Number) {
				var returnNum:Number=new Number();
				returnNum=Number('0x'+input);
				return (returnNum);
			} else if (returnType==int) {
				var returnInt:int=new int();
				returnInt=int('0x'+input);
				return (returnInt);
			} else if (returnType==uint) {
				var returnUInt:uint=new uint();
				returnUInt=uint('0x'+input);
				return (returnUInt);
			} else if (returnType==ByteArray) {
				var realString:String=new String();
				realString=String(input);
				var returnArray:ByteArray=new ByteArray();
				var tempStr:String=new String();		
				for (var count:Number=0;count<realString.length;count+=2) {
					tempStr=realString.substr(count,2);
					tempStr='0x'+tempStr;
					var uintVal:uint=uint(tempStr);					
					returnArray.writeByte(uintVal);
				}//for
				return (returnArray);
			} else if (returnType==String) {
				realString=new String();
				realString=String(input);
				var outStr:String=new String();
				tempStr=new String();		
				for (count=0;count<realString.length;count+=2) {
					tempStr=realString.substr(count,2);
					tempStr='0x'+tempStr;
					var numVal:Number=Number(tempStr);			
					outStr+=String.fromCharCode(numVal);
				}//for
				return (outStr);
			} else {
				return (null);
			}//else
			return (null);
		}//fromHexString
		
		/**
		 * Converts the input Number / int / uint to its binary string representation.
		 *  
		 * @param inputNumber The number (Number / int / uint) to convert to a binary string representation.
		 * @param bits The number of bits to process in the <code>inputNumber</code>. Note that if using a 
		 * <code>bits</code> value that is less than the number of bits found in the <code>inputNumber</code>
		 * (typically 32 or 64), the resulting binary value won't be equal to the original decimal value since
		 * some of the information is necessarily lost.
		 * 
		 * @return The binary representation of the input number, accurate to the number of bits specified.
		 * 
		 * @see fromBinaryString()
		 * 
		 */
		public static function toBinaryString(inputNumber:*, bits:uint=32):String {
			if (((inputNumber is uint) || (inputNumber is int) || (inputNumber is Number))==false) {
				return (new String());
			}//if
			if (bits==0) {
				return (new String());
			}//if
			var returnString:String=new String();
			var currentDigit:String;
			for (var count:uint=0; count<bits; count++) {						
				currentDigit=String((inputNumber & (1 << count)) >>> count);
				returnString=currentDigit+returnString;				
			}//for
			return (returnString);
		}//toBinaryString
		
		/**
		 * Converts the input binary string sequence to a native numeric type.
		 *  
		 * @param inputString The string to convert to a native numeric type.
		 * @param returnType The numeric type to convert the <code>inputString</code> to. Valid types are 
		 * <code>Number</code>, <code>uint</code>, and <code>int</code>.
		 * 
		 * @return The numeric value represented by the binary <code>inputString</code>, of the type specified
		 * by <code>returnType</code>. If the <code>returnType</code> specified is not a valid numeric type,
		 * or the <code>inputString</code> contains invalid digits (not 0 or 1), <em>null</em> is returned.
		 * 
		 * @see toBinaryString()
		 * 
		 */
		public static function fromBinaryString(inputString:String, returnType:Class):* {			
			if ((returnType!=Number) && (returnType!=uint) && (returnType!=int)) {				
				return (null);
			}//else
			var returnValue:*;
			var localInputString:String=new String(inputString);
			localInputString=stripOutsideChars(localInputString, SwagDataTools.SEPARATOR_RANGE);			
			if ((localInputString=="") || (localInputString.length==0)) {
				returnValue=0;
				return (returnValue);
			}//if			
			for (var count:int=0; count<localInputString.length; count++) {
				var currentChar:String=localInputString.charAt(count);				
				if (currentChar=="1") {
					returnValue=returnValue | (1 << (localInputString.length-count-1));
				} else if (currentChar=="0") {
					returnValue=returnValue | (0 << (localInputString.length-count-1));
				} else {
					//Return null if an unexpected character is encountered.
					return (null);
				}//else
			}//for
			if (returnType==int) {
				returnValue=int(returnValue);	
			} else if (returnType==uint) {
				returnValue=uint(returnValue);
			} else {
				returnValue=Number(returnValue);
			}//else
			return (returnValue);
		}//fromBinaryString	
		
		/**
		 * Returns the bit value at a specific position within the input number. 
		 * 
		 * @param input A valid numeric type (<code>Number</code>, <code>int</code>, or <code>uint</code>), from which to retrieve the 
		 * specified bit value.
		 * @param bitPos The bit position to retrieve from within the <code>input</code> value. This number ranges from 1 to 32 (the highest
		 * bit position currently supported by Flash). This parameter is 1-based so that 1 is the lowest (LSB) bit and 32 is the 
		 * highest (MSB) bit.
		 * 		 
		 * @return <em>True</em> denotes that the bit at the specified position is on, or 1, and <em>false</em> denotes that it's off, or 0.
		 * An <em>undefined</em> value is returned if the associated bit or input number are invalid.
		 * 
		 * @see #setBit()
		 * 		 
		 */
		public static function getBit(input:*=null, bitPos:uint=0):Boolean {			
			if ((!(input is Number)) && (!(input is int)) && (!(input is uint))) {	
				return (undefined);
			}//if
			if ((bitPos<1) || (bitPos>32)) {
				return (undefined);
			}//if
			var returnBool:Boolean=new Boolean();
			returnBool=Boolean ((input & (1 << (bitPos-1))) >> (bitPos-1));
			return (returnBool);
		}//getBit
		
		/**
		 * Sets the bit at the specified position in the input number to the specified value.
		 * 
		 * @param input The numeric value (<code>Number</code>, <code>int</code>, or <code>uint</code>), within which
		 * to manipulate the specified bit value.
		 * @param bitPos The bit position to set from within the <code>input</code> value. This number ranges from 1 to 32 (the highest
		 * bit position currently supported by Flash). This parameter is 1-based so that 1 is the lowest (LSB) bit and 32 is the 
		 * highest (MSB) bit.
		 * @param setValue The value to assign to the specified bit, with <em>true</em> representing 1, or on, and <em>false</em>
		 * representing 0, or off.
		 * 
		 * @return The <code>input</code> value with the specified bit manipulated to the specified value. If the <code>input</code> 
		 * value was an object reference, the original object will be updated as well.
		 * 
		 * @see #getBit()
		 * 		
		 */
		public static function setBit(input:*=null, bitPos:uint=0, setValue:Boolean=false):* {			
			if ((!(input is Number)) && (!(input is int)) && (!(input is uint))) {	
				return (undefined);
			}//if
			if ((bitPos<1) || (bitPos>32)) {				
				return (undefined);
			}//if
			if (setValue==true) {				
				input=input | (1 << (bitPos-1));
			} else {				
				var tempVal:uint=1;
				tempVal=~(tempVal << (bitPos-1));			
				input=input & tempVal;
			}//else
			return (input);
		}//setBit
		
		/**
		 * Converts an input value to a boolean value. Typical input values can include strings such
		 * as "true", "false", "yes", "no", "on", "off", "1", "0", etc., and numbers such as 1 and 0.
		 *  
		 * @param input The input value to attempt to convert to a valid boolean value.
		 * @param defaultValue The default boolean value to return if the input parameter can't be converted.
		 * 
		 * @return A valid boolean value based on the input, or the default value if conversion can't be completed. 
		 * 
		 */
		public static function toBoolean(input:*, defaultValue:Boolean=false):Boolean {
			if (input==null) {
				return (defaultValue);
			}//if
			if ((input is XML) || (input is XMLList)) {
				input=new String(input.toString());
			}//if
			if (input is String) {
				var inputString:String=new String(input);
				inputString=inputString.toLowerCase();
				inputString=stripOutsideChars(inputString, SEPARATOR_RANGE);
				switch (inputString) {
					case "true" : return (true); break;
					case "t" : return (true); break;
					case "yes" : return (true); break;
					case "y" : return (true); break;
					case "on" : return (true); break;
					case "1" : return (true); break;
					case "false" : return (false); break;
					case "f" : return (false); break;
					case "no" : return (false); break;
					case "n" : return (false); break;
					case "off" : return (false); break;
					case "0" : return (false); break;
					default : return (defaultValue); break;
				}//switch
			}//if
			if ((input is Number) || (input is uint) || (input is int)) {
				if (input==1) {
					return (true);
				} else {
					return (false);
				}//else					
			}//if
			return (defaultValue);
		}//toBoolean
		
		/**
		 * Sizes a target <code>DisplayObject</code> while maintaining the aspect ratio. The resulting image will be
		 * sized according to the largest of the width and height parameters. 
		 * 
		 * @param target The <code>DisplayObject</code> to size while maintaining the aspect ratio.
		 * @param targetWidth The desired width of the target object. This value is used if it's larger than the target height.
		 * @param targetHeight The desired height of the target object. This value is used if it's larger than the target width.
		 * @param scaleBitmap If the <code>target</code> parameter is a <code>Bitmap</code>, setting this value will force a
		 * transform to be applied to the resulting <code>BitMap</code> object. 
		 * 
		 * @return The target object, of the same type as the <code>target</code> parameter sized to either the largest width 
		 * or height specified while maintaining the aspect ratio.
		 * 
		 */
		public static function sizeWithAspectRatio(target:DisplayObject, targetWidth:Number, targetHeight:Number, scaleBitmap:Boolean=false):DisplayObject {
			if (target==null) {
				return (null);
			}//if	
			if (target.width>target.height) {
				var multiplier:Number=targetWidth/target.width;
				if ((scaleBitmap) && (target is Bitmap)) {
					var matrix:Matrix = new Matrix();
					matrix.scale(multiplier, multiplier);					
					var smallBMD:BitmapData = new BitmapData(Bitmap(target).bitmapData.width*multiplier, Bitmap(target).bitmapData.height*multiplier, true, 0x000000);
					smallBMD.draw(Bitmap(target).bitmapData, matrix, null, null, null, true);					
					var sizedBitmap:Bitmap = new Bitmap(smallBMD, PixelSnapping.NEVER, true);
					return (sizedBitmap);
				} else {
					target.width=targetWidth;
					target.height*=multiplier;
				}//else
			} else {
				multiplier=targetHeight/target.height;
				if ((scaleBitmap) && (target is Bitmap)) {
					matrix = new Matrix();
					matrix.scale(multiplier, multiplier);					
					smallBMD = new BitmapData(Bitmap(target).bitmapData.width*multiplier, Bitmap(target).bitmapData.height*multiplier, true, 0x000000);
					smallBMD.draw(Bitmap(target).bitmapData, matrix, null, null, null, true);					
					sizedBitmap = new Bitmap(smallBMD, PixelSnapping.NEVER, true);
					return (sizedBitmap);
				} else {
					target.height=targetHeight;
					target.width*=multiplier;
				}//else
			}//else
			return (target);
		}//sizeWithAspectRatio
		
		/**
		 * Converts a <code>ByteArray</code> object to a native Flash display object. This may be
		 * a Bitmap, Sprite, or MovieClip object depending on the data supplied.
		 *  
		 * @param bytes The <code>ByteArray</code> object to be converted to a display object.
		 * @param onLoadComplete The function to invoke when the load operation completes. This function
		 * <em>must</em> be an event listener for an <code>Event.INIT</code> event. Target the event object's
		 * <code>.target.content</code> property for the returned display object.
		 * 
		 * @return A <code>Bitmap</code>, <code>Sprite</code>, or <code>MovieClip</code> object. 
		 * 
		 */
		public static function byteArrayToDisplayObject(bytes:ByteArray, onLoadComplete:Function):DisplayObject {
			var objectLoader:Loader=new Loader();
			objectLoader.contentLoaderInfo.addEventListener(Event.INIT, onLoadComplete);
			objectLoader.loadBytes(bytes);
			return (objectLoader.content);
		}//byteArrayToDisplayObject
		
		/**
		 * Decodes a string containing HTML entitities, including those that are not directly supported with ActionScript's
		 * <code>unescape</code> method.
		 * <p><strong>NOTE: As per the W3C specification, HTML entitities are case-sensitive.</strong></p>
		 * 
		 * @param inString The string containing the HTML entitities to translate to plain text. A copy of this
		 * string is made so that the original paramater data is not affected.
		 * 
		 * @return The processed copy of the <code>inString</code> parameter with all of the HTML entities translated to plain text. 
		 * 
		 */
		public static function HTMLDecode(inString:String):String {
			var localString:String=new String();
			localString=String(inString);			
			//Typographical / markup / grammatical marks
			localString=replaceString(localString, String.fromCharCode(34), "&quot;");						
			localString=replaceString(localString, String.fromCharCode(39), "&apos;");	
			localString=replaceString(localString, String.fromCharCode(60), "&lt;");
			localString=replaceString(localString, String.fromCharCode(62), "&gt;");
			localString=replaceString(localString, String.fromCharCode(160), "&nbsp;");
			localString=replaceString(localString, String.fromCharCode(38), "&amp;");
			localString=replaceString(localString, String.fromCharCode(166), "&brvbar;");			
			localString=replaceString(localString, String.fromCharCode(8211), "&ndash;");
			localString=replaceString(localString, String.fromCharCode(8212), "&mdash;");
			localString=replaceString(localString, String.fromCharCode(171), "&laquo;");
			localString=replaceString(localString, String.fromCharCode(187), "&raquo;");
			localString=replaceString(localString, String.fromCharCode(171), "&lsaquo;");
			localString=replaceString(localString, String.fromCharCode(187), "&rsaquo;");
			localString=replaceString(localString, String.fromCharCode(167), "&sect;");
			localString=replaceString(localString, String.fromCharCode(182), "&para;");
			localString=replaceString(localString, String.fromCharCode(8224), "&dagger;");			
			localString=replaceString(localString, String.fromCharCode(8225), "&Dagger;");
			localString=replaceString(localString, String.fromCharCode(8226), "&bull;");
			localString=replaceString(localString, String.fromCharCode(183), "&middot;");
			localString=replaceString(localString, String.fromCharCode(191), "&iquest;");
			localString=replaceString(localString, String.fromCharCode(161), "&iexcl;");
			//Intellectual property marks
			localString=replaceString(localString, String.fromCharCode(169), "&copy;");
			localString=replaceString(localString, String.fromCharCode(169), "&copyright;");
			localString=replaceString(localString, String.fromCharCode(174), "&reg;");
			localString=replaceString(localString, String.fromCharCode(174), "&registered;");
			localString=replaceString(localString, String.fromCharCode(8482), "&trade;");
			localString=replaceString(localString, String.fromCharCode(8482), "&trademark;");			
			//Mathematical marks
			localString=replaceString(localString, String.fromCharCode(177), "&plusmn;");
			localString=replaceString(localString, String.fromCharCode(8722), "&minus;");
			localString=replaceString(localString, String.fromCharCode(8721), "&sum;");
			localString=replaceString(localString, String.fromCharCode(215), "&times;");
			localString=replaceString(localString, String.fromCharCode(247), "&divide;");
			localString=replaceString(localString, String.fromCharCode(189), "&frac12;");
			localString=replaceString(localString, String.fromCharCode(188), "&frac14;");			
			localString=replaceString(localString, String.fromCharCode(190), "&frac34;");
			localString=replaceString(localString, String.fromCharCode(8734), "&infin;");
			localString=replaceString(localString, String.fromCharCode(8776), "&asymp;");
			localString=replaceString(localString, String.fromCharCode(8804), "&le;");
			localString=replaceString(localString, String.fromCharCode(8805), "&ge;");
			localString=replaceString(localString, String.fromCharCode(8800), "&ne;");
			localString=replaceString(localString, String.fromCharCode(8801), "&equiv;");
			localString=replaceString(localString, String.fromCharCode(8747), "&int;");
			localString=replaceString(localString, String.fromCharCode(8730), "&radic;");
			localString=replaceString(localString, String.fromCharCode(185), "&sup1;");
			localString=replaceString(localString, String.fromCharCode(178), "&sup2;");
			localString=replaceString(localString, String.fromCharCode(179), "&sup3;");			
			localString=replaceString(localString, String.fromCharCode(188), "&micro;");
			localString=replaceString(localString, String.fromCharCode(176), "&deg;");
			localString=replaceString(localString, String.fromCharCode(8240), "&permil;"); 
			localString=replaceString(localString, String.fromCharCode(8242), "&prime;");
			localString=replaceString(localString, String.fromCharCode(8243), "&Prime;");
			localString=replaceString(localString, String.fromCharCode(913), "&Alpha;");
			localString=replaceString(localString, String.fromCharCode(945), "&alpha;");
			localString=replaceString(localString, String.fromCharCode(914), "&Beta;");
			localString=replaceString(localString, String.fromCharCode(946), "&beta;");
			localString=replaceString(localString, String.fromCharCode(916), "&Delta;");
			localString=replaceString(localString, String.fromCharCode(948), "&delta;");
			localString=replaceString(localString, String.fromCharCode(928), "&Pi;");
			localString=replaceString(localString, String.fromCharCode(960), "&pi;");	
			localString=replaceString(localString, String.fromCharCode(937), "&Omega;");
			localString=replaceString(localString, String.fromCharCode(969), "&omega;");
			//Currency symbols
			localString=replaceString(localString, String.fromCharCode(162), "&cent;");
			localString=replaceString(localString, String.fromCharCode(163), "&pound;");
			localString=replaceString(localString, String.fromCharCode(165), "&yen;");			
			localString=replaceString(localString, String.fromCharCode(8364), "&euro;");
			localString=replaceString(localString, String.fromCharCode(164), "&curren;");
			//One more pass to decode numeric HTML entities
			localString=unescape (localString);
			return (localString);
		}//urlDecode
		
		/**
		 * Retrieves an ordered list (<code>Array</code>), of the parameters for the specified method.
		 * <p>The returned list will be an array of classes / types that can be used to determine what data type(s)
		 * the supplied method supports.</p> 
		 * 
		 * @param method The method for which to retrieve the list of parameters.
		 * @param container The containing object in which the <code>method</code> resides. Without this reference it's
		 * not possible to determine the specific method properties (this call will fail).
		 * 
		 * @return An ordered <code>Array</code> of classes / types, in the order in which they appear, of the specified
		 * method, or <em>null</em> if there was a problem retrieving this information. For a method with no parameters,
		 * an empty <code>Array</code> object is returned. If the <code>container</code> property is <em>null</em> or
		 * doesn't contain the referenced <code>method</code>, <em>null</em> is returned. If a parameter is a wildcard (&#42;),
		 * a <em>null</em> value is stored at the associated index location within the returned array. The <code>... rest</code>
		 * notation is not considered a parameter since, technically, the method does not expect any data and no type is declared. 
		 * <p><strong>Note: Unlike the index values returned by the <code>describeType</code> method, the returned parameter list 
		 * is 0-indexed (i.e. always 1 less than in the XML description).</strong></p>
		 * 
		 */		
		public static function getMethodParameters(method:Function, container:*):Array {			
			if (method==null) {
				return (null);
			}//if
			if (container==null) {
				return (null);
			}//if
			var returnArray:Array=new Array();
			var containerInfo:XML=describeType(container) as XML;
			if (SwagDataTools.hasData(containerInfo.method)==false) {
				return (null);
			}//if
			var methods:XMLList=containerInfo.method as XMLList;				
			for (var count:uint=0; count<methods.length(); count++) {
				var currentMethodNode:XML=methods[count] as XML;				
				if (SwagDataTools.hasData(currentMethodNode.@name)) {
					var methodName:String=new String(currentMethodNode.@name);					
					if (container[methodName]===method) {						
						if (SwagDataTools.hasData(currentMethodNode.parameter)) {
							var parameterIndex:uint=0;
							var parameterNodes:XMLList=currentMethodNode.parameter as XMLList;							
							for (var count2:uint=0; count2<parameterNodes.length(); count2++) {
								var currentParameterNode:XML=parameterNodes[count2] as XML;
								if (SwagDataTools.hasData(currentParameterNode.@index)) {
									parameterIndex=uint(String(currentParameterNode.@index));
									parameterIndex-=1; //parameters are 1-indexed
								}//if
								if (SwagDataTools.hasData(currentParameterNode.@type)) {
									var typeString:String=new String(currentParameterNode.@type);
									if (typeString=="*") {
										returnArray[parameterIndex]=null;
									} else {
										try {
											typeString=SwagDataTools.replaceString(typeString, ".", "::");											
											var typeClass:Class=getDefinitionByName(typeString) as Class;
											if (typeClass!=null) {
												returnArray[parameterIndex]=typeClass;		
											}//if
										} catch (e:*) {											
										}//catch
									}//else
								}//if
								parameterIndex++;
							}//for
						}//if
					}//if
				}//if
			}//for
			return (returnArray);
		}//getMethodParameters
		
		/**
		 * Returns true if the specified object (usually a class or class instance), contains a
		 * public constant with a specific name.
		 * <p>This can be used, for example, to determine if a specific event type belongs to
		 * an event object.</p>
		 *  
		 * @param targetObject The object to inspect for the constant.
		 * @param constantName The name of the constant to attempt to find.
		 * 
		 * @return <em>True</em> if the specified constant exists within the <code>targetObject</code>,
		 * <em>false</em> otherwise. 
		 * 
		 */
		public static function hasDeclaredConstant(targetObject:*=null, constantName:String=null):Boolean {
			if ((targetObject==null) || (constantName==null) || (constantName=="")) {
				return (false);
			}//if
			var objectInfo:XML=describeType(targetObject) as XML;
			if (!SwagDataTools.hasData(objectInfo.constant)) {
				return (false);
			}//if
			var constantNodes:XMLList=objectInfo.constant as XMLList;
			for (var count:uint=0; count<constantNodes.length(); count++) {
				var currentConstantNode:XML=constantNodes[count] as XML;
				if (SwagDataTools.hasData(currentConstantNode.@name)) {
					var currentConstantName:String=String(currentConstantNode.@name);
					if (constantName==currentConstantName) {
						return (true);
					}//if
				}//if
			}//for
			return (false);
		}//hasDeclaredConstant
		
	}//SwagDataTools class
	
}//package
