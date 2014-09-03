package swag.events {
	
	import swag.events.SwagEvent;
	import swag.interfaces.events.ISwagCloudEvent;
	import swag.network.SwagCloudData;
	import swag.network.SwagCloudShare;
	
	/**
	 * Event type broadcast from a <code>SwagCloud</code> to notify the application of various states of connectivity and
	 * data transfer. This class also carries a variety of properties that may be accessed for extended information related
	 * to various group activity.
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
	public class SwagCloudEvent extends SwagEvent implements ISwagCloudEvent	{
		
		/**
		 * This event is dispatched when the initial connection is made to the Cirrus server.
		 * <p>The local peer ID (the ID of this connection), is created and stored with this event.</p>
		 * <p>A single connection is used for all groups so this event should only ever be broadcast once
		 * per session per application.</p> 
		 */
		public static const CONNECT:String="SwagEvent.SwagCloudEvent.CONNECT";
		/**
		 * This event is dispatched when the main connection is closed.
		 * <p>No further netgroup or streaming operations will be available after this.</p> 
		 */
		public static const DISCONNECT:String="SwagEvent.SwagCloudEvent.DISCONNECT";
		/**
		 * Dispatched whenever the associated group is successfully created and authorized.
		 */
		public static const GROUPCONNECT:String="SwagEvent.SwagCloudEvent.GROUPCONNECT";
		/**
		 * Dispatched whenever the associated group could not be connected to (usually a network or
		 * connectivity issue).
		 */
		public static const GROUPCONNECTFAIL:String="SwagEvent.SwagCloudEvent.GROUPCONNECTFAIL";
		/**
		 * Dispatched whenever the peer is disconnected from the associated group. Because groups are stateless
		 * (new peers initiate connections), there is no real way to disconnect the group except by closing
		 * the connection altogether.
		 */
		public static const GROUPDISCONNECT:String="SwagEvent.SwagCloudEvent.GROUPDISCONNECT";
		/**
		 * Dispatched whenever a group join request has been rejected.
		 */
		public static const GROUPREJECT:String="SwagEvent.SwagCloudEvent.GROUPREJECT";
		/**
		 * Dispatched whenever a remote peer connects to the associated group.
		 * <p>The newly attached peer ID is sent in this event and stored in the <code>SwagP2PCloud</code> instance's
		 * <code>peerList</code> array in the order in which it's attached.</p> 
		 */
		public static const PEERCONNECT:String="SwagEvent.SwagCloudEvent.PEERCONNECT";
		/**
		 * Dispatched whenever a remote peer disconnects to the associated group.
		 * <p>The peer ID is automatically removed from the associated <code>SwagP2PCloud</p>'s <code>peerList</code> array.</p> 
		 */
		public static const PEERDISCONNECT:String="SwagEvent.SwagCloudEvent.PEERDISCONNECT";
		/**
		 * Dispatched when a message for the group is received.
		 * <p>This is the message type received through the NetGroup's <code>post</code> method.</p> 
		 */
		public static const BROADCAST:String="SwagEvent.SwagCloudEvent.BROADCAST";
		/**
		 * Dispatched when a message for this specific peer ID (node), is received.
		 * <p>In other words, this event is broadcast whenever a message sent directly to this node is received. Since messages may be sent
		 * through the peer cloud, it should not be assumed that the message was sent directly (via 1 hop), from sender to receiver.</p>
		 * This is the message type received through the NetGroup's <code>post</code> method.</p> 
		 */
		public static const DIRECT:String="SwagEvent.SwagCloudEvent.DIRECT"; 
		/**
		 * Dispatched when a new multicast stream is established published within the associated group and a notification
		 * to all group members has been made.
		 * <p>Each group may only carry one multicast stream so a new stream can only be opened if a previous one in the group is closed first. 
		 * <p>The stream name is included with the <code>streamID</code> property of the event. It's also associated with the 
		 * <code>mediaStreamName</code> property of the associated <code>SwagCloud</code> instance and the methods <code>playVideoStream</code> 
		 * and <code>playAudioStream</code> may be called without a parameter to start playing back this default stream (don't forget to attach 
		 * a video object if required first).</p>
		 */
		public static const STREAMPUBLISH:String="SwagEvent.SwagCloudEvent.STREAMPUBLISH"; 	
		/**
		 * Dispatched when a multicast stream to the group has been attempted but blocked because one already exists.
		 */
		public static const STREAMPUBLISHFAIL:String="SwagEvent.SwagCloudEvent.STREAMPUBLISHFAIL"; 	
		/**
		 * Dispatched when a multicast stream associated with the group begins playback.
		 * <p>Each group may only carry one multicast stream so a new stream can only be opened if a previous one in the group is closed first. 
		 * <p>The stream name is included with the <code>streamID</code> property of the event. It's also associated with the 
		 * <code>mediaStreamName</code> property of the associated <code>SwagCloud</code> instance and the methods <code>playVideoStream</code> 
		 * and <code>playAudioStream</code> may be called without a parameter to start playing back this default stream (don't forget to attach 
		 * a video object if required first).</p>
		 */
		public static const STREAMOPEN:String="SwagEvent.SwagCloudEvent.STREAMOPEN";
		/**
		 * Dispatched when a multicast stream associated with the group fails to begin playback (connection fails).		 
		 */
		public static const STREAMOPENFAIL:String="SwagEvent.SwagCloudEvent.STREAMOPENFAIL"; 	
		/**
		 * Dispatched when a multicast stream associated with the group is closed.
		 * <p>The stream name is included with the <code>streamID</code> property of the event.</p> 
		 */
		public static const STREAMCLOSED:String="SwagEvent.SwagCloudEvent.STREAMCLOSED";
		/**
		 * Dispatched when a multicast stream associated with the group is stopped (but not closed).
		 * <p>The stream name is included with the <code>streamID</code> property of the event.</p> 
		 */
		public static const STREAMSTOP:String="SwagEvent.SwagCloudEvent.STREAMSTOP";
		/**
		 * Dispatched when a multicast stream associated with the group is reset. 
		 * <p>The stream name is included with the <code>streamID</code> property of the event.</p> 
		 */
		public static const STREAMRESET:String="SwagEvent.SwagCloudEvent.STREAMRESET";
		/**
		 * Dispatched whenever a routing operation takes place.
		 * <p>Peer-to-peer routing allows messages to be sent efficiently through connected peers without broadcasting to the entire
		 * cloud group. This differs from relayed object replication in that the whole cloud group doesn't receive the message or is expected
		 * to relay it ad-hoc.</p>
		 * <p>The ROUTE event differs from the DIRECT event in that it denotes the receipt of a message not intended for this node. Relaying
		 * is done automatically but the data being relayed may be examined in transit.</p>
		 */
		public static const ROUTE:String="SwagEvent.SwagCloudEvent.ROUTE";
		/**
		 * Dispatched when a gather operation receives the initial info for the operation.
		 * <p>This includes information like the number of available chunks, chunk size, and total data size. This
		 * information is available throught the <code>cloudShare</cloud> object.</p> 
		 */		
		public static const GATHERINFO:String="SwagEvent.SwagCloudEvent.GATHERINFO";
		/**
		 * Dispatched when the distributed data shared by a peer via a <code>ditribute</code> command has been
		 * fully gathered.
		 * <p>The gathered data is automatically deserialized into the <code>data</code> object.</p>   
		 */		
		public static const GATHER:String="SwagEvent.SwagCloudEvent.GATHER";
		/**
		 * Dispatched when a distributed data chunk shared by a peer has been received gathered.
		 * <p>The partially collected data may be examined via the <code>cloudShare</code> object but
		 * may not be fully usable.</p>   
		 */		
		public static const CHUNK:String="SwagEvent.SwagCloudEvent.CHUNK";
		/**
		 * Dispatched when a distributed data chunk is requested by a peer.
		 * <p>This event will only be broadcast if this node has the requested data chunk available.</p>   
		 */		
		public static const CHUNKREQUEST:String="SwagEvent.SwagCloudEvent.CHUNKREQUEST";
		/**
		 * Dispatched when distribution info such as chunk size, number of chunks, and total data size,
		 * is requested by a peer.
		 * <p>The associated data can be accessed via the <code>cloudShare</code> reference.</p>   
		 */		
		public static const INFOREQUEST:String="SwagEvent.SwagCloudEvent.INFOREQUEST";
		
		/**
		 * The group ID associated with the <code>SwagP2PCloud</code> event. 
		 */
		public var groupID:String=null;
		/**
		 * The encrypted (hashed) source group ID of the sender if this message was sent directly from a group member. This contains
		 * the value of the NetStatusEvent.info.fromLocal property. In all other instances this value will be <em>null</em>
		 */		
		public var groupIDHash:String=null;		
		/**
		 * The local peer or node ID of this node (typically this application instance).  
		 */
		public var localPeerID:String=null;
		/**
		 * The cryptographic nonce used by the local peer to encrypt outbound messages. 
		 */		
		public var localPeerNonce:String=null;
		/**
		 * The peer ID returned by the Cirrus server when a connection is established. This should not changed during the session and
		 * typically has no practical use outside of handshaking as Cirrus acts primarily as a rendezvous service for connected peers. 
		 */		
		public var serverID:String=null;
		/**
		 * The cryptographic nonce associated with the server. 
		 */		
		public var serverNonce:String=null;
		/**
		 * The ID of the remote peer with which this event is associated. For example, if this is a PEERCONNECT event, this property will
		 * hold the ID of the peer being connected. This is typically stored with the <code>SwagCloud</code> instance and is used
		 * whenever a direct peer ID is required (for example, in a <code>send</code> operation.  
		 */		
		public var remotePeerID:String=null;
		/**
		 * The cryptographic nonce of the remote peer associated with this event. Flash typically handles the combination of the nonce,
		 * peer, and group IDs to route secure messages, but this value may be used if this is to be done directly. 
		 */
		public var remotePeerNonce:String=null;
		/**
		 * The status code associated with this event. This is typically the <code>code</code> value received in the <code>NetStatusEvent</code>
		 * object that cause this event to fire and indicates specifically what the <code>NetStatusEvent</code> object is reporting.
		 */		
		public var statusCode:String=null;
		/**
		 * The status level associated with this event. This is typically the <code>level</code> value received in the <code>NetStatusEvent</code>
		 * object that cause this event to fire. This will typically be either "status" or "error".
		 */		
		public var statusLevel:String=null;
		/**
		 * The cryptographic message ID of the received message. This is the hex value of the SHA256 of the serialized binary data of the message. 
		 */		
		public var messageID:String=null;
		/**
		 * The actual data (if any), received. Depending on the type of event, this object may be null. This is the referenced <code>data</code>
		 * property of the associated <code>SwagCloudData</code> instance used to hold the received data.
		 * <p>Generally, if only the data is required for an application, use this object instead of the <code>cloudData</code> reference
		 * as it's more direct.</p> 
		 */		
		public var data:*=null;
		/**
		 * The <code>SwagClouddata</code> instance containing peered cloud data . 
		 * This is the higher-level property of the <code>data</code> object which is set once the associated share has completed
		 * collecting all data.
		 */		
		public var cloudData:SwagCloudData=null;
		/**
		 * The <code>SwagCloudShare</code> instance containing the collated data (if completed), and in-transit data (being collected). 
		 * This is the higher-level property of the <code>data</code> object which is set once the associated share has completed
		 * collecting all data.
		 */		
		public var cloudShare:SwagCloudShare=null;
		
		//SendTo (DIRECT) message properties.
		/**
		 * Will be <code>true</code> if this was a relayed P2P message that has arrived at its final destination (this). If this is a message
		 * being relayed further, this property will be <code>false</code>. 
		 */
		public var fromLocal:Boolean=false;		
		/**
		 * The message ID associated with a distributed data chunk request. 
		 * <p>For operations not involving data replication, this value will always be 0.</p> 
		 */		
		public var requestID:int=0;
		/**
		 * The stream ID associated with this event. 
		 * <p>For operations not involving multicast streams and if none have been established with the associated <code>SwagCloud</code> instance,
		 * this value will always be null.</p> 
		 */		
		public var streamID:String=null;
		
		/**
		 * The default constructor for the event object.
		 *  
		 * @param eventType The event type constant with which to create the instance.
		 * 
		 */
		public function SwagCloudEvent(eventType:String=null) {			
			super(eventType);
		}//constructor
		
	}//SwagCloudEvent class
	
}//package