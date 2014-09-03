package swag.events {
	
	import swag.interfaces.events.ISwagMovieClipEvent;
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
	public class SwagMovieClipEvent extends SwagEvent implements ISwagMovieClipEvent	{
		
		/**
		 * Dispatched when a playback operation of any kind is started on the associated movie clip.
		 */
		public static const START:String="SwagEvent.SwagMovieClipEvent.START";
		/**
		 * Dispatched when a playback operation of any kind is completed on the associated movie clip.
		 */
		public static const END:String="SwagEvent.SwagMovieClipEvent.END";
		/**
		 * Dispatched when a playback advances on the associated movie clip.
		 */
		public static const FRAME:String="SwagEvent.SwagMovieClipEvent.FRAME";
		
		
		public function SwagMovieClipEvent(eventType:String=null)	{
			super(eventType);
		}//constructor
		
	}//SwagMovieClipEvent class
	
}//package