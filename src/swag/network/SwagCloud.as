package swag.network {
	
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.StatusEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.GroupSpecifier;
	import flash.net.NetConnection;
	import flash.net.NetGroup;
	import flash.net.NetStream;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.utils.ByteArray;
	
	import socialcastr.References;
	import socialcastr.Settings;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.events.SwagCloudEvent;
	import swag.interfaces.network.ISwagCloud;
	import swag.network.SwagCloudData;
	import swag.network.SwagCloudShare;
	
	/**
	 * 
	 * Provides methods and properties for the RTMFP-based Peer-To-Peer cloud service available in Flash player 10.1 and Adobe's Cirrus service.
	 * <p>A <code>SwagCloud</code> instance is, essentially, a single group or swarm of connected peers that can share information via
	 * the <code>NetGroup</code> class.
	 * Although a single <code>NetConnection</code> is shared, multiple <code>NetGroups</code> can be created.</p>
	 * <p>Because groups can be used to transfer chunked data (object replication), an individual group should be assumed to have an individual
	 * purpose. For example, to share a file, a group combining the file name can be created and used to replicate pieces of the file, while
	 * another group can be used to transfer information about that file, or for chat, or for other purposes.</p>
	 * <p>Distributed data can be used in a number of ways. Most of these are straightforward but here are some examples of more
	 * advances techniques.</p>
	 * <p>Native <code>MovieClip</code> objects can be transfered to group members using the following method:<p>
	 * <ol>
	 * <li>Send the byte data for associated MovieClip to cloud: 
	 * 		<code>SwagCloud.distribute(MovieClip.loaderInfo.bytes);</code></li>
	 * <li>On SwagCloudEvent.GATHER event:
	 * 		<code>var newClip:MovieClip=new MovieClip(); 
	 *  	newClip.contentLoaderInfo.addEventListener(Event.INIT, this.onDataLoaded);			
	 * 		var context:LoaderContext=new LoaderContext(false, this.loaderInfo.applicationDomain, null);
	 * 		newClip.loadBytes(eventObj.data, context);</code></li>
	 * <li>Finally, in onDataLoaded, add the clip to the display list.</li>
	 * </ol>
	 * <p>Broadcasting a video or audio stream is achieved using a <code>NetStream</code> object:</p>	 
	 * 
	 * Using the following amfPHP script (running at the myserver.com location), the public IP can be determined.
	 * 
	 * var _netConnection:NetConnection = new NetConnection();
	 * 	
	 * _netConnection.connect("http://www.myserver.com/amfphp/");
	 * _netConnection.call("RendezvousService/getPublicIP", new Responder(handleResult, null));
	 * function handleResult(result:Object):void{
	 *  trace (result.toString());
	 * }		
	 * 
	 * A following method call (not yet written), can return a list of currently available peers.
	 * 
	 * This could be used to connect to peers directly by punching a hole in the NAT / Firewall:
	 * It works like this:
	 *
	 *	Let A be the client requesting the connection
	 *
	 *	Let B be the client that is responding to the request
	 *
	 *	Let S be the server that they contact to initiate the connection
	 * 
	 *	A sends a connection request to S
	 *
	 *	S responds with B's IP and port info, and sends A's IP and port info to B
	 *
	 * A sends a UDP packet to B, which B's router firewall drops but it still punches a hole in A's own firewall where B can connect
	 * 
	 * B sends a UDP packet to A, that both punches a hole in their own firewall, and reaches A through the hole that they punched in their own firewall
	 *
	 *  A and B can now communicate through their established connection without the help of S
	 * 
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
	public class SwagCloud implements ISwagCloud {
		
		/**
		 * Tracks the revision number for the SwagCloud source code. Future revisions should check this
		 * value to ensure compatibility between versions of the protocol stack.
		 * 
		 * 1.0 - First major revision.
		 * 1.1 - Added inclusion of source peer ID ("sourceID") when sending direct ("NetGroup.SendTo.Notify" type) messages.
		 * 1.2 - Removed inclusion of source peer ID ("sourceID"). Now included as existing "remotePeerID" property whenever appropriate.
		 * 1.3 - Added support for distributed /shared streaming. In this mode the SwagCloud acts as a proxy to feed distributed
		 * data into a null connection NetStream for playback (must be supplied externally). Theoretically both live and distributed
		 * streams can be supported in the same SwagCloud instance, but this is untested.
		 */
		public static var version:String="1.3";
		
		private const defaultServerAddress:String="rtmfp://p2p.rtmfp.net/";
		//private const defaultServerAddress:String="rtmfp://127.0.0.1/"; //local - port 1935 (default); no developer key
		private const defaultDeveloperKey:String="XXX"; //Replace with your developer key if using rtmfp.net
		
		private const passwordHashModifier:String="$w@gCl0ud-Ha$h_PaSs768";		
		
		//Use only one connection. Multiple groups (clouds) can be created on a single instance of a NetConnection.
		private static var _netConnection:NetConnection;
		private static var _serverConnected:Boolean=false; //Is the rendezvous server connection established?		
		private static var _sessionStarted:Boolean=false; //Is a connection or a connection attempt currently active?
		private static var _localPeerID:String=new String(); //Peer ID of this connection (singleton since the value comes from the NetConnection instance)
		
		//Fallback to default settings if supplied ones are invalid?
		public var defaultFallback:Boolean=true;
		
		//instrinsic class references (used when compiling in Flash Builder 4.0 or earlier)
		private var NetGroup:Class;
		private var NetGroupInfo:Class;
		private var GroupSpecifier:Class;
		private var NetGroupReplicationStrategy:Class;		
		private var NetGroupReceiveMode:Class;
		private var NetGroupSendMode:Class;
		private var NetGroupSendResult:Class;
		
		//Stores actual server address values used.
		private var _serverAddress:String=new String();
		private var _developerKey:String=new String();
		private var _connectionAddress:String=new String();
		
		private var _groupConnected:Boolean=false; //Is the current group connected?
		private var _groupConnecting:Boolean=false; //Is a group connection currently being established?
		private var _mediaStreamPublished:Boolean=false; //Is the media stream published?		
		
		private var _groupSpecifier:*; //GroupSpecifier instance -- update if using Flash Builder 4.5 or later
		private var _groupName:String;
		private var _netGroup:*; //NetGroup instance -- update if using Flash Builder 4.5 of later	
		private var _openGroup:Boolean=true; //Can anyone post to group or only the creator?
		
		private var _netStream:NetStream; //Used for live streaming (audio / video)
		private var _distributedStream:NetStream; //Used for distributed streaming (audio / video)
		private var _gatherAppendStream:Boolean=false; //Used with "playDistributedStream" to insert
					//shared data into the _netStream object (via appendBytes) instead of a standard media stream.
		private var _mediaStreamName:String; //The media stream name currently being broadcast. 
					//A single stream can share a microphone and camera(recommended for propper A/V synch).
		private var _streamCamera:Camera; //The camera object currently attached and being streamed.
		private var _streamMicrophone:Microphone; //The microphone object currently attached and being streamed.

		private var _peerList:Array=new Array(); //List of attached peers.
				
		/**
		 * The replication strategy used by the netgroup when dealing with distributed / shared / relayed / replicated objects.
		 * This will hold one of the NetGroupReplicationStrategy constants and should be set depending on the type of application
		 * that the group has.
		 * <p>For streaming applications where data order is crucial, the LOWEST_FIRST strategy should be employed. For applications
		 * such as file sharing where the whole data piece is required, the RAREST_FIRST strategy is a better approach for both
		 * ensuring completion and for improving swarming data distribution.</p>
		 */
		private var _gatherStrategy:String;
		/**
		 * Specifies whether or not this cloud group should act as a data relay node for object replication.
		 * <p>Object replication is the basic tenet of most P2P systems and allows individual nodes to retain information
		 * to send on to other nodes, thereby reducing the load on the original source of the data and most efficiently using
		 * bandwidth.</p>
		 * <p>This is enabled by default and may be set before a group is created. If disabled, swarm-based functionality
		 * is effectively disabled as well and direct peer-to-peer communication must be used instead (using <code>send</code>
		 * or <code>broadcast</code>, for example).</p>
		 * <p>The other benefit to using relay replication is the ability to catch and potentially modify informational packets
		 * in the swarmed stream.</p>
		 */		
		private var _dataRelay:Boolean=true;
		private var _cloudData:SwagCloudData=null;
		private var _cloudShare:SwagCloudShare=null;
		
		//If createGroup is called before a connection is established, this queue it up.
		private var _queueCreateGroup:Boolean=false;
		private var _queuedGroupSpec:Object;
		
		/**
		 * The default constructor for the class.
		 *  
		 * @param initServerAddress The initial Cirrus server address that will perform the rendezvous operation. If already connected, this
		 * value will be ignored.
		 * @param initDeveloperKey The initial Cirrus developer key with which to perform the rendezvous. If already connected, this value will
		 * be ignored.
		 * 
		 */
		public function SwagCloud(initServerAddress:String=null, initDeveloperKey:String=null){					
			if ((initServerAddress!=null) && (initServerAddress!="")) {
				this._serverAddress=initServerAddress;
			}//if
			if ((initDeveloperKey!=null) && (initDeveloperKey!="")) {
				this._developerKey=initDeveloperKey;
			}//if
			this.resolveIntrinsicClasses();			
		}//constructor	
		
		/**
		 * Creates a connection with the Cirrus server in order to create the initial rendezvous between peers.
		 * <p>If a connection is already established nothing happens. Since a single <code>NetConnection</code>
		 * is used for this purpose, multiple <code>SwagCloud</code> instance can be created in exactly the same
		 * way (calling this method), without any additional checks.</p>
		 * 
		 * @return <code>True</code> if the connection can, or is already, established, or <code>false</code> if
		 * there's a problem (for example, the server address or developer key weren't set).
		 * 
		 */
		public function createConnection():Boolean {
			if (_sessionStarted || _serverConnected) {			
				return (false);
			}//if
			if ((this._groupConnecting) || (this._groupConnected)) {
				return (false);
			}//if			
			if (Settings.isDebugLevelSet("network")) {
				References.debug("SwagCloud: Attempting rendezvous connection...");
			}//if
			if ((this.serverAddress==null) || (this.serverAddress=="")) {
				if (Settings.isDebugLevelSet("network")) {
					References.debug("SwagCloud: Can't connect because rendezvous server address not valid.");
				}//if	
				return (false);
			}//if
			if ((this.developerKey==null) || (this.developerKey=="")) {
				if (Settings.isDebugLevelSet("network")) {
					References.debug("SwagCloud: Can't connect because rendezvous server developer key not valid.");
				}//if	
				return (false);
			}//if
			_sessionStarted=true;
			if (_netConnection!=null) {
				_netConnection.removeEventListener(NetStatusEvent.NET_STATUS, this.onConnectionStatus);	
			}//if
			if (_netConnection==null) {
				if (Settings.isDebugLevelSet("network")) {
					References.debug("SwagCloud: Initiating new net connection.");
				}//if
				_netConnection=new NetConnection();
				_netConnection.client=this;
				_netConnection.addEventListener(NetStatusEvent.NET_STATUS, this.onConnectionStatus);
				_netConnection.connect(this.serverAddress, this.developerKey); //rtmfp.net
			//	_netConnection.connect(this.serverAddress); //own server
			} else {
				if (Settings.isDebugLevelSet("network")) {
					References.debug("SwagCloud: Using existing net connection.");
				}//if
				_netConnection.addEventListener(NetStatusEvent.NET_STATUS, this.onConnectionStatus);
				if (_netConnection.connected==false) {
					if (Settings.isDebugLevelSet("network")) {
						References.debug("SwagCloud: Attempting to re-connect existing closed net connection.");
					}//if
					_netConnection.client=this;					
					_netConnection.connect(this.serverAddress, this.developerKey); //rtmfp.net
				//	_netConnection.connect(this.serverAddress); //Use for own server
				}//if
			}//else
			return (true);
		}//createConnection
		
		/**
		 * Connects to a new or existing group to be associated with this <code>SwagCloud</code> instance.
		 * <p>This automates the process of connecting to a group by first creating the group specifier and then creating
		 * the group object. If a net connection hasn't yet been established, the operation is queued and carried out automatically (this
		 * saves the developer the hassle of creating a series of listeners to create a group).</p>
		 * <p>In order to connect to an existing group, all of the parameters passed to this method must match the information for
		 * the target group (i.e. the group name, opennes, password, etc., must all be exactly the same). If even one aspect is not the same,
		 * a new group will be created instead. That's just the way it works!</p>		 
		 *  
		 * @param groupName The name of the group to create or connect to.
		 * @param open If <code>true</code>, posting / multicasting to the group is allowed. If <code>false</code>, the group is joined in
		 * read-only mode (consumer role).
		 * @param password The password to encode the group name with. This is used to control access to the group.
		 * @param passwordHash An extra hash string to double-encode the group name and password properties with. Used for extra-secure groups.
		 * @param secure If <code>true</code> the password and passwordHash parameters will be used to encrypt the group data. If <code>false</code>,
		 * these two parameters are ignored and data will be sent in plain text.
		 * @return <code>True</code> if the group was successfully connected to. <code>False</code> if the connection hasn't yet been established, in which
		 * case the group connection will be queued.
		 * 
		 */		
		public function connectGroup (groupName:String, open:Boolean=true, password:String=null, passwordHash:String=passwordHashModifier, secure:Boolean=true):Boolean {			
			if (Settings.isDebugLevelSet("network")) {
				if ((groupName!=null) &&  (password!=null)) {
					if (secure) {
						if (open) {
							References.debug("SwagCloud: Connecting to secure open group \""+groupName+"\".");
						} else {
							References.debug("SwagCloud: Connecting to secure closed group \""+groupName+"\".");
						}//else
					} else {
						if (open) {
							References.debug("SwagCloud: Connecting to non-secure open group \""+groupName+"\".");
						} else {
							References.debug("SwagCloud: Connecting to non-secure closed group \""+groupName+"\".");
						}//else
					}//else					
				} else {
					References.debug("SwagCloud: Establishing queued group connection.");
				}//else
			}//if		
			if ((this._groupConnecting) && (!this._queueCreateGroup)) {				
				return (false);
			}//if
			if (this.groupSpecifier==null) {
				if (this.createGroupSpec(groupName, password, passwordHash, secure)==false) {					
					this._queueCreateGroup=true;
					if (Settings.isDebugLevelSet("network")) {
						References.debug("SwagCloud: Queueing group connection until net connection established.");
					}//if
					return (false);
				}//if
			}//if			
			if (_netConnection==null) {		
				References.debug("SwagCloud: Queuing group connection when new network connection established.");
				this._queueCreateGroup=true;
				if (!this.sessionStarted) {
					this.createConnection();
				}//if
				return (false);		
			} else if (_netConnection.connected==false) {
				References.debug("SwagCloud: Queuing group connection when existing network connection established.");
				this._queueCreateGroup=true;
				if (!this.sessionStarted) {
					this.createConnection();
				}//if
				return (false);
			} else if (this._groupConnecting || this._groupConnected) {
				return (false);
			} else {
				_netConnection.removeEventListener(NetStatusEvent.NET_STATUS, this.onConnectionStatus);
				_netConnection.addEventListener(NetStatusEvent.NET_STATUS, this.onConnectionStatus);
			}//else
			if (this._netGroup!=null) {
				this._netGroup.removeEventListener(NetStatusEvent.NET_STATUS, this.onGroupStatus);
				this._netGroup=null;
			}//if
			_sessionStarted=true;
			this._groupConnecting=true;
			this._openGroup=open;
			this._queueCreateGroup=false;
			this._groupName=groupName;				
			if (this._openGroup) {
				//Can post				
				if (Settings.isDebugLevelSet("network")) {
					References.debug("SwagCloud: Creating group using \"groupspecWithAuthorizations\" specifier.");
				}//if
				this._netGroup=new NetGroup(netConnection, this.groupSpecifier.groupspecWithAuthorizations());
			} else {
				//Receive only
				if (Settings.isDebugLevelSet("network")) {
					References.debug("SwagCloud: Creating group using \"groupspecWithoutAuthorizations\" specifier.");
				}//if
				this._netGroup=new NetGroup(netConnection, this.groupSpecifier.groupspecWithoutAuthorizations());
			}//else
			this._netGroup.addEventListener(NetStatusEvent.NET_STATUS, this.onGroupStatus);
			return (true);
		}//connectGroup		
		
		/**
		 * Disconnects from the associated <code>NetGroup</code>, closing any associated <code>NetStream</code>
		 * first,. This does not close the active <code>NetConnection</code> connection but will make this 
		 * particular <code>SwagCloud</code> instance unfunctional until a new connection is established using 
		 * the <code>connectGroup</code> method.  
		 */
		public function disconnectGroup():void {
			if (Settings.isDebugLevelSet("network")) {
				References.debug("SwagCloud: Disconnecting group \""+this._groupName+"\".");
			}//if
			if (this._netStream!=null) {
				this._netStream.removeEventListener(NetStatusEvent.NET_STATUS, this.onStreamStatus);
				//this._netStream.close();
				this._netStream=null;
				this._mediaStreamPublished=false;
			}//if
			if (this._netGroup!=null) {
				this._netGroup.removeEventListener(NetStatusEvent.NET_STATUS, this.onGroupStatus);
				this._netGroup.close();
				//this._netGroup=null;
				this._groupConnecting=false;
				this._groupConnected=false;
			}//if
			this._gatherAppendStream=false;
			this._groupName=null;
		}//disconnectGroup
		
		/**
		 * Disconnects the <code>NetConnection</code> object being used by all <code>SwagCloud</code>
		 * instances. Obviously this should be used with care.
		 * <p>Broadcasts a <code>SwagCloudEvent.DISCONNECT</code> event when disconnected.</p>
		 * 
		 */
		public function disconnect():void {
			if (Settings.isDebugLevelSet("network")) {
				References.debug("SwagCloud: Closing net connection.");
			}//if
			this.disconnectGroup();
			if (_netConnection!=null) {
				_netConnection.close();
			}//if
			this._gatherAppendStream=false;
			this._groupName=null;			
		}//disconnect
		
		/**
		 * <p>Broadcasts a message to all connected peers using the <code>post</code> method.</p>
		 * <p>According to Adobe's documentation all messages must be unique, so including something lke an <code>index</code>
		 * property is a good idea to ensure proper propagation to all peers.</p>
		 *  
		 * @param data Any valid simple or complex Flash data type(s). Data that exceeds 10 MB in size (for example, 
		 * <code>ByteArray</code> objects, should be chunked into smaller pieces for reliable delivery.
		 * @param neighbourhood If <code>true</code>, the message is propagated through only through the nearest neighbours. If <code>false</code>,
		 * the message is sent to all connected peers (this may be very data intensive if many peers are connected!)
		 * 
		 * @return The message ID sent. This is the hex value of the SHA256 of the serialized binary data of the message.
		 * 
		 */
		public function broadcast(data:*, neighbourhood:Boolean=true):String {
			if (this.netGroup==null) {
				return (null);
			}//if
			if (neighbourhood){ 
				var directDataObject:SwagCloudData=new SwagCloudData("message");				
				directDataObject.data=data;		
				directDataObject.source=this.localPeerID;
				directDataObject.destination="";
				return (this.netGroup.sendToAllNeighbors(directDataObject));	
			}//if			
			directDataObject=new SwagCloudData("message");			
			directDataObject.data=data;
			directDataObject.source=this.localPeerID;
			//TODO: Check why posting to NetGroup does not work as a broadcast. Maybe an unhandled event type in the receiver?
			return (this.netGroup.post(directDataObject));
		}//broadcast
		
		/**
		 * <p>Sends a message to a specific peer via cloud propagation.</p>
		 * <p>The peer ID is one of the IDs stored in the <code>peerList</code> array, *not* an ID associated with a 
		 * received message. A message routed to a non-recognized peer will be lost. Peer propagation is used to
		 * route messages via nearest neighbours to the ultimate location using a shortest path algorithm.</p>
		 *  
		 * @param data The data to send directly to the peer. This can contain any valid Flash data types and will be encapsulated
		 * within the sending data object for routing.
		 * @param peerID The target peer ID to send to. If blank or <code>null</code>, no message will be sent and <code>null</code> will 
		 * be returned.
		 * 
		 * @return  The message ID sent. This is the hex value of the SHA256 of the serialized binary data of the message.
		 * 
		 */		
		public function send(data:*, peerID:String=null):String {
			if (this.netGroup==null) {
				return (null);
			}//if
			if ((peerID==null) || (peerID=="")) {
				return (null);
			}//if			
			var directDataObject:SwagCloudData=new SwagCloudData("message");			
			directDataObject.data=data;	
			directDataObject.source=this.localPeerID;
			directDataObject.destination=this.netGroup.convertPeerIDToGroupAddress(peerID);
			return (this.netGroup.sendToNearest(directDataObject, directDataObject.destination));
		}//send		
		
		/**
		 * Begins the distribution of a data object using relayed object replication.
		 * 
		 * <p>Because a single group can only replicate one data stream, calling this method while data is being replicated
		 * in the background cases any currently relaying data to be discarded.</p>
		 * <p>For this reason it's advisable to create a new <code>SwagCloud</code> instance with any new distribution
		 * that's required.</p>
		 * 
		 * @param data The data object to be replicated. If this is a <code>ByteArray</code> it will be used as-is,
		 * otherwise the data will be serialized using AMF data serialization.
		 * @param chunkSize The data chunk size to use for distribution. Larger chunks may cause unnecessary traffic
		 * as lossy UDP data may cause packets to be lost and re-requested, while small chunks will have excessive overhead
		 * added on them. 
		 * 
		 * @return The newly created <code>SwagCloudData</code> instance associated with the group. An additional reference
		 * to this object is stored in this class instance (since a group can only replicate one object).
		 * 
		 */
		public function distribute(data:*=null, chunkSize:uint=64000):SwagCloudShare {
			if (data==null) {
				return (null);
			}//if
			if (Settings.isDebugLevelSet("network")) {
				References.debug("SwagCloud: Beginning peer to peer data distribution using chunk size of "+String(chunkSize)+" bytes.");
			}//if
			this._gatherAppendStream=false;
			this._cloudShare=new SwagCloudShare();
			this._cloudShare.dataChunkSize=chunkSize;
			this._cloudShare.chunkData(data);
			this._netGroup.addHaveObjects(0, this._cloudShare.numberOfChunks);
			return (this._cloudShare);
		}//distribute
		
		/**
		 * Begins the gathering of a data object using relayed object replication.
		 * 
		 * <p>Since a single group can only distribute one stream of data (though that data can be a complex object),
		 * the received data for a group is associated with only one <code>SwagCloudData</code> object.</p>		 		 
		 * 
		 * @appendStream If <em>true</em>, the associated <code>NetStream</code> object will begin streaming
		 * the gathered data as it's received. This is different from playing published audio / video
		 * streams as this data is not live.
		 * 
		 * @return A newly created <code>SwagCloudData</code> instance into which the distributed data will be gathered.
		 * Once completed, the data will be de-serialized into a native Flash data type and can be used. Until then,
		 * however, the raw binary data may be analyzed if desired within this instance.
		 * 
		 */
		public function gather(appendStream:Boolean=false):SwagCloudShare {
			this._gatherAppendStream=appendStream;
			this._cloudShare=new SwagCloudShare();
			this._netGroup.addWantObjects(0,0); //Send request for number of packets available
			return (this._cloudShare);
		}//distribute
		
		/**
		 * Creates a media stream name for the cloud instance. This must be set in advance of starting
		 * a camera or microphone stream. 
		 *  
		 * @param streamName The exacr stream name to publish over the connected cloud instance.
		 * 
		 */
		public function createMediaStream(streamName:String):void {
			this._mediaStreamPublished=true;
			this._mediaStreamName=streamName;
		}//createMediaStream
		
		/**
		 * Attaches a camera to the outgoing group stream. Be sure to call the <code>createMediaStream</code>
		 * method to set the stream name before calling this method.
		 *  
		 * @param camera The <code>Camera</code> object to attach to the outgoing stream.
		 * @param snapshotMS The snapshot, or key frame rate, at which to insert the camera key frames into the stream.
		 * The default value is -1, which is the same as 0 (only one frame).
		 * 
		 * @return The <code>NetStream</code> object being used to transport the camera stream, or <em>null</em>
		 * if none can be found. 
		 * 
		 */
		public function streamCamera(cam:Camera, snapshotMS:int=-1):NetStream {
			if (cam==null) {
				//Broadcast error
				return (null);
			}//if
			if (this.stream==null) {
				//Broadcast error
				return (null);
			}//if			
			this._streamCamera=cam;
			if (cam.muted) {
				//Camera security dialog is showing...wait until it's done.
				cam.addEventListener(StatusEvent.STATUS, this.onCameraStatus);
				Security.showSettings(SecurityPanel.PRIVACY);
				return (null);
			} else {
				this.stream.attachCamera(cam, snapshotMS);
				if (Settings.isDebugLevelSet("network")) {
					References.debug("SwagCloud: About to publish media stream: \""+this._mediaStreamName+"\"");
				}//if				
				this.publishMediaStream(this._mediaStreamName);
			}//else
			return (this.stream)
		}//streamCamera
		
		/**
		 * Publishes an outgoing group video stream.
		 * 
		 * @param streamName A standard <code>StatusEvent</code> object.
		 * 
		 */
		private function onCameraStatus(eventObj:StatusEvent):void {			
			if (eventObj.code=="Camera.Unmuted") {
				this.stream.attachCamera(this._streamCamera);
				this.publishMediaStream(this._mediaStreamName);
			}//if
		}//onCameraStatus
		
		/**
		 * Attaches a microphone to the outgoing group stream.
		 *  
		 * @param camera
		 * @param snapshotMS
		 * 
		 * @return The <code>NetStream</code> object being used to transport the microphobe stream, or <em>null</em>
		 * if none can be found. 
		 * 
		 */
		public function streamMicrophone(mic:Microphone):NetStream {
			if (mic==null) {
				//Broadcast error
				return (null);
			}//if
			if (this.stream==null) {
				//Broadcast error
				return (null);
			}//if			
			this._streamMicrophone=mic;
			if (mic.muted) {
				//Microphone security dialog is showing...wait until it's done.
				this._streamMicrophone.addEventListener(StatusEvent.STATUS, this.onMicrophoneStatus);
				Security.showSettings(SecurityPanel.PRIVACY);
				return (null);
			} else {
				this.stream.attachAudio(mic);
				this.publishMediaStream(this._mediaStreamName);
			}//else
			return (this.stream)
		}//streamMicrophone
		
		/**
		 * Responds to a microphone security dialog status change, attaches the microphone to the stream,
		 * and publishes it.
		 * 
		 * @param streamName A standard <code>StatusEvent</code> object.
		 * 
		 */
		private function onMicrophoneStatus(eventObj:StatusEvent):void {		
			if (eventObj.code=="Microphone.Unmuted") {
				this.stream.attachAudio(this._streamMicrophone);
				this.publishMediaStream(this._mediaStreamName);
			}//if
		}//onMicrophoneStatus
		
		/**
		 * Stops an outgoing camera stream, if one is attached.  Be sure to call the <code>createMediaStream</code>
		 * method to set the stream name before calling this method.
		 *  
		 * @return <em>True</em> if the stream was stopped, <em>false</em> otherwise (for example, no stream
		 * exists). 
		 * 
		 */
		public function stopCameraStream():Boolean {
			if (this.stream==null) {
				//Broadcast error
				return (false);
			}//if
			try {
				this.stream.attachCamera(null);
				this._streamCamera=null;
				return (true);
			} catch (e:*) {
				return (false);
			}//catch
			return (false);
		}//stopCameraStream
		
		/**
		 * Stops an outgoing microphone stream, if one is attached.
		 *  
		 * @return <em>True</em> if the stream was stopped, <em>false</em> otherwise (for example, no stream
		 * exists). 
		 * 
		 */
		public function stopMicrophoneStream():Boolean {
			if (this.stream==null) {
				//Broadcast error
				return (false);
			}//if
			try {
				this.stream.attachAudio(null);
				this._streamMicrophone.removeEventListener(StatusEvent.STATUS, this.onMicrophoneStatus);
				this._streamMicrophone=null;
				return (true);
			} catch (e:*) {
				return (false);
			}//catch
			return (false);
		}//stopMicrophoneStream
		
		/**
		 * Publishes the media stream. This after camera / microphone have asynchonously checked security settings,
		 * if streaming from these devices, or directly if streaming from a file (or other native location).
		 *  
		 * @param streamName The stream name to publish.
		 * 
		 */
		private function publishMediaStream(streamName:String):void {
			this._mediaStreamPublished=true;
			this.stream.publish(streamName);
		}//publishMediaStream
		
		/**
		 * Attaches a <code>Video</code> object to the cloud's P2P media stream (if one is active). Valid
		 * for both
		 *  
		 * @param video A reference to the <code>Video</code> object to attach to the the cloud's P2P
		 * media stream.
		 *  
		 * @return The <code>NetStream</code> object being used to transport the streaming media, or
		 * <em>null</em> if none exists (no stream is active). 
		 * 
		 */
		public function attachVideoStream(video:Video):NetStream {
			if (this.stream==null) {
				//Broadcast error
				return (null);
			}//if
			video.attachNetStream(this.stream);
			return (this.stream);
		}//attachVideoStream
		
		/**
		 * Plays an attached stream from an incoming group video stream.
		 * <p>Ensure that a <code>Video</code> instance is attached to the stream first
		 * by calling the <code>attachVideoStream</code> method, otherwise the stream
		 * will begin with no output.</p>
		 * 
		 * @param streamName The video stream to connect to and begin playing back. If
		 * an empty string or <em>null</em>, <code>mediaStreamName</code> is used instead. When
		 * a new stream is established for the group, the <code>mediaStreamName</code> is 
		 * automaticaly set. For outgoing connections, the <code>mediaStreamName</code> is set
		 * by the caller, but should also be available.
		 * 
		 */
		public function playVideoStream(streamName:String=null):void {
			if (this.stream==null) {
				//Broadcast error
				return;
			}//if
			if ((streamName==null) || (streamName=="")) {
				streamName=this.mediaStreamName;
			}//if
			this._gatherAppendStream=false;
			this.stream.play(streamName);
		}//playVideoStream
		
		/**
		 * Plays an attached stream from an incoming group audio stream.
		 * 
		 * @param streamName The audio stream to connect to and begin playing back. If
		 * an empty string or <em>null</em>, <code>mediaStreamName</code> is used instead. When
		 * a new stream is established for the group, the <code>mediaStreamName</code> is 
		 * automaticaly set. For outgoing connections, the <code>mediaStreamName</code> is set
		 * by the caller, but should also be available.
		 * 
		 * @return The <code>SoundTranform</code> object associated with the playing audio stream.
		 * 
		 */
		public function playAudioStream(streamName:String=null):SoundTransform {
			if (this.stream==null) {
				//Broadcast error
				return (null);
			}//if
			if ((streamName==null) || (streamName=="")) {
				streamName=this.mediaStreamName;
			}//if
			this._gatherAppendStream=false;
			this.stream.play(streamName);
			return (this.stream.soundTransform);
		}//playAudioStream
		
		/**
		 * Begins playback of a distributed stream associated with the <code>SwagCloud</code> instance.
		 * <p>Unline traditional streams which are published, a gathered stream uses ordered distributed
		 * data for playback meaning that a valid FLV file (of FLV formatted data of any kind), can
		 * be streamed. The stream is appended to a <code>NetStream</code> object which can
		 * then be used as the source for video or audio playback just as a live published stream.</p>
		 * <p>Because the "data generation" <code>NetStream</code> object must have a <em>null</em> <code>NetConnection</code>,
		 * a separate <code>NetStream</code> object must be created and instructed to <code>.play(null)</code>, then passed
		 * to this method as a reference. The SwagCloud will then append data into the <code>NetStream</code> object
		 * for playback.</p>
		 * 
		 * @param playbackStream A reference to the <code>NetStream</code> object, conected to a <em>null</em>
		 * <code>NetConnection</code> object, and instructed to <code>.play(null)</code> (data generation mode)
		 * into which the gathered stream will be collected for playback.
		 */
		public function playDistributedStream(playbackStream:NetStream):void {
			this._distributedStream=playbackStream;			
			this.gatherStrategy="stream";
			this.gather(true);			
		}//playDistributedStream
		
		/**
		 * Stops and closes any video / audio streams being received. Any outbound streams
		 * will have to be recreated, and any inbound streams will have to be re-attached,
		 * if playback is desired again.
		 */
		public function stopStreams():void {
			if (this._netStream!=null) {
				this._netStream.close();
				this._netStream=null;
			}//if
			this._mediaStreamPublished=false;
		}//stopStreams
		
		/**
		 * Pauses any video / audio streams being received.
		 */
		public function pauseStreams():void {
			if (this.stream!=null) {
				this.stream.pause();
			}//if
		}//pauseStreams
		
		/**
		 * Resumes any previously paused video / audio streams.
		 */
		public function resumeStreams():void {
			if (this.stream!=null) {
				this.stream.resume();
			}//if
		}//resumeStreams	
		
		/**
		 * Toggles between pause and play of any video / audio streams being received.
		 */
		public function togglePauseStreams():void {
			if (this.stream!=null) {
				this.stream.togglePause();
			}//if
		}//togglePauseStreams
		
		/**
		 * Validates a data object (usually received by a the cloud), by creating a <code>SwagCloudData</code> 
		 * object and assigning applicable parameter values to it.  
		 * 
		 * @param dataObject The object matching the properties of a standard <code>SwagCloudData</code> object.
		 * Any additional properties will be ignored and any omitted properties will be set to default values.
		 * 
		 * @return A verified <code>SwagCloudData</code> instance. 
		 * 
		 */
		private function validateCloudData(sourceObject:*):SwagCloudData {
			var cloudData:SwagCloudData=new SwagCloudData("message"); //default type
			if (sourceObject==null) {
				return (cloudData);
			}//if
			if (sourceObject is NetStatusEvent) {
				//Data is nested within sourceObject.info.message structure...
				try {
					for (var item:String in sourceObject.info.message) {
						cloudData[item]=sourceObject.info.message[item];
					}//for
				} catch (e:*) {}//catch
			} else if (sourceObject is SwagCloudEvent) {				
				//Process standard return format first. Use fallbacks if data nesting is different.
				try {
					cloudData.control=sourceObject.control;
				} catch (e:*) {}//catch
				try {
					cloudData.data=sourceObject.data;
				} catch (e:*) {}//catch
				try {
					cloudData.destination=sourceObject.destination;
				} catch (e:*) {}//catch			
				try {
					cloudData.source=sourceObject.source;
				} catch (e:*) {}//catch
			}//else
			return (cloudData);
		}//validateCloudData
		
		/**
		 * @private
		 */
		private function addPeer(peerID:String):void {			
			if (this._peerList==null) {
				this._peerList=new Array();
				return;
			}//if
			for (var count:uint=0; count<this._peerList.length; count++) {
				var currentPeer:String=this._peerList[count] as String;
				if (currentPeer==peerID) {
					return;
				}//if
			}//for
			if (this.peerIsUnique(peerID)) {
				if (Settings.isDebugLevelSet("network")) {
					References.debug("SwagCloud: Adding new peer to list \""+peerID+"\"");
				}//if				
				this._peerList.push(peerID);	
			}//if
		}//addPeer
		
		/**
		 * @private
		 */
		private function removePeer(peerID:String):void {
			if (Settings.isDebugLevelSet("network")) {
				References.debug("SwagCloud: Attempting to cull peer: "+peerID);
			}//if
			if (this._peerList==null) {
				if (Settings.isDebugLevelSet("network")) {
					References.debug("SwagCloud: Peer list doesn't exist.");
				}//if
				this._peerList=new Array();
				return;
			}//if
			var updatedList:Array=new Array();
			for (var count:uint=0; count<this._peerList.length; count++) {
				var currentPeer:String=this._peerList[count] as String;
				if (currentPeer==peerID) {
					if (Settings.isDebugLevelSet("network")) {
						References.debug("SwagCloud: Culling peer: "+peerID);
					}//if					
				} else {
					//Do a little housekeeping while we're at it...
					if ((currentPeer!=null) && (currentPeer!="")) {
						updatedList.push(currentPeer);
					}//if
				}//else
			}//for		
			this._peerList=updatedList;		
		}//removePeer
		
		/**		 
		 * @private		 
		 */
		private function peerIsUnique(peerID:String):Boolean {
			if ((peerID==null) || (peerID=="")) {
				return (false);
			}//if
			for (var count:uint=0; count<this._peerList.length; count++) {
				var currentPeer:String=this._peerList[count] as String;
				if (currentPeer==peerID) {
					return (false);
				}//if
			}//for
			return (true);
		}//peerIsUnique
		
		/**
		 * @private
		 */
		private function createGroupSpec(groupName:String, password:String=null, passwordHash:String=passwordHashModifier, secure:Boolean=true): Boolean {			
			if ((groupName==null) || (groupName=="")) {
				return (false);
			}//if
			this._groupSpecifier=new GroupSpecifier(groupName);
			this._groupSpecifier.multicastEnabled=true;	
			// When set to "true", the Flash Player instance will send 
			// membership updates on a LAN to inform other LAN-connected group 
			// neighbors of their participation.
			this._groupSpecifier.ipMulticastMemberUpdatesEnabled=true;
			this._groupSpecifier.serverChannelEnabled=true; //Do we want handshaking to be automatic via server? If not we need to implement 
						//the "addBootstrapPeer" method. 
			this._groupSpecifier.objectReplicationEnabled=this.dataRelay; //gather
			this._groupSpecifier.postingEnabled=true; //broadcast		
			this._groupSpecifier.routingEnabled=true; //direct
			this._groupSpecifier.multicastEnabled=true; //streams
			this._groupSpecifier.peerToPeerDisabled=false; //Must ALWAYS be false, otherwise no P2P!
			if ((password!=null) && (password!="")) {
				this._groupSpecifier.setPostingPassword(password, passwordHash);
				this._groupSpecifier.setPublishPassword(password, passwordHash);
			}//if
			return (true);
		}//createGroupSpec	
		
		//__/ CONNECTION HANDLERS \__
		
		/**
		 * @private
		 */
		private function onConnectionStatus(eventObj:NetStatusEvent):void {		
			if (Settings.isDebugLevelSet("network")) {
				References.debug("SwagCloud.onConnectionStatus ["+eventObj.info.level+"]: "+eventObj.info.code);
			}//if			
			switch (eventObj.info.code) {
				case "NetConnection.Connect.Success" : 
					_sessionStarted=true;
					_serverConnected=true;					
					_localPeerID=_netConnection.nearID;					
					var event:SwagCloudEvent=new SwagCloudEvent(SwagCloudEvent.CONNECT);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;		
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					SwagDispatcher.dispatchEvent(event, this);
					if (this._queueCreateGroup) {
						if (Settings.isDebugLevelSet("network")) {
							References.debug("SwagCloud: Connecting group post-connect.");
						}//if	
						this.connectGroup(null, this._openGroup, null, null, false);
					}//if			
					break;	
				//Not sure why this is NetConnection and not NetGroup, but here it is anyways.
				case "NetGroup.Connect.Success":
					_sessionStarted=true;
					this._groupConnected=true;
					_sessionStarted=true;
					_serverConnected=true;
					try {
						this._netGroup.replicationStrategy=this.gatherStrategy;
					} catch (e:*) {
						
					}//catch
					event=new SwagCloudEvent(SwagCloudEvent.GROUPCONNECT);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;			
					event.groupID=String(eventObj.info.group);				
					SwagDispatcher.dispatchEvent(event, this);					
					break;
				case "NetGroup.Connect.Failed":
					this._groupConnected=false;
					event=new SwagCloudEvent(SwagCloudEvent.GROUPCONNECTFAIL);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;			
					event.groupID=String(eventObj.info.group);				
					SwagDispatcher.dispatchEvent(event, this);					
					break;
				case "NetGroup.Connect.Rejected":	
					this._groupConnected=false;
					event=new SwagCloudEvent(SwagCloudEvent.GROUPREJECT);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;			
					event.groupID=String(eventObj.info.group);				
					SwagDispatcher.dispatchEvent(event, this);					
					break;
				case "NetGroup.Connect.Closed":
					this._groupConnected=false;
					event=new SwagCloudEvent(SwagCloudEvent.GROUPDISCONNECT);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;			
					event.groupID=String(eventObj.info.group);				
					SwagDispatcher.dispatchEvent(event, this);					
					break;
				case "NetStream.Connect.Closed":
					this._groupConnected=false;
					event=new SwagCloudEvent(SwagCloudEvent.STREAMCLOSED);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;			
					event.groupID=String(eventObj.info.group);				
					SwagDispatcher.dispatchEvent(event, this);					
					break;
				case "NetConnection.Connect.Closed":
					_sessionStarted=false;
					_serverConnected=false;
					event=new SwagCloudEvent(SwagCloudEvent.DISCONNECT);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;			
					event.groupID=String(eventObj.info.group);				
					SwagDispatcher.dispatchEvent(event, this);					
					break;
			}//switch			
		}//onConnectionStatus
		
		/**
		 * <p>Processes messages for the P2P group.</p>
		 * 
		 * <p>A basic <code>switch</code> statement is used to determine what type of message was received. Typically,
		 * very little processing is done to the message and instead relevant details are extracted and packaged into
		 * a <code>SwagCloudEvent</code> object which is then broadcast.</p>
		 * 
		 * <p>Some message codes such as "NetGroup.SendTo.Notify" are processed (in this case propagated), to ensure that
		 * P2P functionality is retained with the client.</p>
		 * 
		 * @param eventObj The <code>NetStatusEvent</code> event object received for the group status message.
		 * 
		 */
		private function onGroupStatus(eventObj:NetStatusEvent):void {
			this._queueCreateGroup=false;
			if (Settings.isDebugLevelSet("network")) {
				References.debug("SwagCloud.onGroupStatus ["+eventObj.info.level+"]: "+eventObj.info.code);
			}//if			
			this._groupConnecting=false;
			switch (eventObj.info.code) {
				//__/ Single-Shot Communication and Relays \__
				case "NetGroup.Neighbor.Connect" :					
					_sessionStarted=true;					
					var event:SwagCloudEvent=new SwagCloudEvent(SwagCloudEvent.PEERCONNECT);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;			
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					event.remotePeerID=eventObj.info.peerID;					
					event.remotePeerNonce=eventObj.info.neighbor; //Is this right?
					this.addPeer(event.remotePeerID);
					SwagDispatcher.dispatchEvent(event, this);					
					break;
				case "NetGroup.Neighbor.Disconnect":
					_sessionStarted=true;
					event=new SwagCloudEvent(SwagCloudEvent.PEERDISCONNECT);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;			
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;					
					event.remotePeerID=eventObj.info.peerID;					
					event.remotePeerNonce=eventObj.info.neighbor; //Is this right?
					this.removePeer(event.remotePeerID);
					SwagDispatcher.dispatchEvent(event, this);	
					break;
				case "NetGroup.Posting.Notify" :
					_sessionStarted=true;
					var cloudData:SwagCloudData=this.validateCloudData(eventObj);
					if (cloudData.control=="message") {
						event=new SwagCloudEvent(SwagCloudEvent.BROADCAST);
						event.statusLevel=eventObj.info.level;
						event.statusCode=eventObj.info.code;	
						event.data=cloudData.data;
						event.cloudData=cloudData;
						event.messageID=eventObj.info.messageID;
						event.remotePeerID=cloudData.source;							
						event.remotePeerNonce=eventObj.info.neighbor; //Is this right?
						SwagDispatcher.dispatchEvent(event, this);
					}//if
					break;
				case "NetGroup.SendTo.Notify" :						
					_sessionStarted=true;
					//eventObj.info.message.destination is set in the "broadcast" method. Update if it conflicts with something else.					
					cloudData=this.validateCloudData(eventObj);				
					if ((eventObj.info.fromLocal == true) || (cloudData.destination=="")) {
						var directDataObject:SwagCloudData=new SwagCloudData("message");															
						if (eventObj.info.message.control=="message") {
							event=new SwagCloudEvent(SwagCloudEvent.DIRECT);
							event.statusLevel=eventObj.info.level;
							event.statusCode=eventObj.info.code;	
							event.data=cloudData.data;
							event.cloudData=cloudData;
							event.fromLocal=eventObj.info.fromLocal;
							event.localPeerID=_netConnection.nearID;
							event.localPeerNonce=_netConnection.nearNonce;
							event.serverID=_netConnection.farID;
							event.serverNonce=_netConnection.farNonce;					
							event.groupIDHash=eventObj.info.from;
							event.remotePeerID=cloudData.source;							
							SwagDispatcher.dispatchEvent(event, this);
						}//if
					} else {
						if (cloudData.control=="message") {
							event=new SwagCloudEvent(SwagCloudEvent.ROUTE);
							event.statusLevel=eventObj.info.level;
							event.statusCode=eventObj.info.code;	
							event.data=cloudData.data;
							event.cloudData=cloudData;
							event.fromLocal=eventObj.info.fromLocal;
							event.localPeerID=_netConnection.nearID;
							event.localPeerNonce=_netConnection.nearNonce;
							event.serverID=_netConnection.farID;
							event.serverNonce=_netConnection.farNonce;					
							event.groupIDHash=eventObj.info.from;
							event.remotePeerID=cloudData.source;
							SwagDispatcher.dispatchEvent(event, this);
							this.netGroup.sendToNearest(eventObj.info.message, eventObj.info.message.destination);
						}//if
					}//else
					break;
				//__/ Object-Replication / Sharing / Relay Communication \__
				case "NetGroup.Replication.Fetch.SendNotify":
					_sessionStarted=true;
					//About to send a chunk from a fetch operation. An FYI event.
					break;
				case "NetGroup.Replication.Fetch.Result":
					_sessionStarted=true;
					//Got a response from cloud with a requested chunk					
					var chunkIndex:Number=new Number(eventObj.info.index);
					if (chunkIndex==0) {
						//Header chunk
						//See format from "NetGroup.Replication.Request" below
						var chunkInfoObject:Object=eventObj.info.object;
						//chunkInfoObject includes: numChunks, chunkSize, dataSize
						this._cloudShare.numberOfChunks=chunkInfoObject.numChunks;
						this._cloudShare.dataChunkSize=chunkInfoObject.chunkSize;
						this._cloudShare.encoding=chunkInfoObject.encoding;
						event=new SwagCloudEvent(SwagCloudEvent.GATHERINFO);
						event.statusLevel=eventObj.info.level;
						event.statusCode=eventObj.info.code;	
						event.cloudShare=this._cloudShare;
						this._netGroup.addWantObjects(1, 1);
					} else {	
						//Data chunk
						this._cloudShare.addReceivedDataChunk(eventObj.info.object, chunkIndex);						
						this._netGroup.addHaveObjects(chunkIndex, chunkIndex);						
						var nextIndex:uint=this._cloudShare.nextUnreceivedChunkIndex;						
						if ((nextIndex>0) && (nextIndex<=this._cloudShare.numberOfChunks)) {														
							this._netGroup.addWantObjects(nextIndex, nextIndex);
							//Push data into NetStream if streaming from gathered / distributed source(s)
							if (this._gatherAppendStream) {
								if (this._distributedStream!=null) {
									this._distributedStream.appendBytes(eventObj.info.object);
								}//if
							}//if
						} else {							
							this._cloudShare.distributedData.position=0; //Don't forget to reset!!
							if (this._cloudShare.encoding=="AMF") {		
								this._cloudShare.data=this._cloudShare.distributedData.readObject();
							} else {
								this._cloudShare.data=this._cloudShare.distributedData;
							}//else
							event=new SwagCloudEvent(SwagCloudEvent.GATHER);
							event.statusLevel=eventObj.info.level;
							event.statusCode=eventObj.info.code;	
							event.data=this._cloudShare.data;
							event.cloudShare=this._cloudShare;
							SwagDispatcher.dispatchEvent(event, this);
						}//else
					}//else					
					break;
				case "NetGroup.Replication.Request":
					_sessionStarted=true;
					//Got a request from the cloud for a chunk					
					var requestIndex:Number=eventObj.info.index;
					var requestID:Number=eventObj.info.requestID;
					if (requestIndex==0) {
						var numChunks:Number=this._cloudShare.numberOfChunks;
						var chunkSize:uint=this._cloudShare.dataChunkSize;
						var encoding:String=this._cloudShare.encoding;
						chunkInfoObject=new Object();
						chunkInfoObject.numChunks=numChunks;
						chunkInfoObject.chunkSize=chunkSize;
						chunkInfoObject.encoding=encoding;
						chunkInfoObject.dataSize=this._cloudShare.distributedData.length;
						this._netGroup.writeRequestedObject(requestID, chunkInfoObject);
						event=new SwagCloudEvent(SwagCloudEvent.INFOREQUEST);
						event.requestID=requestID;
						event.cloudShare=this._cloudShare;
						SwagDispatcher.dispatchEvent(event, this);
					} else {						
						var chunkData:ByteArray=this._cloudShare.getChunk(requestIndex);						
						this._netGroup.writeRequestedObject(requestID, chunkData);
						event=new SwagCloudEvent(SwagCloudEvent.CHUNKREQUEST);
						event.requestID=requestID;
						event.cloudShare=this._cloudShare;
						SwagDispatcher.dispatchEvent(event, this);
					}//else
					break;
				case "NetGroup.MulticastStream.PublishNotify" :
					_sessionStarted=true;
					event=new SwagCloudEvent(SwagCloudEvent.STREAMOPEN);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=eventObj.info.name;
					this._mediaStreamName=String(eventObj.info.name);
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					event.remotePeerID=eventObj.info.peerID;
					event.remotePeerNonce=eventObj.info.neighbor;					
					SwagDispatcher.dispatchEvent(event, this);					
					break;
				case "NetGroup.MulticastStream.UnpublishNotify" :
					_sessionStarted=true;
					event=new SwagCloudEvent(SwagCloudEvent.STREAMCLOSED);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=eventObj.info.name;
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					event.remotePeerID=eventObj.info.peerID;
					event.remotePeerNonce=eventObj.info.neighbor;					
					SwagDispatcher.dispatchEvent(event, this);					
					break;
			}//switch						
		}//onGroupStatus
		
		/**
		 * Handles <code>NetStatusEvent</code> events similarly to <code>onGroupStatus</code> except that it
		 * operates on the <code>stream</code> instance associated with this class instance.
		 *  
		 * @param eventObj A standard <code>NetStatusEvent</code> event object.
		 * 
		 */
		public function onStreamStatus(eventObj:NetStatusEvent):void {
			this._queueCreateGroup=false;	
			_sessionStarted=true;
			if (Settings.isDebugLevelSet("network")) {
				References.debug("SwagCloud.onStreamStatus ["+eventObj.info.level+"]: "+eventObj.info.code);
			}//if			
			switch (eventObj.info.code) {
				case "NetStream.Play.Start" : 
					var event:SwagCloudEvent=new SwagCloudEvent(SwagCloudEvent.STREAMOPEN);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=this._mediaStreamName;
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					SwagDispatcher.dispatchEvent(event, this);			
					break;
				case "NetStream.Play.Stop" : 
					event=new SwagCloudEvent(SwagCloudEvent.STREAMSTOP);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=this._mediaStreamName;
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					SwagDispatcher.dispatchEvent(event, this);			
					break;
				case "NetStream.Publish.Start" :
					this._mediaStreamPublished=true;
					_sessionStarted=true;
					event=new SwagCloudEvent(SwagCloudEvent.STREAMOPEN);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=this._mediaStreamName;					
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;					
					SwagDispatcher.dispatchEvent(event, this);	
					break;
				case "NetStream.Publish.BadName" :
					this._mediaStreamPublished=false;
					event=new SwagCloudEvent(SwagCloudEvent.STREAMPUBLISHFAIL);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=this._mediaStreamName;
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					SwagDispatcher.dispatchEvent(event, this);		
					break;
				case "NetStream.Play.Reset" : 
					event=new SwagCloudEvent(SwagCloudEvent.STREAMRESET);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=this._mediaStreamName;
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					SwagDispatcher.dispatchEvent(event, this);		
					break;
				case "NetStream.MulticastStream.Reset" : 
					event=new SwagCloudEvent(SwagCloudEvent.STREAMRESET);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=this._mediaStreamName;
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					SwagDispatcher.dispatchEvent(event, this);		
					break;
				case "NetStream.Connect.Success" :
					this._mediaStreamPublished=true;
					event=new SwagCloudEvent(SwagCloudEvent.STREAMOPEN);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=eventObj.info.stream;
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					SwagDispatcher.dispatchEvent(event, this);							
					break;
				case "NetStream.Connect.Closed" :
					this._mediaStreamPublished=false;
					this._netStream.removeEventListener(NetStatusEvent.NET_STATUS, this.onStreamStatus);
					if (this._netStream["dispose"] is Function) {
						this._netStream["dispose"]();
					}//if
					this._netStream=null;
					event=new SwagCloudEvent(SwagCloudEvent.STREAMCLOSED);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=eventObj.info.stream;
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					SwagDispatcher.dispatchEvent(event, this);							
					break;
				case "NetStream.Connect.Failed" :
					this._mediaStreamPublished=false;
					this._netStream.removeEventListener(NetStatusEvent.NET_STATUS, this.onStreamStatus);
					if (this._netStream["dispose"] is Function) {
						this._netStream["dispose"]();
					}//if
					this._netStream=null;					
					event=new SwagCloudEvent(SwagCloudEvent.STREAMOPENFAIL);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=eventObj.info.stream;
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					SwagDispatcher.dispatchEvent(event, this);							
					break;					
				case "NetStream.Connect.Rejected" :
					this._mediaStreamPublished=false;
					this._netStream.removeEventListener(NetStatusEvent.NET_STATUS, this.onStreamStatus);
					if (this._netStream["dispose"] is Function) {
						this._netStream["dispose"]();
					}//if
					this._netStream=null;
					event=new SwagCloudEvent(SwagCloudEvent.STREAMOPENFAIL);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=eventObj.info.stream;
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					SwagDispatcher.dispatchEvent(event, this);							
					break;
				case "NetStream.Play.StreamNotFound" :
					this._mediaStreamPublished=false;
					this._netStream.removeEventListener(NetStatusEvent.NET_STATUS, this.onStreamStatus);
					if (this._netStream["dispose"] is Function) {
						this._netStream["dispose"]();
					}//if
					this._netStream=null;
					event=new SwagCloudEvent(SwagCloudEvent.STREAMOPENFAIL);
					event.statusLevel=eventObj.info.level;
					event.statusCode=eventObj.info.code;
					event.streamID=this._mediaStreamName;
					event.localPeerID=_netConnection.nearID;
					event.localPeerNonce=_netConnection.nearNonce;
					event.serverID=_netConnection.farID;
					event.serverNonce=_netConnection.farNonce;
					SwagDispatcher.dispatchEvent(event, this);							
					break;				
			}//switch
		}//onStreamStatus
		
		public static function get connected():Boolean {
			if (_netConnection==null) {
				return (false);
			}//if
			return (_netConnection.connected);
		}//get connected
		
		public function get attachedCamera():Camera {
			return (this._streamCamera);
		}//get attachedCamera
		
		public function get attachedMicrophone():Microphone {
			return (this._streamMicrophone);
		}//get attachedMicrophone
		
		public function get mediaStreamName():String {
			return (this._mediaStreamName);
		}//get mediaStreamName
		
		public function get connectionAddress():String {
			this._connectionAddress=this.serverAddress+this.developerKey;
			return (this._connectionAddress);
		}//get connectionAddress
		
		public function get serverAddress():String {
			if ((this._serverAddress==null) || (this._serverAddress=="")) {
				if (this.defaultFallback) {
					this._serverAddress=this.defaultServerAddress;
				}//if
			}//if
			return (this._serverAddress);
		}//get serverAddress
		
		public function set serverAddress(serverSet:String):void {
			this._serverAddress=serverSet;
		}//set serverAddress
		
		public function get developerKey():String {
			if ((this._developerKey==null) || (this._developerKey=="")) {
				if (this.defaultFallback) {
					this._developerKey=this.defaultDeveloperKey;
				}//if
			}//if
			return (this._developerKey);
		}//get developerKey
		
		/**
		 * 
		 * @param strategySet The data gathering strategy for distributed / relayed / shared / replicated data with
		 * a group. This value should be set to match the target application for which it's being used, and should
		 * ideally match one of the <code>NetGroupReplicationStrategy</code> constants. Use a LOWEST_FIRST strategy
		 * when streaming data or when data ordering is important. When data can be distributed piecemeal, such as in
		 * file sharing applications, the RAREST_FIRST strategy is the best to employ to ensure that data is both 
		 * available to the swarm and to ensure easiest completion of the transfer.
		 * <p>This method attempts to more forgiving when specifying the strategy by providing support for a variety
		 * of alternate naming conventions. For example:
		 * <code>"lowest" = "LowestFirst" = " lowest First" = NetGroupReplicationStrategy.LOWEST_FIRST</code>
		 * 
		 */
		public function set gatherStrategy(strategySet:String):void {
			if (Settings.isDebugLevelSet("network")) {
				References.debug("SwagCloud: Updating gather strategy to \""+strategySet+"\".");
			}//if	
			this._gatherStrategy=new String();
			this._gatherStrategy=strategySet;
			this._gatherStrategy=SwagDataTools.stripChars(this._gatherStrategy, SwagDataTools.SEPARATOR_RANGE);
			this._gatherStrategy=this._gatherStrategy.toLowerCase();
			switch (this._gatherStrategy) {
				case "lowestfirst": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "lowest": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;							
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "low":
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;		
				case "first":
						this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
						if (this._netGroup!=null) {
							this._netGroup.replicationStrategy=this._gatherStrategy;
						}//if
						break;		
				case "numbered": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "number": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "num": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "indexed": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "index": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "ind": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "ordered": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "order": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "ord": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "stream": 
						this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
						if (this._netGroup!=null) {
							this._netGroup.replicationStrategy=this._gatherStrategy;
						}//if
						break;
				case "streaming": 
						this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
						if (this._netGroup!=null) {
							this._netGroup.replicationStrategy=this._gatherStrategy;
						}//if
						break;
				case "rarestfirst": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.RAREST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "rarest": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.RAREST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;				
				case "rare": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.RAREST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "file": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.RAREST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "share": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.RAREST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				case "distributed": 
							this._gatherStrategy=this.NetGroupReplicationStrategy.RAREST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
				default : 
							this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
							if (this._netGroup!=null) {
								this._netGroup.replicationStrategy=this._gatherStrategy;
							}//if
							break;
			}//switch
		}//gatherStrategy
		
		/**		 
		 * @private		 
		 */
		public function get gatherStrategy():String {
			if ((this._gatherStrategy==null) || (this._gatherStrategy=="")) {
				this._gatherStrategy=new String();
				this._gatherStrategy=this.NetGroupReplicationStrategy.LOWEST_FIRST;
			}//if
			return (this._gatherStrategy);
		}//get gatherStrategy
		
		public static function get netConnection():NetConnection {
			return (_netConnection);
		}//get netConnection
		
		public function get rendezvousConnected():Boolean {
			return (_serverConnected);
		}//get rendezvousConnected

		public function get groupConnected():Boolean {
			return (this._groupConnected);
		}//get groupConnected
		
		public function get groupConnecting():Boolean {
			return (this._groupConnecting);
		}//get groupConnecting
		
		public function get mediaStreamPublished():Boolean {
			return (this._mediaStreamPublished);
		}//get mediaStreamPublished
		
		public function get stream():NetStream {
			if (_netConnection==null) {
				return (null);
			}//if
			if (_netConnection.connected==false) {
				return (null);
			}//if
			if (this._netStream==null) {
				if (this._openGroup) {
					//Can post
					this._netStream=new NetStream(_netConnection,this.groupSpecifier.groupspecWithAuthorizations());					
				} else {
					//Receive only
					this._netStream=new NetStream(_netConnection,this.groupSpecifier.groupspecWithoutAuthorizations());					
				}//else	
				this._netStream.addEventListener(NetStatusEvent.NET_STATUS, this.onStreamStatus);	
			}//if
			return (this._netStream);
		}//get stream
		
		/** 
		 * @return <em>True</code> is the session has been started (a connection attempt has been requested). This
		 * value does not indicate that a connection is necessarily opened.
		 */
		public function get sessionStarted():Boolean {
			return (_sessionStarted);
		}//get sessionStarted
		
		/** 
		 * @param keySet The developer key to use with the rtmfp.net server (not currently used at any other time). 
		 */
		public function set developerKey(keySet:String):void {
			this._developerKey=keySet;
		}//set developerKey
		
		/** 
		 * @return A reference to the internal <code>NetGroup</code> object being used for P2P communication.
		 */
		public function get netGroup():* {
			return (this._netGroup);
		}//get netGroup
		
		/** 
		 * @return The name of the group, as specified when invoking the <code>connectGroup</code> method.
		 */
		public function get groupName():String {
			return (this._groupName);
		}//get groupName
		
		/** 
		 * @return The <code>NetGroupInfo</code> object of associated <code>NetGroup</code> object, or 
		 * <em>null</em> if the group doesn't exist. 
		 */
		public function get netGroupInfo():* {
			if (this._netGroup==null) {
				return (null);
			}//if
			return (this._netGroup.info);
		}//get netGroupInfo
		
		/** 
		 * @return The neighbour count value of the same name in the associated <code>NetGroup</code>
		 * object, or <em>null</em> none exists. 
		 */
		public function get neighbourCount():Number {
			if (this._netGroup==null) {				
				return (0);
			}//if
			return (this._netGroup.neighborCount);
		}//get neighbourCount
		
		/** 
		 * @return The estimated member count value of the same name in the associated <code>NetGroup</code>
		 * object, or <em>null</em> none exists. 
		 */
		public function get estimatedMemberCount():Number {
			if (this._netGroup==null) {
				return (0);
			}//if
			return (this._netGroup.estimatedMemberCount);
		}//get estimatedMemberCount
		
		/** 
		 * @return The <code>GroupSpecifier</code> object created and used with the local <code>NetGroup</code>
		 * instance to connect to the group, or <em>null</em> if none exists.
		 */
		public function get groupSpecifier():* {
			return (this._groupSpecifier);
		}//get groupSpecifier
		
		/** 
		 * @return The dynamic encrypted local peer ID, as assigned by the rendezvous server to the local RTMFP 
		 * connection.
		 */
		public function get localPeerID():String {
			return (_localPeerID);
		}//get localPeerID
		
		/** 
		 * @return The dynamic encrypted rendezvous server peer ID as reported on connection. 
		 */
		public static function get connectionPeerID():String {
			return (_localPeerID);
		}//get connectionPeerID
		
		/** 
		 * @return An array of unique peer IDs connected directly to this <code>SwagCloud</code> instance. 
		 */
		public function get peerList():Array {
			return (this._peerList);
		}//get peerList
		
		/** 
		 * @return <em>True</em> if this instance may act as a data relay for shared / distributed data,
		 * <code>false</code> otherwise.
		 */
		public function get dataRelay():Boolean {
			return (this._dataRelay);
		}//get dataRelay
		
		public function set dataRelay(relaySet:Boolean):void {
			this._dataRelay=relaySet;
			if (this._groupSpecifier!=null) {
				this._groupSpecifier.objectReplicationEnabled=relaySet;
			}//if
		}//set dataRelay
		
		/**
		 * Resolves intrinsic classes so that this will compile in earlier versions of Flash Builder.
		 * <p>These are set to Class type references for the class so that they can be used as though they'd been 
		 * imported.</p> 
		 */
		private function resolveIntrinsicClasses():void {			
			this.NetGroup=SwagSystem.getDefinition("flash.net.NetGroup");
			this.NetGroupInfo=SwagSystem.getDefinition("flash.net.NetGroupInfo");
			this.GroupSpecifier=SwagSystem.getDefinition("flash.net.GroupSpecifier");			
			this.NetGroupReplicationStrategy=SwagSystem.getDefinition("flash.net.NetGroupReplicationStrategy");
			this.NetGroupReceiveMode=SwagSystem.getDefinition("flash.net.NetGroupReceiveMode");
			this.NetGroupReplicationStrategy=SwagSystem.getDefinition("flash.net.NetGroupReplicationStrategy");
			this.NetGroupSendMode=SwagSystem.getDefinition("flash.net.NetGroupSendMode");
			this.NetGroupSendResult=SwagSystem.getDefinition("flash.net.NetGroupSendResult");
		}//resolveIntrinsicClasses
		
	}//SwagCloud class
	
}//package