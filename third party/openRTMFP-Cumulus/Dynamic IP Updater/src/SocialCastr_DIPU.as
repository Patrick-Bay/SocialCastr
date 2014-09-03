package {
	
	import flash.display.MovieClip;
	import flash.net.NetConnection;
	import flash.net.Responder;
	import flash.text.TextField;
	
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
	public class SocialCastr_DIPU extends MovieClip {
		
		public var resultsTxt:TextField;
		
		private var _nc:NetConnection;
		private var _responder:Responder;
		
		public function SocialCastr_DIPU() {
			this._nc = new NetConnection();
			this._responder = new Responder(this.onResult, this.onStatus);
			this._nc.connect("http://www.myserver.com/amfphp/");
			this._nc.call("RendezvousService/getPublicIP", this._responder);
		}//constructor
		
		public function onResult(obj:*):void {
			this.resultsTxt.text=obj.server.REMOTE_ADDR;			
		}//onResult
		
		public function onStatus(obj:*):void {
			
		}//onStatus
		
	}//SocialCastr_DIPU
	
}//package