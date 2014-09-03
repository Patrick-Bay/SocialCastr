package socialcastr.events {
	
	import swag.events.SwagEvent;
	
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
	public class MovieClipButtonEvent extends SwagEvent	{
		
		public static const ONCLICK:String="SocialCastr.MovieClipButtonEvent.ONCLICK";
		public static const ONDOWN:String="SocialCastr.MovieClipButtonEvent.ONDOWN";
		public static const ONRELEASE:String="SocialCastr.MovieClipButtonEvent.ONRELEASE";
		public static const ONOVER:String="SocialCastr.MovieClipButtonEvent.ONOVER";
		public static const ONOUT:String="SocialCastr.MovieClipButtonEvent.ONOUT";
		public static const ONLOCKSTATE:String="SocialCastr.MovieClipButtonEvent.ONLOCKSTATE";
		public static const ONUNLOCKSTATE:String="SocialCastr.MovieClipButtonEvent.ONUNLOCKSTATE";
		public static const ONSHOW:String="SocialCastr.MovieClipButtonEvent.ONSHOW";
		public static const ONHIDE:String="SocialCastr.MovieClipButtonEvent.ONHIDE";
		
		public var state:String=null;
		
		public function MovieClipButtonEvent(eventType:String=null)	{
			super(eventType);
		}//constructor
		
	}//MovieClipButtonEvent class
	
}//package