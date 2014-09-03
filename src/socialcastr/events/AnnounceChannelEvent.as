package socialcastr.events {	
	
	/**
	 * Event object broadcast from the <code>AnnounceChannel</code> class to announce various updates and state changes within the class.
	 * <p>Subscribe to the event types listed here for global Announce Channel support.</p>
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
	import swag.events.SwagEvent;
	import swag.events.SwagCloudEvent;
	import socialcastr.core.Timeline;
	public class AnnounceChannelEvent extends SwagEvent	{
		
		/**
		 * Broadcast when the Announce Channel connects. The SCID and CCID are available after this event is broadcast.
		 */
		public static const ONCONNECT:String="SwagEvent.AnnounceChannelEvent.ONCONNECT";
		/**
		 * Broadcast when the Announce Channel connects to or establishes a shared / distributed data connection on a
		 * <code>SwagCloud</code> instance.
		 */
		public static const ONSHARECONNECT:String="SwagEvent.AnnounceChannelEvent.ONSHARECONNECT";
		/**
		 * Broadcast when the Announce Channel has completed gathering shared / distributed data on a
		 * <code>SwagCloud</code> instance.
		 */
		public static const ONSHAREGATHER:String="SwagEvent.AnnounceChannelEvent.ONSHAREGATHER";
		/**
		 * Broadcast when the Announce Channel has gathered a chunk of data from the distributed / shared connection
		 * on a <code>SwagCloud</code> instance.
		 */
		public static const ONSHAREPROGRESS:String="SwagEvent.AnnounceChannelEvent.ONSHAREPROGRESS";
		/**
		 * Broadcast whenever information for an AV channel is received, typically as a response to the <code>AnnounceChannelrequestAVChannels</code> call.
		 * It's possible for a peer to send the same message multiple times so this cloudEvent's <code>remotePeerID</code> property should be checked
		 * for uniqueness.   
		 */
		public static const ONAVCHANNELINFO:String="SwagEvent.AnnounceChannelEvent.ONAVCHANNELINFO";
		/**
		 * Broadcast when a Live Timeline channel is connected through the Announce Channel. Typically used by channel receivers.  
		 */
		public static const ONLIVETIMELINECONNECT:String="SwagEvent.AnnounceChannelEvent.ONLIVETIMELINECONNECT";
		/**
		* Broadcast when a Live Timeline channel is registered through the Announce Channel. Typically used by channel broadcasters.
		*/
		public static const ONLIVETIMELINEREG:String="SwagEvent.AnnounceChannelEvent.ONLIVETIMELINEREG";
		/**
		 * Broadcast when a Live Timeline channel fails to register through the Announce Channel. Typically used by channel broadcasters and
		 * most frequently occurs when the Live Timeline channel has already been established (some else is using it).
		 */
		public static const ONLIVETIMELINEREGFAIL:String="SwagEvent.AnnounceChannelEvent.ONLIVETIMELINEREGFAIL";
		/**
		 * Broadcast whenever a timeline element or a timeline (group of elements) is received for the connected channel.   
		 */
		public static const ONLIVETIMELINE:String="SwagEvent.AnnounceChannelEvent.ONLIVETIMELINE";
		/**
		 * Broadcast whenever a new AV channel is connected. The associated channel information is included with the <code>channelInfo</code> object.
		 * It's possible for a peer to send the same message multiple times so this cloudEvent's <code>remotePeerID</code> property should be checked
		 * for uniqueness. 
		 */
		public static const ONAVCHANNELCONNECT:String="SwagEvent.AnnounceChannelEvent.ONAVCHANNELCONNECT";
		/**
		 * Broadcast whenever an AV channel is disconnected. No further requests to the associated channel should be issued. 
		 */
		public static const ONAVCHANNELDISCONNECT:String="SwagEvent.AnnounceChannelEvent.ONAVCHANNELDISCONNECT";
		/**
		 * Broadcast when the AnnounceChannel disconnects. This may happen either as a result of user interaction or because the connection
		 * was otherwise dropped, but no further channel interaction with any channels should take place. 
		 */
		public static const ONDISCONNECT:String="SwagEvent.AnnounceChannelEvent.ONDISCONNECT";
		
		/**
		 * Contains the information of the channel associated with the event being broadcast.   
		 */
		public var channelInfo:Object=null;
		/**
		 * Contains the original transaction information associated with the response (the original <code>SwagCloudEvent</code> event that created
		 * the AnnounceChannelEvent).  
		 */
		public var cloudEvent:SwagCloudEvent=null;
		/**
		 * Contains a reference to the <code>Timeline</code> object associated with this Announce Channel broadcast. This
		 * value is <em>null</em> if no <code>Timeline</code> instance is associated with the event.
		 */
		public var timeline:Timeline=null;
		
		
		public function AnnounceChannelEvent(eventType:String=null)	{
			super(eventType);
		}//constructor
		
	}//AnnounceChannelEvent class
	
}//package