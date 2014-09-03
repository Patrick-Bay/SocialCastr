package swag.network {
	
	import flash.errors.EOFError;
	import flash.utils.ByteArray;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import swag.interfaces.network.ISwagCloudData;
	
	/**
	 * Used to transfer data through a peer-to-peer cloud (a <code>NetGroup</code> instance in Flash).
	 * <p>This class allows provides support for single-shot transmissions, either broadcasts to the cloud, or sending directly to a peer,
	 * as well as data replication / sharing / relaying  
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
	public class SwagCloudData extends Proxy implements ISwagCloudData {
		
		/**
		 * Defines the type of data being associated with this data object.
		 * <p>This allows the retrieving end to determine how to treat the received data.</p> 
		 */		
		private var _control:String=new String();		
		/**
		 * Determines the target destination (typically peer ID), to which to send the associated data to.
		 * <p>If <code>null</code> or blank, this typically denotes a broadcast object (to be sent to all peers).</p>  
		 */
		private var _destination:String=new String();
		/**
		 * The source (sender) peer ID.
		 */
		private var _source:String=new String();
		/**
		 * The data of the associated cloud object.
		 * <p>Unlike the other properties which are used for routing or control operations, this object contains the actual
		 * data to be sent to the group or associated peers. For this reason it's untyped and may contain any valid Flash data type.</p>  
		 */
		private var _data:*;
		
		
		public function SwagCloudData(controlType:String=null) {
			this.setDefaults();
			if (controlType!=null) {
				this.control=controlType;
			}//if
		}//constructor
		
		override flash_proxy function setProperty(name:*, value:*):void {
			trace ("SwagCloudData doesn't support the property \""+name+"\"");
		}//setProperty
		
		override flash_proxy function getProperty(name:*):* {
			trace ("SwagCloudData doesn't have the property \""+name+"\"");
			return (null);
		}//getProperty
		
		public function set control(controlSet:String):void {
			this._control=controlSet;
		}//set control
		
		public function get control():String {
			return (this._control);
		}//get control
		
		public function set destination (destSet:String):void {
			this._destination=destSet;
		}//set destination
		
		public function get destination():String {
			return (this._destination);
		}//get destination	
		
		public function set source (sourceSet:String):void {
			this._source=sourceSet;
		}//set source
		
		public function get source():String {
			return (this._source);
		}//get source	
		
		public function set data(dataSet:*):void {
			this._data=dataSet;
		}//set data
		
		public function get data():* {
			return (this._data);
		}//get data
		
		private function setDefaults():void {
			this._destination="";		
		}//setDefaults
		
	}//SwagCloudData class
	
}//package