package socialcastr.core {
	
	/**
	 * Used to store and execute queued operations for the <code>AnnounceChannel</code> class.
	 * <p>Operation queing allows requests to be made before the Announce Channel has had a chance to connect, or if it's in the 
	 * process of reconnecting.</p>
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
	public class AnnounceChannelQueueItem {
		
		private static var _items:Vector.<AnnounceChannelQueueItem>=new Vector.<AnnounceChannelQueueItem>();
		
		private var _parameters:Array=null;
		private var _function:Function=null;
		private var _thisRef:*;
		
		/**
		 * Create a queued action item.
		 *  
		 * @param queueAction The function to invoke when this item is taken out of the queue and executed.
		 * @param thisRef The reference to the "this" object (the scope), in which to invoke the queued action function. Typically "this".
		 * @param args Any optional parameters to pass to the function, in sequence.
		 * 
		 */
		public function AnnounceChannelQueueItem(queueAction:Function, thisRef:*, ... args)	{
			_items.push(this);
			this._function=queueAction;
			this._thisRef=thisRef;
			if (args!=null) {
				this._parameters=args;
			}//if			
		}//constructor
		
		public function execute(removeFromStack:Boolean=false):void {
			try {
				if (this._parameters!=null) {
					this._function.apply(this._thisRef, this._parameters);
				} else {
					this._function.call(this._thisRef);
				}//else
			} catch (e:*) {
				trace ("AnnounceChannelQueueItem.execute: Could not execute next queued item!");
			} finally {
				this.destroy();
			}//finally
		}//execute
		
		public static function clearQueue():void {
			_items=new Vector.<AnnounceChannelQueueItem>();
		}//clearQueue
		
		public static function executeNext(keepInStack:Boolean=false):Boolean {			
			if (_items==null) {
				_items=new Vector.<AnnounceChannelQueueItem>();
			}///if
			if (_items.length==0) {
				return (false);
			}//if			
			if (keepInStack) {
				var currentItem:AnnounceChannelQueueItem=_items[0] as AnnounceChannelQueueItem;
				currentItem.execute(false);
			} else {				
				var nextItem:AnnounceChannelQueueItem=_items.shift() as AnnounceChannelQueueItem;				
				nextItem.execute(true);
			}//else
			
			if (_items.length==0) {
				return (false);
			} else {
				return (true);
			}//if
		}//executeNext
		
		public function destroy():void {
			var packedItems:Vector.<AnnounceChannelQueueItem>=new Vector.<AnnounceChannelQueueItem>();
			for (var count:uint=0; count<_items.length; count++) {
				var currentItem:AnnounceChannelQueueItem=_items[count] as AnnounceChannelQueueItem;
				if ((currentItem!=null) && (currentItem!=this)) {
					packedItems.push(currentItem);
				}//if
			}//for
			_items=packedItems;
		}//destroy
		
	}//AnnounceChannelQueueItem class
	
}//package