package socialcastr.core {
	
	import flash.events.TimerEvent;
	import flash.net.NetStream;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.events.TimelineEvent;
	import socialcastr.interfaces.core.ITimeline;
	import socialcastr.ui.components.VideoDisplayComponent;
	import socialcastr.core.timeline.TimelineInvokeConstants;
	
	import swag.core.instances.SwagDate;
	import swag.core.instances.SwagTime;
	import swag.network.SwagCloud;
	
	/**
	 * Manages a group of <code>TimelineElement</code> instances which trigger specific time-based 
	 * actions within SocialCastr.
	 * <p>A Timeline instance is associated with a time-based system such as a <code>NetStream.time</code> value.
	 * Because of this, the structure of the class is fairly flexible to allow additional time-based plugins.
	 * Using <em>null</em> as the beacon reference causes the Timeline to use the Flash timer, useful for 
	 * functionality such as stream bootstrapping where a stream time is not yet established.</p> 
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
	public class Timeline implements ITimeline	{
		
		private static var _timelines:Vector.<Timeline>=new Vector.<Timeline>(); 
		
		private var _elements:Vector.<TimelineElement>=new Vector.<TimelineElement>();
		private var _broadcastElementsQueue:Vector.<TimelineElement>=new Vector.<TimelineElement>();
		private var _beacon:*=null;
		private var _beaconTimer:Timer=null;
		//Used to record a time stamp which is compared on each cycle. If this time stamp matches the
		//current time it means that the stream is not advancing and appropriate actions are taken.
		private var _storedTime:SwagTime; 
		private var _sampleRate:int=100;
		private var _elpasedTime:uint=0;
		private var _timerStartDelta:int=0;
		//Discard missed low priority timeline elements if missed by longer than 2 seconds (default).
		private var _missedElementDiscardTimeout:int=2000;
		private var _announceChannelCloud:SwagCloud;		
		
		/**
		 * Creates a new Timeline instance.
		 *  
		 * @param beaconObject The object to act as the beacon, or time driver. Currently accepted
		 * types include: <code>VideoDisplayComponent</code>, <em>null</em> (uses the application timer
		 * to calculate a delta offset)
		 * @param sampleRate The sample rate to poll the beacon at, in milliseconds.
		 * @param startupTimelineXML An optional XML object to initialize the timeline with.
		 * 
		 */
		public function Timeline(beaconObject:*, sampleRateVal:int=100, startupTimelineXML:XML=null) {
			_timelines.push(this);
			this._sampleRate=sampleRateVal;
			this._beacon=beaconObject;
			this.incorporateElements(startupTimelineXML);
		}//constructor
		
		/**
		 * Incorporates elements into the timeline.
		 *  
		 * @param source Valid XML objects (XML or XMLList), or representations of XML objects. If the source
		 * is a string, a conversion to XML is attempted. If the source is XML, it is examined to determine if
		 * it is a timeline element (node name "element"), or complete live timeline object ("livetimeline"). 
		 * Elements of a complete live timeline, or a list of individual elements (XMLList) are all added in order,
		 * and individual elements are simply added as-is.
		 * 
		 */
		public function incorporateElements(source:*):void {
			if (source!=null) {
				if (source is String) {
					source=new XML(source);
				}//if
				if (source is XML) {
					//Single element
					if (source.localName()=="element") {
						this.addElement(source);
						return;
					}//if
					//Received entire timeline.
					//TODO: Add option in data to reset entire timeline with new one.
					if (source.localName()=="livetimeline") {
						var elementNodes:XMLList=source.children();
					}//if
				} else if (source is XMLList) {
					//Received timeline elements
					elementNodes=source;
				} else {
					return;
				}//else				
				if (elementNodes!=null) {
					for (var count:uint=0; count<elementNodes.length(); count++) {
						var currentElement:XML=elementNodes[count] as XML;
						if (currentElement.toString()!="") {
							if (currentElement.localName()=="element") {
								this.addElement(currentElement);
							}//if
						}//if
					}//for
				}//if
			}//if
		}//incorporateElements
		
		/**
		 * @private
		 */
		private function onBeaconTimer(eventObj:TimerEvent):void {
			if (this._beacon==null) {
				var streamTime:Number=Number(getTimer()-this._timerStartDelta); //Calculate the delta, accurate to 49 days
				var beaconTime:SwagTime=new SwagTime();
				beaconTime.totalMilliseconds=uint(streamTime);
				var beaconDate:SwagDate=new SwagDate();
				for (var count:uint=0; count<elements.length; count++) {
					var currentElement:TimelineElement=elements[count] as TimelineElement;
					if (currentElement!=null) {
						currentElement.onBeaconTick(beaconTime, beaconDate);
					}//if
				}//for
			} else if (this._beacon is VideoDisplayComponent) {
				//Ensures that timer will fire off as 0 (not streaming value), so that startup elements
				//can be invoked without the stream(s) needing to exist.
				streamTime=0;
				try {				
					if (VideoDisplayComponent(this._beacon).streamConnection!=null) {
						if (VideoDisplayComponent(this._beacon).streamConnection is SwagCloud) {
							if (VideoDisplayComponent(this._beacon).streamConnection.stream!=null) {
								streamTime=VideoDisplayComponent(this._beacon).streamConnection.stream.time;	
							}//if
						} else if (VideoDisplayComponent(this._beacon).streamConnection is NetStream) {
							streamTime=VideoDisplayComponent(this._beacon).streamConnection.time;
						}//else
					}//if
				} catch (e:*) {					
				}//catch
				beaconTime=new SwagTime();
				beaconTime.totalMilliseconds=uint(streamTime*1000);
				beaconDate=new SwagDate();
				for (count=0; count<elements.length; count++) {
					currentElement=elements[count] as TimelineElement;
					if (currentElement!=null) {
						currentElement.onBeaconTick(beaconTime, beaconDate);
					}//if
				}//for
			} else {
				//No valid beacon!
				this.stop(false);
				return;
			}//else
			if (this._storedTime!=null) {
				if (this._storedTime.totalMilliseconds==beaconTime.totalMilliseconds) {
					this.stop(true);
				}//if
			}//if
			this._storedTime=new SwagTime();
			this._storedTime.totalMilliseconds=beaconTime.totalMilliseconds;
		}//onBeaconTimer
		
		/**
		 * Removes a <code>TimelineElement</code> from this <code>Timeline</code> instance.
		 * 
		 * @param elementRef A reference to the <code>TimelineElement</code> element to remove from the timeline.
		 * 
		 * @return <em>True</em> if the element was successfully removed, <em>false</em> otherwise (for example,
		 * it couldn't be found).
		 * 
		 */
		public function removeElement(elementRef:TimelineElement):Boolean {
			var parsedElements:Vector.<TimelineElement>=new Vector.<TimelineElement>();
			var elementRemoved:Boolean=false;
			for (var count:uint=0; count<_elements.length; count++) {
				var currentElement:TimelineElement=_elements[count] as TimelineElement;
				if ((currentElement!=null) && (currentElement!=elementRef)) {
					parsedElements.push(currentElement);
					elementRemoved=true;
				}//if
			}//for
			_elements=parsedElements;
			this.sortElements();
			return (elementRemoved);
		}//removeElement
		
		/**
		 * Adds an element to the timeline. See the <code>TimelineElement</code> structure
		 * for valid XML. If calling the <code>broadcastElement</code> method with the
		 * <code>add</code> parameter set to <em>true</em>, do not call this method
		 * as it will result in duplicate Timeline items (unless this is desired).
		 *  
		 * @param elementData Valid <code>TimelineElement</code> XML instantiation data.
		 *  
		 * @return A newly added and sorted <code>TimelineElement</code> instance, or <em>null</em> if
		 * one can't be added (for example, bad XML). 
		 * 
		 */
		public function addElement(elementData:XML):TimelineElement {
			if (elementData==null) {
				return (null);
			}//if
			if (elementData.localName()!="element") {
				return (null);
			}//if
			var newElement:TimelineElement=new TimelineElement(this, elementData);
			_elements.push(newElement);
			this.sortElements();
			return (newElement);
		}//addElement
		
		/**
		 * Adds an element to the Timeline's broadcast queue to be dispatched via the
		 * Announce Channel as soon as available.
		 *  
		 * @param elementData Valid <code>TimelineElement</code> XML instantiation data.
		 * @param sendImmediate If <em>true</em> (default), the element is attempted to be sent immediately,
		 * otherwise the Announce Channel's <code>broadcastLiveTimeline</code> method must be invoked for the
		 * element to be sent.
		 * @param add If <em>true</em> (default), this element to be queued for broadcast is also
		 * added to the Timeline via the <code>addElement</code> method (useful for simultaneous 
		 * playback and broadcast control).
		 * 
		 * @return A newly created <code>TimelineElement</code> instance, or <em>null</em> if
		 * one can't be created.  
		 * 
		 */
		public function broadcastElement(elementData:XML, sendImmediate:Boolean=true, add:Boolean=true):TimelineElement {
			if (elementData==null) {
				return (null);
			}//if
			var newElement:TimelineElement=new TimelineElement(this, elementData);
			if (add==true) {
				_elements.push(newElement);
				this.sortElements();
			}//if
			broadcastElementsQueue.push(newElement);
			if (sendImmediate==true) {
				if (References.announceChannel!=null) {
					References.announceChannel.broadcastLiveTimeline(this);
				}//if
			}//if
			return (newElement);
		}//broadcastElement
		
		/**
		 * @return A list of elements queued for broadcast, typically by the Announce Channel, to broadcast
		 * to subscribed peers.		 
		 */
		public function get broadcastElementsQueue():Vector.<TimelineElement> {
			if (this._broadcastElementsQueue==null) {
				this._broadcastElementsQueue=new Vector.<TimelineElement>();
			}//if
			return (this._broadcastElementsQueue);
		}//get broadcastElementsQueue
		
		/**
		 * @return Used by the announce channel to match the Timeline instance to a <code>SwagCloud</code>
		 * instance. Timeline events and management should be done through the announce channel. 
		 */
		public function get announceChannelCloud():SwagCloud {
			return (this._announceChannelCloud);
		}//get announceChannelCloud
		
		public function set announceChannelCloud(connectionSet:SwagCloud):void {
			this._announceChannelCloud=connectionSet;
		}//set announceChannelCloud
		
		/**
		 * @private 		 
		 */
		private function sortElements():void {
			_elements=_elements.sort(this.elementSortMethod);
		}//sortElements
		
		/**
		 * @private 		 
		 */
		private function elementSortMethod(element1:TimelineElement, element2:TimelineElement):Number {
			if (element2.date.isLater(element1.date)) {
				return (-1);
			}//if
			if (element1.date.isLater(element2.date)) {
				return (1);
			}//if			
			if (element1.date.isSame(element2.date)) {
				if (element2.time.isAfter(element1.time)) {
					return (-1);
				}//if
				if (element1.time.isAfter(element2.time)) {
					return (-1);
				}//if
			}//if
			return (0);
		}//elementSortMethod
		
		/**
		 * @return The beacon object associated with the <code>Timeline</code>. This is the object that
		 * the timeline monitors for playback progress. Currently supported beacon types include:
		 * <code>VideoDisplayComponent</code>, <em>null</em> (uses the Flash timer delta).		 
		 */
		public function get beacon():* {
			return (this._beacon);
		}//get beacon
		
		public function set beacon(beaconSet:*):void {
			this._beacon=beaconSet;
		}//set beacon
		
		/**
		 * @return The rate, in milliseconds, at which the timeline samples the <code>beacon</code>.		 
		 */
		public function get sampleRate():int {
			return (this._sampleRate);
		}//get sampleRate
		
		/**
		 * @return The number of milliseconds that are allowed to elapse between when a timeline element 
		 * was supposed to have been triggered and the current time. If that element has a "low" priority
		 * and this number of milliseconds has already elapsed since it was to be triggered, it's discarded.
		 */
		public function get missedElementDiscardTimeout():int {
			return (this._missedElementDiscardTimeout);
		}//get missedElementDiscardTimeout
		
		public function set missedElementDiscardTimeout(timeoutSet:int):void {
			this._missedElementDiscardTimeout=timeoutSet;
		}//set missedElementDiscardTimeout
		
		/**
		 * @return The <code>TimelineElement</code>s associated with this <code>Timeline</code> instance.		 
		 */
		public function get elements():Vector.<TimelineElement> {
			if (_elements==null) {
				_elements=new Vector.<TimelineElement>();
			}//if
			_elements.fixed=false;
			return (_elements);
		}//get elements
		
		/**
		 * @return All the <code>Timeline</code> instances currently in memory.		 
		 */
		public static function get timelines():Vector.<Timeline> {
			if (_timelines==null) {
				_timelines=new Vector.<Timeline>();
			}//if
			return (_timelines);
		}//get timelines
		
		/**
		 * Finds a specific <code>Timeline</code> instance for a specific source object.
		 *  
		 * @param targetObject The source, or target object that acts as a beacon for the timeline.
		 * 
		 * @return The <code>Timeline</code> instance associated with the source object, or <em>null</em> if
		 * none can be found.
		 * 
		 */
		public static function findTimelineFor(targetObject:*):Timeline {
			if (timelines.length==0) {
				return (null);
			}//if
			for (var count:uint=0; count<timelines.length; count++) {
				var currentTimeline:Timeline=timelines[count] as Timeline;
				if (currentTimeline!=null) {
					if (currentTimeline.beacon==targetObject) {
						return (currentTimeline);
					}//if
				}//if
			}//for
			return (null);
		}//findTimelineFor
		
		/**
		 * Starts the live timeline. This initiates a sampling of the live stream or other beacon object
		 * to determine the number of elapsed milliseconds. On each sample, active <code>Timeline</code>
		 * objects are updated to invoke individual timeline elements (if ready).
		 */
		public function start():void {
			References.debug("Timeline: Beginning stream sampling at "+String(this._sampleRate)+"ms");
			if (this._beaconTimer!=null) {
				this._beaconTimer.removeEventListener(TimerEvent.TIMER, this.onBeaconTimer);
				this._beaconTimer.stop();
				this._beaconTimer=null;
			}//if
			this._timerStartDelta=getTimer(); //Used when beacon is null (flash timer), ignored otherwise.
			this._beaconTimer=new Timer(this._sampleRate, 0);
			this._beaconTimer.addEventListener(TimerEvent.TIMER, this.onBeaconTimer);
			this._beaconTimer.start();
		}//start
		
		/**
		 * Stops the live timeline. This does not remove the timeline or its data from memory, it simply stops
		 * sampling the source beacon.
		 * 
		 * @param 	 
		 */
		public function stop(includeStopElement:Boolean=false):void {
			if (this._beaconTimer!=null) {
				this._beaconTimer.removeEventListener(TimerEvent.TIMER, this.onBeaconTimer);
				this._beaconTimer.stop();
				this._beaconTimer=null;
			}//if
			if (includeStopElement) {
				var elementData:XML=TimelineElement.create(TimelineInvokeConstants.VIDEO_STOP_RECSTREAM, this._storedTime.toString(), "", "high", null, false);
				var stopElement:TimelineElement=new TimelineElement(this, elementData);
				stopElement.invoke(this._storedTime, null, true);
			}//if
		}//stop
		
		/**
		 * Pauses the live timeline.
		 */
		public function pause():void {
			if (this._beaconTimer!=null) {
				this._beaconTimer.stop();
			}//if
		}//pause
		
		/**
		 * Resumes the live timeline.
		 */
		public function resume():void {
			if (this._beaconTimer!=null) {
				this._beaconTimer.start();
			}//if
		}//resume
		
		/**
		 * @return The complete current <code>Timeline</code> object as an XML object.
		 */
		public function toXML():XML {
			var channel:String="";
			if (this._announceChannelCloud!=null) {
				channel=this._announceChannelCloud.groupName;
			}//if
			var timelineXML:XML=new XML("<livetimeline />");
			for (var count:uint=0;count<elements.length; count++) {
				var currentElement:TimelineElement=elements[count] as TimelineElement;
				if (currentElement!=null) {
					timelineXML.appendChild(currentElement.elementData);
				}//if
			}//for
			return (timelineXML);
		}//toXML
		
		/**
		 * @return The complete current <code>Timeline</code> object as an XML-formatted string.
		 */
		public function toXMLString():String {
			var channel:String="";
			if (this._announceChannelCloud!=null) {
				channel=this._announceChannelCloud.groupName;
			}//if
			var timelineXML:XML=new XML("<livetimeline />");
			for (var count:uint=0;count<elements.length; count++) {
				var currentElement:TimelineElement=elements[count] as TimelineElement;
				if (currentElement!=null) {
					timelineXML.appendChild(currentElement.elementData);
				}//if
			}//for
			return (timelineXML.toXMLString());
		}//toXMLString
		
	}//Timeline class
	
}//package