package swag.core.instances {
	
	import swag.core.SwagDataTools;
	import swag.interfaces.core.instances.ISwagDate;
	//import flash.utils.*;
	
	/**
	 * Contains and extends a standard Flash <code>Date</code> object with various formatting and comparison options as well
	 * as other date-related utilities. 
	 * <p>This instance is intended to be used alone but is also used throughout the SwAG toolkit for date support.</p>
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
	public class SwagDate implements ISwagDate {
				
		/**
		 * @private 
		 */
		private var _date:Date = null;
		
		/**
		 * Default constructor for the <code>SwagDate</code> object.
		 * 
		 *  
		 * @param args The parameter to instantiate the instance with. If no parameter is specified, a new standard 
		 * Flash <code>Date</code> object is created with the current system date. If the parameter specified is a string, 
		 * an attempt is made by the <code>Date</code> object to create an instance of matching date properties 
		 * (see the <code>Date</code> constructor for valid formatting options). If the parameter is another <code>SwagDate</code> 
		 * instance, the date properties of the original instance are copied to the new one.
		 * 
		 * @see global#Date() 
		 * 
		 */
		public function SwagDate(... args) {
			if (args[0]!=undefined) {
				if (SwagDataTools.isType(args[0], String, false)) {
					this._date = new Date(args[0]);	
				} else if (SwagDataTools.isType(args[0], int, false)) {
					this._date = new Date(args[0]);
				} else if (SwagDataTools.isType(args[0], uint, false)) {
					this._date = new Date(args[0]);	
				} else if (SwagDataTools.isType(args[0], Number, false)) {
					this._date = new Date(args[0]);	
				} else if (SwagDataTools.isType(args[0], SwagDate, false)) {
					this._date=new Date(SwagDate(args[0]).toString());
				} else {
					this._date = new Date();
				}//else				
			} else {
				this._date = new Date();
			}//else
		}//constructor
		
		/**
		 * Compares the current <code>SwagDate</code> instance to another one to see if it comes later.
		 * 
		 * @param date The <code>SwagDate</code> instance to compare with this one.
		 * 
		 * @return <em>True</em> if the current <code>SwagDate</code> instance (this) is later than the specified one. 
		 * <em>False</em> is returned if the other date (parameter) is earlier, or comes before, the current one (this).  
		 * 
		 */
		public function isLater(date:SwagDate):Boolean {
			if (date == null) {
				return (false);
			}//if			
			if (this.dateIndex <= date.dateIndex) {
				return (false);
			} else {
				return (true);
			}//else
		}//isLater
		
		/**
		 * Compares the current <code>SwagDate</code> instance to another one to see if they fall on the same date.
		 * 
		 * @param date The <code>SwagDate</code> instance to compare with this one.
		 * 
		 * @return <em>True</em> if the current <code>SwagDate</code> instance (this) is the same as the specified one. 
		 * <em>False</em> is returned if the other date (parameter) is earlier or later than the current one (this).  
		 * 
		 */
		public function isSame(date:SwagDate):Boolean {
			if (date == null) {
				return (false);
			}//if
			if ((date.date.getFullYear() == this.date.getFullYear()) && 
				(date.date.getMonth() == this.date.getMonth()) && 
				(date.date.getDate() == this.date.getDate())) {
				return (true)
			} else {
				return (false);
			}//else
		}//isSame
		
		/**
		 * Returns the number of days of the specified month, or of the current month associated with the <code>SwagDate</code>
		 * instance if none specified.
		 * 
		 * @param args The month number to evaluate. This parameter may either be a numberic type (starting at 0 for January),
		 * a string (valid entries include the full month name, month abreviation, or numeric string representing the month number), 
		 * or omitted in which case the current <code>SwagDate</code> month value will be used.
		 * 
		 * @return The number of days in the specified month. <strong>Note: The value for February always returns a non-leap year number
		 * (29 days). Use the <code>isLeapYear</code> method to adjust this value wherer required.</strong>
		 * 
		 * @see #isLeapYear()
		 * 
		 */
		public function getDaysPerMonth (... args):uint {
				var month:uint = new uint();
				if ((args[0] == undefined) || (args[0] == null)) {				
					var dateObj:Date = new Date();
					month = dateObj.getMonth();
				} else {
					if ((args[0] is Number) || (args[0] is uint) || (args[0] is int)) {
						month = args[0];
					} else {
						if (args[0] is String) {
							month = getMonthNumber(args[0]);
						}//if
					}//else
				}//else
				switch (month) {
					case 0 : return (31); break;
					//TODO: Check for leap year
					case 1 : return (29); break;
					case 2 : return (31); break;
					case 3 : return (30); break;
					case 4 : return (31); break;
					case 5 : return (30); break;
					case 6 : return (31); break;
					case 7 : return (31); break;
					case 8 : return (30); break;
					case 9 : return (31); break;
					case 10 : return (30); break;
					case 11 : return (31); break;
					default: return (null); break;
				}//switch
			}//getDaysPerMonth
			
			/**
			 * Translates the specified month string (name or numeric string representation), to its 0-based month value.
			 * <p>Months are numbered starting from 0=January, 1=February, 2=March, and so on.</p>
			 *  
			 * @param monthName The name, 3-letter abreviation (with an optional period at the end), or numeric string representation 
			 * of the month. For example, "February", "Feb.", "february", "feb", and "1", are all equivalent and will return 
			 * month number 1.
			 * 
			 * @return The 0-based month number represented by the parameter. That is, 0=January, 1=February, and so on.
			 * 
			 */
			public static function getMonthNumber(monthName:String):uint {
				if (monthName == null) {
					return (null);
				}//if
				var month:String = new String();
				month = monthName;
				month = month.toLowerCase();
				month = SwagDataTools.stripOutsideChars(month, SwagDataTools.SEPARATOR_RANGE);
				month = SwagDataTools.replaceString(month, "", ".");
				switch (month) {
					case "january": return (0); break;
					case "jan": return (0); break;
					case "february": return (1); break;
					case "feb": return (1); break;
					case "march": return (2); break;
					case "mar": return (2); break;
					case "april": return (3); break;
					case "apr": return (3); break;
					case "may": return (4); break;				
					case "june": return (5); break;
					case "jun": return (5); break;
					case "july": return (6); break;
					case "jul": return (6); break;
					case "august": return (7); break;
					case "aug": return (7); break;
					case "september": return (8); break;
					case "sept": return (8); break;
					case "sep": return (8); break;
					case "october": return (9); break;
					case "oct": return (9); break;
					case "november": return (10); break;
					case "nov": return (10); break;
					case "december": return (11); break;
					case "dec": return (11); break;
					case "0": return (0); break;
					case "1": return (1); break;
					case "2": return (2); break;
					case "3": return (3); break;
					case "4": return (4); break;
					case "5": return (5); break;
					case "6": return (6); break;
					case "7": return (7); break;
					case "8": return (8); break;
					case "9": return (9); break;
					case "10": return (10); break;
					case "11": return (11); break;
					default: return (null);
				}//switch
				return (null);
			}//getMonthNumber
			
			/**
			 * Returns the full or partial name of the month represented by the input parameter.
			 * 
			 * @param monthIndex The numeric index of the month, starting with 0=January, 1=February, 2=March, etc.
			 * @param args Optional parameters include (in order):
			 * <p><ul>
			 * <li>abbrev (<code>Boolean</code>) - If <em>true</em>, the three-letter abbreviation for the month name
			 * is returned instead of the full name (e.g. "Jul" instead of "July"). Default is <em>false</em>.</li>
			 * <li>lowercase (<code>Boolean</code>) - If <em>true</em>, the month name (full or abbreviated) is returned
			 * as a lowercase string instead of a mixed-case string in which the first letter is capitalized. Default is
			 * <em>false</em>.</li>
			 * </ul></p>
			 * 
			 * @return The name of the month, either full or abbreviated / capitalized or lowercased (depending on the optional
			 * parameters), of the specified month number.  
			 * 
			 */
			public static function getMonthName(monthIndex:uint, ... args):String {			
				var monthName:String = new String();
				if (args[0] == true) {
					switch (monthIndex) {
						case 0 : monthName = "Jan"; break;
						case 1 : monthName = "Feb"; break;
						case 2 : monthName = "Mar"; break;
						case 3 : monthName = "Apr"; break;
						case 4 : monthName = "May"; break;
						case 5 : monthName = "Jun"; break;
						case 6 : monthName = "Jul"; break;
						case 7 : monthName = "Aug"; break;
						case 8 : monthName = "Sep"; break;
						case 9 : monthName = "Oct"; break;
						case 10 : monthName = "Nov"; break;
						case 11 : monthName = "Dec"; break;				
						default: return (null);
					}//switch
				} else {
					switch (monthIndex) {
						case 0 : monthName = "January"; break;
						case 1 : monthName = "February"; break;
						case 2 : monthName = "March"; break;
						case 3 : monthName = "April"; break;
						case 4 : monthName = "May"; break;
						case 5 : monthName = "June"; break;
						case 6 : monthName = "July"; break;
						case 7 : monthName = "August"; break;
						case 8 : monthName = "September"; break;
						case 9 : monthName = "October"; break;
						case 10 : monthName = "November"; break;
						case 11 : monthName = "December"; break;				
						default: return (null);
					}//switch
				}//else
				if (SwagDataTools.isType(args[1], Boolean, false)) {
					if (args[1]==true) {
						monthName=monthName.toLowerCase();
					}//if
				}//if
				return (monthName);
			}//getMonthName
						
			/**
			 * Evaluates the specified year to determine whether or not it's a leap year. 
			 * <p>Use this in conjunction with any methods that evaluate the number of days in a specific month (especially February).</p>
			 * 
			 * @param args The year value to evaluate. This may either be a numeric type, which will be used as is, a string, which
			 * will be converted to a numeric type, or a <code>SwagDate</code> instance who's <code>year</code> property will be used.
			 * 
			 * @return <em>True</em> if the specified parameter is a valid leap year, <em>false</em> if it's not or if there was an
			 * error converting the parameter to a usable (i.e. numeric) type. 
			 * 
			 */
			public static function isLeapYear(... args):Boolean {
				if ((SwagDataTools.isType(args[0], Number)) || (SwagDataTools.isType(args[0], int)) || (SwagDataTools.isType(args[0], uint))) {
					var year:Number=new Number(String(args[0]));	
				} else if (SwagDataTools.isType(args[0], String)) {
					year=new Number(args[0]);
				} else if (SwagDataTools.isType(args[0], SwagDate)) {
					year=new Number(SwagDate(args[0]).year);
				} else {
					return (false);
				}//else
				//Gregorian calendar evaluation. The 4-year cycle is based on the older Julian calendar and isn't as accurate.
				if ((year%4==0) && ((year%100!=0) || (year%400==0))) {
					return (true);
				} else {
					return (false);
				}//else
				return (false);
			}//isLeapYear
			
			/**
			 * Sets the date (day / month / year) value for the <code>SwagDate</code> instance from a 16-bit packed MS-DOS time format. 
			 * <p>If this value is combined with a 16-bit time value, as with most standard packed MSDOS date/time stamps, it can be 
			 * isolated using a simple shift-right operation:
			 * <listing>MSDOSDateValue=MSDOSPackedTimeDateValue >> 15; //Shift right by 15 bits</listing></p>
			 * <p>Because Flash <code>uint</code>s are 32 or posisbly 64 bits,
			 * only the last 16 bits will be evaluated. This value is assumed to be stored in a MSB (Most Significant Bit first) order.</p>
			 * 
			 * @see swag.core.instances.SwagTime#MSDOSTime
			 */
			public function set MSDOSDate(MSDOSDateValue:uint):void {												
				var dateValue:uint=MSDOSDateValue & 0xFFFF;
				var dayValue:Number=(dateValue & 0x1F) as Number;
				var monthValue:Number=((dateValue & 0x1E0) >> 5) as Number;
				monthValue-=1; //0-based month (January=0, February=1, etc.)
				var yearValue:Number=((dateValue & 0xFE00) >> 9) as Number;
				yearValue+=1980; //As per specification (first year DOS was available)
				this._date=new Date(yearValue, monthValue, dayValue);			
			}//set MSDOSDate
			
			/**
			 * An unsigned integer value based on the date of the instance in the format YYYYMMDD. 
			 * <p>This allows the date object to be used as a unique index value in sorted data sets like numeric arrays or as a unique 
			 * key in databases.</p>
			 * <p>Numbers in this value that are less than 10 are padded with an extra 0 to ensure that index valued and data length are retained 
			 * (i.e. the returned value will always be 8 digits long).</p>	
			 */
			public function get dateIndex():uint {
				var indexVal:uint = new uint();
				var indexString:String = new String();
				indexString = String(this.date.getFullYear());
				if (this.date.getMonth() < 10) {
					indexString += "0";
				}//if			
				indexString += String(this.date.getMonth());
				if (this.date.getDate() < 10) {
					indexString += "0";
				}//if
				indexString += String(this.date.getDate());						
				indexVal = uint(indexString);
				return (indexVal);
			}//get dateIndex
			
			/**
			 *  
			 * The standard Flash <code>Date</code> object associated with the <code>SwagDate</code> instance.
			 * <p> The <code>Date</code> object is used extensively throughout <code>SwagDate</code> and the values of this
			 * standard Flash object should always match the values supplied or updated via <code>SwagDate</code>.</p>
			 * 
			 */
			public function get date():Date {
				return (this._date);
			}//get date
			
			/**
			 * 
			 * The numeric value of the day of the month associated with the <code>SwagDate</code> instance. Day
			 * values are standard calendar values (ranging from 1 to 31).
			 * 
			 */
			public function get day():Number {
				return (this._date.getDate());
			}//get day
					
			
			/**
			 * 
			 * The numeric value of the month associated with the <code>SwagDate</code> instance. 
			 * <p>Month values are 0-indexed; 0=January, 1=February, 2=March, etc.</p> 
			 * 
			 */
			public function get month():Number {
				return (this._date.getMonth());
			}//get month
			
			/**
			 * 
			 * The numeric value of the year associated with the <code>SwagDate</code> instance. 
			 * <p>This returned number is the full, 4-digit year value (e.g. 2011)</p> 
			 * 
			 */
			public function get year():Number {
				return (this._date.getFullYear());
			}//get year
			
			/**			 
			 * The numeric value representing the day of the week associated with the current <code>SwagDate</code> 
			 * instance. 
			 * <p>This value is 0-indexed; 0=Sunday, 1=Monday, 2=Tuesday, etc.</p>	
			 */
			public function get dayOfWeek():Number {
				return (this._date.getDay());
			}//get dayOfWeek
			
			/**
			 * The full name of the day of the week associated with this <code>SwagDate</code> instance. 
			 * <p>The returned name is capitalized (e.g. "Monday").</p> 
			 * 
			 */
			public function get dayOfWeekName():String {
				switch (this.dayOfWeek) {
					case 0 : return ("Sunday"); break;
					case 1 : return ("Monday"); break;
					case 2 : return ("Tuesday"); break;
					case 3 : return ("Wednesday"); break;
					case 4 : return ("Thursday"); break;
					case 5 : return ("Friday"); break;
					case 5 : return ("Saturday"); break;
					default : return ("not defined"); break;
				}//switch
			}//get dayOfWeekName
			
			/**
			 * 
			 * @return The string representation of the <code>SwagDate</code> object. 
			 * <p>Currently this is the same value as that returned by the <code>Date.toDateString</code> method.</p>
			 * 
			 * @see Date#toDateString()
			 */
			public function toString():String {
				return (this._date.toDateString());
			}//toString
		
	}//SwagGate class
	
}//package