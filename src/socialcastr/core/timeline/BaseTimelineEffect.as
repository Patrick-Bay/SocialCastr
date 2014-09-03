package socialcastr.core.timeline {
	
	import flash.net.NetStream;
	
	import socialcastr.References;
	import socialcastr.core.AnnounceChannel;
	import socialcastr.core.Timeline;
	import socialcastr.core.TimelineElement;
	import socialcastr.core.timeline.TimelineInvokeConstants;
	import socialcastr.events.TimelineEvent;
	import socialcastr.interfaces.core.timeline.IBaseTimelineEffect;
	import socialcastr.ui.components.VideoDisplayComponent;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.instances.SwagDate;
	import swag.core.instances.SwagTime;
	import swag.network.SwagCloud;
	
	/**
	 * A base class to extend to easily produce Timeline audio / video effects. The extending class acts as both receiver and broadcaster for effects
	 * and so is expected to manage its own payload (XML) data.
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
	public class BaseTimelineEffect implements IBaseTimelineEffect	{
		
		private var _effectTarget:*;
				
		public function BaseTimelineEffect(effectTarget:*) {
			this._effectTarget=effectTarget;
			if (effectTarget!=null) {
				SwagDispatcher.addEventListener(TimelineEvent.INVOKE, this.onTimelineInvoke, this);
			}//if			
		}//constructor
		
		/**
		 * @return The target object that the timeline effect is to control. Recognized types are specified by extending classes.		 
		 */
		public function get target():* {
			return (this._effectTarget);
		}//get target
		
	 	public function onTimelineInvoke(eventObj:TimelineEvent):void {
			trace ("BaseTimelineEffect.onTimelineInvoke must be overriden in extending class. Removing from event chain.");
			//This function will be called on any timeline event and should trigger the appropriate action in the effect.
			//Be sure to check the eventObj.invoke property against all of the valid TimelineInvokeConstants constants.
			//Note that if the effect payload changes (new version, for example), it must be accomodated
			//for in this function.
			this.destroy();
		}//onTimelineInvoke
		
		/**
		 * Creates a valid timeline element XML object for the Timeline effect.
		 * 
		 * @param effectType The type of effect to create. Currently accepted types are "video" and "audio".
		 * @param effectName The name of the effect (included in the XML in the "name" attribute.
		 * @param effectVersion The effect version in standard "major.minor" notation (for example, "1.0").
		 * @param streamOffsetTime An optional stream offset time, in milliseconds, to trigger the action at. Leaving this as the
		 * default value (-1), causes the timeline effect to seek for an offset time within recognized types assigned
		 * to the <code>target</code> property. If 0 is specified, the effect is issued immediately. Otherwise,
		 * values such as the NetStream.time value (multiplied by 1000) can be used to specify an offset within the stream to 
		 * synchronize the effect to.
		 * 
		 * @return A valid timeline element XML object, of <em>null</em> if one couldn't be created. 
		 * 
		 */
		public function createTimelineEffectXML(effectType:String, effectName:String, effectVersion:String, streamOffsetTime:int=-1):XML {
			if ((effectType==null) || (effectName==null) || (effectVersion==null)) {
				return(null);
			}//if
			if ((effectType=="") || (effectName=="")) {
				return(null);
			}//if
			effectType=new String(effectType);
			effectType=effectType.toLowerCase();
			//The effect name is case sensitive!
			var	payloadXML:XML=new XML("<"+effectType+" name=\""+effectName+"\" version=\""+effectVersion+"\"/>");
			var currentTime:SwagTime=new SwagTime();
			currentTime.totalMilliseconds=0;
			var currentDate:SwagDate=new SwagDate();
			if (this.target is VideoDisplayComponent) {				
				if (streamOffsetTime<0) {
					if (this.target.streamConnection is SwagCloud) {
						var cloudInstance:SwagCloud=this.target.streamConnection as SwagCloud;
						if (cloudInstance!=null) {						
							if (cloudInstance.stream!=null) {							
								if (cloudInstance.stream.time>0) {							
									currentTime.totalMilliseconds=cloudInstance.stream.time;								
								}//if
							}//if	
						}//if
					} else if (this.target.streamConnection is NetStream){
						var streamInstance:NetStream=this.target.streamConnection as NetStream;
						if (streamInstance!=null) {													
							if (streamInstance.time>0) {							
								currentTime.totalMilliseconds=streamInstance.time;								
							}//if	
						}//if
					}//else
				} else {					
					currentTime.totalMilliseconds=uint(streamOffsetTime);
				}//else
			}//if						
			var element:XML=TimelineElement.create(
				TimelineInvokeConstants.VIDEO_EFFECT_START, 
				currentTime.toString(), 
				currentDate.toString(), 
				"high", 
				payloadXML);
			return (element);
		}//createTimelineEffectXML
		
		/**
		 * Verifies that the effect specified in the payload XMLList matches the supplied specifications.
		 *  
		 * @param payloadXML The payload XMLList to analyze.
		 * @param effectType The effect type to match. This is the node name of the first payload node and is not case sensitive.
		 * @param effectName The effect name to match. This is the "name" attribute and is case sensitive.
		 * @param effectVersion The effect version to match. Standard version numbers are accepted but only the major and minor
		 * revision numbers are compared.
		 * 
		 * @return <em>True</em> if the effect was verified within the first node of the payload XMLList, <em>false</em> otherwise.
		 * 
		 */
		public function verifyEffect(payloadXML:XMLList, effectType:String, effectName:String, effectVersion:String):Boolean {
			if (payloadXML==null) {
				return (false);
			}//if
			try {
				var effectNode:XML=payloadXML[0] as XML;
				if (effectNode==null) {
					return (false);
				}//if
			} catch (e:*) {
				return (false);
			}//catch
			effectType=new String(effectType);
			effectType=effectType.toLowerCase();
			var effectNodeType:String=new String(effectNode.localName());
			effectNodeType=effectNodeType.toLowerCase();
			if (effectNodeType!=effectType) {
				return (false);
			}//if
			//The effect name is case sensitive!
			if (!SwagDataTools.isXML(effectNode.@name)) {
				return (false);
			}//if
			var effectNameAttribute:String=new String(effectNode.@name);
			if (effectNameAttribute!=effectName) {
				return (false);
			}//if
			if (!SwagDataTools.isXML(effectNode.@version)) {
				return (false);
			}//if
			var verifyVersionObj:Object=SwagDataTools.parseVersionString(effectVersion);
			var versionNodeObj:Object=SwagDataTools.parseVersionString(effectNode.@version);
			if (verifyVersionObj.major!=versionNodeObj.major) {
				return (false);
			}//if
			if (verifyVersionObj.minor!=versionNodeObj.minor) {
				return (false);
			}//if
			return (true);
		}//verifyEffect
		
		/**
		 * @return The <code>Timeline</code> object associated with the timelnie effect, or <em>null</em> if none can be found.		 
		 */
		public function get targetTimeline():Timeline {
			return (Timeline.findTimelineFor(this.target));
		}//get targetTimeline
		
		/**
		 * Adds the timeline effect to the specified timeline.
		 *  
		 * @param timeline The <code>Timeline</code> instance to add the effect to.
		 * 
		 */
		public function addToTimeline(timeline:Timeline):void {
			//Override this function to add the effect's XML payload to the host Timeline via its
			//"addElement" method. Obviously the effect settings should all be set at this point.			
		}//addToTimeline
		
		/**
		 * Stops the timeline effect removes any event listeners, and cleans up after itself as best as it can.
		 */
		public function destroy():void {
			SwagDispatcher.removeEventListener(TimelineEvent.INVOKE, this.onTimelineInvoke);
			this._effectTarget=null;
		}//destroy
		
	}//BaseTimelineEffect class
	
}//package