package socialcastr.core {
	
	import flash.utils.getTimer;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.core.Timeline;
	import socialcastr.events.TimelineEvent;
	import socialcastr.interfaces.core.ITimeline;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.instances.SwagDate;
	import swag.core.instances.SwagTime;
	
	/**
	 * Manages a specific timeline element. When a specific time interval has been achieved,
	 * a <code>TimelineElement</code> instance broadcasts a SwAG-based <code>TimelineEvent</code>
	 * to any listeners.
	 * 
	 * Some initial default XML values define start instructions for the channel. These are
	 * required since, if a timeline is present, it is assumed to be controlling the associated
	 * video and audio streams, including when they start and stop. Note the "high" priority
	 * attribute which specifies that the instruction must be carried out as soon as the timeline
	 * has reached that time, even if it's been missed.
	 * 
	 * <element invoke="SocialCastr.AV:default_video_start" time="00:00:00:00" date="" priority="high" static="true"/>
	 * <element invoke="SocialCastr.AV:default_audio_start" time="00:00:00:00" date="" priority="high" static="false"/>
	 * 
	 * Special attention should be paid to capitalization and spacing. Since timeline data is assumed
	 * to be internally generated, it is typically not checked for validity, etc.
	 * 
	 * This creation and management of <code>TimelineElement</code> instance is managed by
	 * a <code>Timeline</code> instance.
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
	public class TimelineElement implements ITimeline	{
		
		private var _parentTimeline:Timeline=null;
		private var _localTime:SwagTime=null;
		private var _localDate:SwagDate=null;
		private var _elementData:XML=<element invoke="" time="00:00:00:00" date="" priority="low" static="false"/>;
		private var _invoked:Boolean=false;
		
		public function TimelineElement(parentTimeline:Timeline, elementData:XML)	{
			this._parentTimeline=parentTimeline;
			if (elementData!=null) {
				this._elementData=elementData;
			}//if
		}//constructor
		
		/**
		 * Method typically invoked by the parent <code>Timeline</code> object on every beacon interval.
		 *  
		 * @param elapsedTime A <code>SwagTime</code> object containing the amount of time elapsed (from start of broadcast).
		 * @param elapsedDate A <code>SwagDate</code> object containing the date invocation.
		 * 
		 */
		public function onBeaconTick(elapsedTime:SwagTime, elapsedDate:SwagDate):void {
			this.broadcastInvocation(elapsedTime, elapsedDate);
		}//onBeaconTick
		
		/**
		 * @private
		 */
		private function broadcastInvocation(elapsedTime:SwagTime, elapsedDate:SwagDate):void {
			if (this._invoked) {
				return;
			}//if
			if (elapsedTime.isAfter(this.time) || elapsedTime.isSame(this.time)) {
				if (this.isPriority("low")) {
					if (elapsedTime.compareTimes(this.time).totalMilliseconds>this._parentTimeline.missedElementDiscardTimeout) {
						this.destroy();
						return;
					}//if
				}//if
				//TODO: add date checking (for multi-day broadcasts)
				this.invoke(elapsedTime, elapsedDate);				
			}//if
		}//broadcastInvocation
		
		/**
		 * Invokes the <code>TimelineElement</code> to broadcast a "TimelineEvent.INVOKE" event. 
		 * 
		 * @param elapsedTime A <code>SwagTime</code> object containing the amount of time elapsed (from start of broadcast).
		 * @param elapsedDate A <code>SwagDate</code> object containing the date invocation.
		 * @param remove An element, once invoked, is automatically removed from the timeline unless this parameter is
		 * <em>true</em>, or the element is static.
		 * 
		 */
		public function invoke(elapsedTime:SwagTime=null, elapsedDate:SwagDate=null, remove:Boolean=true):void {
			var event:TimelineEvent=new TimelineEvent(TimelineEvent.INVOKE);
			event.invoke=this.invocation;			
			event.elapsedTime=elapsedTime;
			event.elapsedDate=elapsedDate;
			event.elementData=this.elementData;
			event.payload=this.elementData.children();
			event.target=this._parentTimeline.beacon;
			SwagDispatcher.dispatchEvent(event, this);
			if (remove) {
				this.destroy();
			}//if
		}//invoke
		
		/**
		 * Validates the priority setting against the priorities set for this <code>TimelineElement</code> instance.
		 * Priorities are semi-colon (;) separated and are typically included with the element XML data as the
		 * "priority" attribute.
		 *  
		 * @param priorityType The priority type to match against this <code>TimelineElement</code> (for example,
		 * "high" or "low").
		 * 
		 * @return <em>True</em> if the specified priority is associated with this <code>TimelineElement</code> instance,
		 * <em>false</em> oterwise.
		 * 
		 */
		public function isPriority(priorityType:String):Boolean {
			if ((priorityType==null) || (priorityType=="")) {
				return (false);
			}//if
			var typeString:String=new String(priorityType);
			typeString=typeString.toLowerCase();
			typeString=SwagDataTools.stripOutsideChars(typeString, SwagDataTools.SEPARATOR_RANGE);
			if (SwagDataTools.isXML(this._elementData.@priority)) {
				var priorityTypes:String=new String(this._elementData.@priority);
				var prioritySplit:Array=priorityTypes.split(";");
				for (var count:uint=0; count<prioritySplit.length; count++) {
					var currentPriority:String=new String(prioritySplit[count] as String);
					currentPriority=currentPriority.toLowerCase();
					currentPriority=SwagDataTools.stripOutsideChars(currentPriority, SwagDataTools.SEPARATOR_RANGE);
					if (currentPriority==typeString) {
						return (true);
					}//if
				}//for
			}//if
			return (false);
		}//isPriority
		
		/**
		 * @return <em>True</em> if the element is static (shouldn't be removed after invocation), oe <em>false</em> if not.
		 * Static elements are invoked as other elements but aren't removed from the timeline once done. This allows them to
		 * remain on the timeline (to be broadcast to external sources, for example).
		 * <p>The static property can be found as the "static" attribute in the associated XML data, and defaults to <em>false</em>
		 * if not present or not correctly formatted.</p>		 
		 */
		public function get isStatic():Boolean {
			if (SwagDataTools.isXML(this._elementData.@static)==false) {
				return (false);
			}//if
			var staticString:String=new String(this._elementData.@static);
			staticString=staticString.toLowerCase();
			staticString=SwagDataTools.stripOutsideChars(staticString, SwagDataTools.SEPARATOR_RANGE);
			if ((staticString=="true") || (staticString=="t") || (staticString=="yes") || (staticString=="on") || (staticString=="1")) {
				return (true);
			}//if
			return (false);
		}//get isStatic
		
		/**
		 * @return The trigger time associated with this <code>TimelineElement</code> object as a <code>SwagTime</code> object.		 
		 */
		public function get time():SwagTime {
			if (this._localTime==null) {
				var timeString:String=new String("00:00:00:00");
				if (SwagDataTools.isXML(this._elementData.@time)) {
					timeString=new String(String(this._elementData.@time));
				}//if
				this._localTime=new SwagTime(timeString);
			}//if
			return (this._localTime);
		}//get time
		
		/**
		 * @return The trigger date associated with this <code>TimelineElement</code> object as a <code>SwagDate</code> object.		 
		 */
		public function get date():SwagDate {
			if (this._localDate==null) {
				if (SwagDataTools.isXML(this._elementData.@date)) {
					var dateString:String=new String(String(this._elementData.@date));
					this._localDate=new SwagDate(dateString);
				} else {
					this._localDate=new SwagDate();
				}//else
			}//if
			return (this._localDate);
		}//get date
		
		/**
		 * Creates a basic XML object containing the default structure to create a <code>TimelineElement</code> object with.
		 * Use this method instead of creating custom XML objects to avoid re-writing code should the format ever change.
		 *  
		 * @param invokeString The invocation string, either a custom value or a constant from the <code>TimelineInvokeConstants</code> class.
		 * @param timeString An initial time value, in the format "00:00:00.0" (hours:minutes:seconds.mseconds), to assign to the default
		 * element data.
		 * @param dateString An initial time value, in the standard Date.toString() format, to assign to the default
		 * element data.
		 * @param priority The priority setting(s) to include with the default XML data. Multiple settings should be separated with
		 * a semicolon (;).
		 * @param payload Additional payload data, as an XML object, to include with the default "element" XML node as a child node.
		 * @param static <em>True</em> if the new element is to be static (stay on the timeline after invocation), or <em>false</em>. Static
		 * elements are invoked just once like all other elements but will remain on the timeline (to broadcast to external sources, for example).
		 * 
		 * @return The valid, properly formatted XML object representing a <code>TimelineElement</code> oject which can subsequently
		 * be used to create an instance of a <code>TimelineElement</code>.
		 * 
		 */
		public static function create(invokeString:String, timeString:String, dateString:String, priority:String, payload:XML=null, static:Boolean=false):XML {
			var elementXML=new XML("<element invoke=\"\" time=\"\" date=\"\" priority=\"\" static=\"\" />");
			elementXML.@invoke=invokeString;
			elementXML.@time=timeString;
			elementXML.@date=dateString;
			elementXML.@priority=priority;
			if (static) {
				elementXML.@static="true";	
			} else {
				elementXML.@static="false";
			}//else
			if (payload!=null) {
				elementXML.appendChild(payload);
			}//if
			return (elementXML);
		}//create
		
		/**		 
		 * @return The invocation string that will trigger this timeline element at the specific time / date. 		 
		 */
		public function get invocation():String {
			var returnString:String=new String();
			if (SwagDataTools.isXML(this._elementData.@invoke)) {
				returnString=new String(this._elementData.@invoke);
			}//if
			return (returnString);
		}//get invocation
		
		/**
		 * @return The XML data object associated with the <code>TimelineElement</code> instance. The format should match that
		 * output from the <code>create</code> method.		 
		 */
		public function get elementData():XML {
			return (this._elementData);
		}//get elementData
		
		/**
		 * Flags the <code>TimelineElement</code> as invoked, and requests the parent timeline to remove itself. 
		 */
		public function destroy():void {
			this._invoked=true;	
			References.debug ("   Called TimelineElement.destroy. Is static? "+this.isStatic);
			if (!this.isStatic) {
				this._parentTimeline.removeElement(this);
			}//if
		}//destroy
		
	}//TimelineElement class
	
}//package