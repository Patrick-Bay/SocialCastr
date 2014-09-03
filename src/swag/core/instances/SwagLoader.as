package swag.core.instances {
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;	
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	import socialcastr.References;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	import swag.events.SwagErrorEvent;
	import swag.events.SwagLoaderEvent;
	import swag.interfaces.core.instances.ISwagLoader;
	
	/**
	 * Provides runtime-agnostic methods and properties for downloading / uploading data from / to remote or local sources. 
	 * <p>"Runtime-agnostic" means that the best methods will be used depending on the runtime and should be completely transparent
	 * to the developer. In other words, if <code>SwagLoader</code> is running within an AIR instance, it will attempt to use AIR-based
	 * file routines instead of standard Flash URL-based ones.</p>
	 * <p>The aim of runtime-agnosticism is to provide the developer with the easiest way to load file data reliably without the need
	 * to split or change code to work with the target runtime.</p> 
	 * <p>Load errors that receive HTTP status codes will include the returned server code with the <code>SwagErrorEvent</code> dispatch. 
	 * Other error codes may include:
	 * <ul>
	 * <li><b>1</b> - An I/O error occured (usually a hardware problem that may require a system reset).
	 * </ul></p>
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
	public class SwagLoader implements ISwagLoader {
		
		/**
		 * Denotes that the associated <code>SwagLoader</code> instance will attempt to use a local, file-based
		 * transport mechanism (a <code>FileStream</code> instance).
		 */
		public static const LOCALTRANSPORT:String="SwagLoader.LOCALTRANSPORT";
		/**
		 * Denotes that the associated <code>SwagLoader</code> instance will attempt to use a remote, URL-based
		 * transport mechanism (a <code>URLStream</code> instance). This is the default transport type since
		 * it has the broadest support (both Flash and AIR), and is also the fallback transport if a local one
		 * isn't available.
		 */
		public static const REMOTETRANSPORT:String="SwagLoader.REMOTETRANSPORT";
		/**
		 * Denotes that the <code>SwagLoader</code> instance will not attempt any load. This is the default
		 * transport when the class hasn't been properly initialized.
		 */
		public static const NOTRANSPORT:String="SwagLoader.NOTRANSPORT";
		/**
		 * Denotes that the associated <code>SwagLoader</code> instance will attempt to use a remote, URL-based
		 * transport mechanism (a <code>URLLoader</code> instance), using a <em>GET</em> operation. When
		 * an invalid send request type is issued during a send request, this is the default mechanism used.
		 */
		public static const REMOTETRANSPORTGET:String="SwagLoader.REMOTETRANSPORTGET";
		/**
		 * Denotes that the associated <code>SwagLoader</code> instance will attempt to use a remote, URL-based
		 * transport mechanism (a <code>URLLoader</code> instance), using a <em>POST</em> operation.
		 */
		public static const REMOTETRANSPORTPOST:String="SwagLoader.REMOTETRANSPORTPOST";
		/**
		 * Denotes that the associated <code>SwagLoader</code> instance will attempt to use a remote, file send
		 * transport mechanism (a <code>FileReference</code> instance).
		 */
		public static const REMOTETRANSPORTFILE:String="SwagLoader.REMOTETRANSPORTFILE";
		/**
		 * @private 
		 */
		private var _stream:*=null
		/**
		 * @private 
		 */
		private var _path:*=null;
		/**
		 * @private 
		 */
		private var _loadedBinaryData:ByteArray=null;		
		/**
		 * @private 
		 */
		private var _sendBinaryData:ByteArray=null;	
		/**
		 * @private 
		 */
		private var _loadedData:*=null;
		/**
		 * @private 
		 */
		private var _uiObjectLoader:Loader;
		/**
		 * @private 
		 */
		private var _returnType:*=null;
		
		/**
		 * Default constructor for the class.
		 *  
		 * @param filePathRef The file path to associate with this <code>SwagLoader</code> instance. This
		 * value may either be a <code>String</code>, in which case it's assumed to be a direct file / URL reference,
		 * a <code>URLRequest</code> object to be used directly with a <code>URLStream</code> instance, or a
		 * <code>File</code> instance to be used directly with a <code>FileStream</code> instance. If omitted,
		 * the <code>path</code> property must be set manually before attempting a load operation.
		 * 
		 */
		public function SwagLoader(pathRef:*=null) {			
			this.path=pathRef;
		}//constructor
		
		/**
		 * Begins a load (download) operation for the <code>SwagLoader</code> instance.
		 * <p>Unless otherwise specified, this method attempts to automatically determine the best, most robust,
		 * and most reliable transport mechanism for the load.</p>
		 *  
		 * @param pathRef The path, or an object containing a reference to the path, of the file to load. This
		 * may either be a string containing a full or partial file path or URL, a <code>URLRequest</code> instance,
		 * or a <code>File</code> instance. If this parameter is null, the already set property will be used if it was assigned
		 * in the constructor. If neither the constructor nor this method receive valid path info, the method will return <em>false</em>.
		 * @param returnType The expected return data type for the loaded. <code>SwagLoader</code> attempts to
		 * convert the loaded data to this type once loaded. While data is being loaded, it's stored in a <code>ByteArray</code>
		 * object, which is also the default <code>returnType</code> if none is specified, or the type specified isn't supported.
		 * Supported return types currently include: <code>ByteArray</code>, <code>String</code>, <code>XML</code>
		 * @param forceTransport The type of transport to use with the load, regardless of what <code>SwagLoader</code>
		 * determines to be the best one. Valid load types can be found in <code>SwagLoader</code>'s constant values,
		 * and include <code>SwagLoader.LOCALTRANSPORT</code> and <code>SwagLoader.REMOTETRANSPORT</code>.
		 * 
		 * @return <em>True</em> if the load was successfully started, <em>false</em> otherwise (for example, the 
		 * <code>path</code> is <em>null</em> or empty, or the <code>SwagLoader</code> instance reports no available transport).
		 * 
		 */
		public function load(pathRef:*=null, returnType:Class=null, forceTransport:String=null):Boolean {
			if (pathRef!=null) {
				this.path=pathRef;
			}//if
			if (this.path==null) {
				return (false);
			}//if
			this._returnType=returnType;
			if ((forceTransport==null) || (forceTransport=="")) {
				//Determine transport automatically since none was specified
				forceTransport=this.transport;
			}//if
			if (forceTransport==SwagLoader.LOCALTRANSPORT) {				
				//Using local transport					
				try {												
					if (this._path is URLRequest) {
						var fileInstance:*=File.applicationDirectory.resolvePath(URLRequest(this._path).url);
					} else if (this._path is String) {
						fileInstance=File.applicationDirectory.resolvePath(this._path);
					} else if (this._path is File) {
						//do nothing
					} else {
						return (false);
					}//else						
				} catch (error:*) {						
					return (false);
				}//catch					
				this._stream=new FileStream();
				this._stream.addEventListener(ProgressEvent.PROGRESS, this.onLoadProgress);
				this._stream.addEventListener(Event.COMPLETE, this.onLoadComplete);
				this._stream.addEventListener(IOErrorEvent.IO_ERROR, this.onLoadError);
				this._loadedBinaryData=new ByteArray();
				SwagDispatcher.dispatchEvent(new SwagLoaderEvent(SwagLoaderEvent.START), this);
				this._stream.openAsync(fileInstance, FileMode.READ);					
			} else if (forceTransport==SwagLoader.REMOTETRANSPORT) {
				//Using remote transport
				try {
					if (this._path is URLRequest) {
						//do nothing
					} else if (this._path is String) {
						var requestInstance:*=new URLRequest(this._path);
					} else if (this._path is File) {
						requestInstance=new URLRequest(this._path.url);
					} else {
						return (false);
					}//else
				} catch (error:*) {
					return (false);
				}//catch
				this._stream=new URLStream();
				this._stream.addEventListener(ProgressEvent.PROGRESS, this.onLoadProgress);
				this._stream.addEventListener(Event.COMPLETE, this.onLoadComplete);
				this._stream.addEventListener(IOErrorEvent.IO_ERROR, this.onLoadError);
				this._stream.addEventListener(HTTPStatusEvent.HTTP_STATUS, this.onLoadHTTPStatus);
				this._loadedBinaryData=new ByteArray();
				SwagDispatcher.dispatchEvent(new SwagLoaderEvent(SwagLoaderEvent.START), this);					
				URLStream(this._stream).load(requestInstance);
			} else {
				return (false);
			}//else			
			return (true);
		}//load
		
		/**
		 * Begins a send / save / upload operation for the <code>SwagLoader</code> instance.
		 * <p>Unless otherwise specified, this method attempts to automatically determine the best, most robust,
		 * and most reliable transport mechanism for the load.</p>
		 *  
		 * @param pathRef The path, or an object containing a reference to the path, of the file to save or send to. This
		 * may either be a string containing a full or partial file path or URL, a <code>URLRequest</code> instance,
		 * or a <code>File</code> instance. If this parameter is null, the already set property will be used if it was assigned
		 * in the constructor. If neither the constructor nor this method receive valid path info, the method will return <em>false</em>.
		 * @param data The data to send. May be of any type. <code>SwagLoader</code> will determine the best
		 * send method if no transport is specified.
		 * @param forceTransport The type of transport to use with the send / save, regardless of what <code>SwagLoader</code>
		 * determines to be the best one. Valid load types can be found in <code>SwagLoader</code>'s constant values,
		 * and include <code>SwagLoader.LOCALTRANSPORT</code>, <code>SwagLoader.REMOTETRANSPORTGET</code>, 
		 * <code>SwagLoader.REMOTETRANSPORTPOST</code>, and <code>SwagLoader.REMOTETRANSPORTFILE</code>.
		 * 
		 * @return <em>True</em> if the send / save was successfully started, <em>false</em> otherwise (for example, the 
		 * <code>path</code> is <em>null</em> or empty, or the <code>SwagLoader</code> instance reports no available transport).
		 * 
		 */
		public function send(pathRef:*=null, data:*=null, forceTransport:String=null):Boolean {
			if (pathRef!=null) {
				this.path=pathRef;
			}//if
			if (this.path==null) {
				return (false);
			}//if
			if (data==null) {
				return (false);
			}//if
			if ((forceTransport==null) || (forceTransport=="") || (forceTransport==SwagLoader.LOCALTRANSPORT)) {
				if ((this.transport==SwagLoader.LOCALTRANSPORT) || (forceTransport==SwagLoader.LOCALTRANSPORT)) {
					//Using local transport					
					try {												
						if (this._path is URLRequest) {
							var fileInstance:*=File.applicationDirectory.resolvePath(URLRequest(this._path).url);
						} else if (this._path is String) {
							fileInstance=File.applicationDirectory.resolvePath(this._path);
						} else if (this._path is File) {
							fileInstance=this._path;
						} else {
							return (false);
						}//else						
					} catch (error:*) {						
						return (false);
					}//catch					
					//Convert data to ByteArray if not already...
					this._sendBinaryData=new ByteArray();
					if (data is ByteArray) {						
						this._sendBinaryData=data;
					} else if (data is Bitmap) {
						var copyRect:Rectangle=new Rectangle(0, 0, data.bitmapData.width, data.bitmapData.height);
						this._sendBinaryData.writeBytes(data.getPixels(copyRect));
					} else if (data is MovieClip) {	
						if (data.loaderInfo!=null) {
							this._sendBinaryData=data.loaderInfo.bytes;
						} else {
							var event:SwagErrorEvent=new SwagErrorEvent(SwagErrorEvent.DATAEMPTYERROR);
							event.description="The MovieClip object \""+data+"\" has no no loaderInfo reference assigned to it.";
							event.remedy="Ensure that the associated MovieClip has content available through the loaderInfo property.";
							SwagDispatcher.dispatchEvent(event, this);
							return (false);
						}//else						
					} else if ((data is XML) || (data is XMLList)) {
						this._sendBinaryData.writeMultiByte(data.toXMLString(), "utf-8");
					} else {
						this._sendBinaryData.writeMultiByte(String(data), "utf-8");
					}//else
					this._stream=new FileStream();				
					this._stream.addEventListener(IOErrorEvent.IO_ERROR, this.onSendError);
					SwagDispatcher.dispatchEvent(new SwagLoaderEvent(SwagLoaderEvent.START), this);					
					this._stream.open(fileInstance, FileMode.WRITE);
					try {					
						this._sendBinaryData.position=0;
						this._stream.writeBytes(this._sendBinaryData);
						SwagDispatcher.dispatchEvent(new SwagLoaderEvent(SwagLoaderEvent.DATA), this);
						this._stream.close();
					} catch (errorObj:IOError) {
						event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
						event.code=1;
						event.description=errorObj.toString();
						event.remedy="Ensure that the file is not opened by another application and has the correct permissions."
						SwagDispatcher.dispatchEvent(event, this);
					}//catch
					SwagDispatcher.dispatchEvent(new SwagLoaderEvent(SwagLoaderEvent.COMPLETE), this);
				} else if (this.transport==SwagLoader.REMOTETRANSPORTGET) {
					trace ("SwagLoader.send() -- remote transport GET not yet implemented!");
					return (false);
				} else if (this.transport==SwagLoader.REMOTETRANSPORTPOST) {
					trace ("SwagLoader.send() -- remote transport POST not yet implemented!");
					return (false);
				} else if (this.transport==SwagLoader.REMOTETRANSPORTFILE) {
					trace ("SwagLoader.send() -- remote transport FILE not yet implemented!");
					return (false);
				} else {
					return (false);
				}//else
			} else {
				
			}//else
			return (true);
		}//send
		
		/**		 
		 * @private		 
		 */
		private function onLoadProgress(eventObj:ProgressEvent):void {			
			this._stream.readBytes(this.loadedBinaryData, this.loadedBinaryData.length);
			SwagDispatcher.dispatchEvent(new SwagLoaderEvent(SwagLoaderEvent.DATA), this);
		}//onLoadProgress
		
		/**		 
		 * @private		 
		 */
		private function onSendProgress(eventObj:ProgressEvent):void {				
			SwagDispatcher.dispatchEvent(new SwagLoaderEvent(SwagLoaderEvent.DATA), this);
		}//onSendProgress
		
		/**		 
		 * @private		 
		 */
		private function onLoadError(eventObj:IOErrorEvent):void {
			try {
				if (this._stream is FileStream) {
					this._stream.close();
				}//if		
			} catch (e:*) {				
			} finally {
				var event:SwagErrorEvent=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=1;
				event.description=eventObj.toString();
				event.remedy="Try establishing the connection again or resetting your network hardware."
				SwagDispatcher.dispatchEvent(event, this);
				this._stream.removeEventListener(ProgressEvent.PROGRESS, this.onLoadProgress);
				this._stream.removeEventListener(Event.COMPLETE, this.onLoadComplete);
				this._stream.removeEventListener(IOErrorEvent.IO_ERROR, this.onLoadError);
				this._stream.removeEventListener(HTTPStatusEvent.HTTP_STATUS, this.onLoadHTTPStatus);
				//TODO: handle the error
			}//finally
		}//onLoadError
		
		/**		 
		 * @private		 
		 */
		private function onSendError(eventObj:IOErrorEvent):void {			
			var event:SwagErrorEvent=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
			event.code=1;
			event.description=eventObj.toString();
			event.remedy="Try establishing the connection again or, if sending locally, verify that the file is not open in another application ";
			event.remedy+="and that the file permissions are correct.";
			SwagDispatcher.dispatchEvent(event, this);
			this._stream.removeEventListener(ProgressEvent.PROGRESS, this.onSendProgress);
			this._stream.removeEventListener(Event.COMPLETE, this.onSendComplete);
			this._stream.removeEventListener(IOErrorEvent.IO_ERROR, this.onSendError);			
			this._stream.removeEventListener(HTTPStatusEvent.HTTP_STATUS, this.onSendHTTPStatus);
			//TODO: handle the error
		}//onSendError
		
		/**		 
		 * @private		 
		 */
		private function onLoadComplete(eventObj:Event):void {	
			if (FileStream != null) {
				if (this._stream is FileStream) {
					this._stream.close();
				}//if
			}//if
			if (this.loadedBinaryData!=null) {	
				var loadCompleted:Boolean=true;
				if (this._returnType==String) {
					this._loadedData=new String(String(this._loadedBinaryData.toString()));
				} else if (this._returnType==XML) {
					this._loadedData=new XML(String(this._loadedBinaryData.toString()));
				} else if (this._returnType==ByteArray) {
					this._loadedData=this._loadedBinaryData;
				} else if ((this._returnType==Bitmap) || (this._returnType==MovieClip)) {
					loadCompleted=false;
					this._uiObjectLoader=new Loader();
					this._uiObjectLoader.contentLoaderInfo.addEventListener(Event.INIT, this.onUIObjectLoadComplete);
					this._uiObjectLoader.loadBytes(this._loadedBinaryData);					
				} else {
					//Default to ByteArray
					this._loadedData=this._loadedBinaryData;
				}//else
			}//if
			this._stream.removeEventListener(ProgressEvent.PROGRESS, this.onLoadProgress);
			this._stream.removeEventListener(Event.COMPLETE, this.onLoadComplete);
			this._stream.removeEventListener(IOErrorEvent.IO_ERROR, this.onLoadError);
			this._stream.removeEventListener(HTTPStatusEvent.HTTP_STATUS, this.onLoadHTTPStatus);
			if (loadCompleted) {
				SwagDispatcher.dispatchEvent(new SwagLoaderEvent(SwagLoaderEvent.COMPLETE), this);
			}//if
		}//onLoadComplete
		
		/**		 
		 * Extra step used for <code>Bitmap</code> and <code>MovieClip</code> loads.
		 * 
		 * @private		 
		 */
		private function onUIObjectLoadComplete(eventObj:Event):void {
			this._uiObjectLoader.contentLoaderInfo.removeEventListener(Event.INIT, this.onUIObjectLoadComplete);
			this._loadedData=this._uiObjectLoader.content;
			SwagDispatcher.dispatchEvent(new SwagLoaderEvent(SwagLoaderEvent.COMPLETE), this);
		}//onUIObjectLoadComplete
		
		/**		 
		 * @private		 
		 */
		private function onSendComplete(eventObj:Event):void {			
			this._stream.removeEventListener(ProgressEvent.PROGRESS, this.onSendProgress);
			this._stream.removeEventListener(Event.COMPLETE, this.onSendComplete);
			this._stream.removeEventListener(IOErrorEvent.IO_ERROR, this.onSendError);
			this._stream.removeEventListener(HTTPStatusEvent.HTTP_STATUS, this.onSendHTTPStatus);
			SwagDispatcher.dispatchEvent(new SwagLoaderEvent(SwagLoaderEvent.COMPLETE), this);
		}//onSendComplete
		
		/**		 
		 * @private		 
		 */
		private function onLoadHTTPStatus(eventObj:HTTPStatusEvent):void {
			this._stream.close();
			if (eventObj.status==400) {
				var event:SwagErrorEvent=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=400;
				event.description="The server request was bad or malformed.";
				event.remedy="The network connection may be unstable. Try resetting the network hardware."
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==401) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=401;
				event.description="The request was not authorized.";
				event.remedy="A \"WWW-Authenticate\" field should be added to the request header (see RFC2616 Section 14)."
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==402) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=402;
				event.description="The server requires payment for this transaction.";
				event.remedy="This is most likely a paid resource and is restricted. Contact the site owner for more information."
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==403) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=403;
				event.description="Access to \""+this.path+"\" is forbidden.";
				event.remedy="This is most often cause by access or security restrictions on the server (see \".htaccess\")."
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==404) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=404;
				event.description="The path \""+this.path+"\" could not be found (server returned code 404).";
				event.remedy="Check the path and try loading the data again."
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==405) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=405;
				event.description="The method specified in the request \"Request-Line\" header is not allowed.";
				event.remedy="Check the sending header information to ensure that this value is correct."
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==406) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=406;
				event.description="The requesting header information is not acceptable.";
				event.remedy="Check the sending header information to ensure that it is correct and valid."
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==407) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=407;
				event.description="Proxy authentication required.";
				event.remedy="You are connecting to a proxy that requires authentication. Examine the \" Proxy-Authenticate\" header field. "
				event.remedy+="Further information on proxy authentication can be found at RFC2616 section 14."
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==408) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=408;
				event.description="The request has timed out.";
				event.remedy="Check your connection and route (using ping, for example), to see where the timeout may be occurring."				
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==409) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=409;
				event.description="The request is in a conflicted state.";
				event.remedy="A previous transaction may have been left opened or incomplete. Contact the server administrator for details."				
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==410) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=410;
				event.description="The path \""+this.path+"\" is gone.";
				event.remedy="This error does not provide forwarding information so the request should be assumed to be invalid in the future."				
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==411) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=411;
				event.description="The request requires a \"Content-Length\" header field.";
				event.remedy="Include this header field, including valid content length, in the header of the request."				
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==412) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=412;
				event.description="One or more request headers was invalid.";
				event.remedy="The server expected headers that were either missing or badly formatted. Contact the server administrator ";
				event.remedy+="for more information.";				
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==413) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=413;
				event.description="The request was too large.";
				event.remedy="Try reducing the size of the data being sent or, of not possible, contact the server administrator ";
				event.remedy+="to establish some other data-chunking system so that individual requests can be shortened.";
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==414) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=414;
				event.description="The request URI was too long.";
				event.remedy="Try reducing the size of the URI / URL being requested.";				
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==415) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=415;
				event.description="The media type being sent or requested is unsupported.";
				event.remedy="Contact the server administrator about supported media types and potentially updating the server's ";
				event.remedy+="MIME types.";
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==416) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=416;
				event.description="The \"Range\" value in the request header is not valid.";
				event.remedy="Change the \"Range\" value in the request header to a valid value.";				
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==417) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=417;
				event.description="The \"Expect\" value in the request header is not valid.";
				event.remedy="Change the \"Expect\" value in the request header to a valid value.";				
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==500) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=500;
				event.description="Internal server error.";
				event.remedy="The most common cause of this error is a misconfigured server-side language ";
				event.remedy+="or other problem when executing server-side code.";
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==501) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=501;
				event.description="Unsupported operation.";
				event.remedy="The server doesn't know how to handle this type of request.";				
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==502) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=502;
				event.description="The server proxying your request received a bad response from an upstream server.";
				event.remedy="Check the server logs to see what kinds of errors the server is receiving. These will typically ";
				event.remedy+="be 400/500-series errors similar to ones received on the client and will reveal more information ";
				event.remedy+="on the source of this issue.";
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==504) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=504;
				event.description="The server proxying your request has timed out.";
				event.remedy="The upstream server may be having intermitent issues. Try reconnecting or, failing that ";
				event.remedy+="contact the upstream server's administrator.";
				SwagDispatcher.dispatchEvent(event, this);
			}//if
			if (eventObj.status==505) {
				event=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				event.code=505;
				event.description="HTTP version requested is not supported on this server.";
				event.remedy="Try changing the HTTP version in the request header to a standard one (1.1, for example) ";
				event.remedy+="or contact the server administrator with the issue.";
				SwagDispatcher.dispatchEvent(event, this);
			}//if
		}//onLoadHTTPStatus
		
		/**		 
		 * @private		 
		 */
		private function onSendHTTPStatus(eventObj:HTTPStatusEvent):void {	
		}//onSendHTTPStatus
		
		/**
		 * The instance of the data streaming object (<code>URLStream</code> or <code>FileStream</code> instance, depending on 
		 * the runtime), being used to most stream data for this <code>SwagLoader</code> instance.
		 * <p>This value will be <em>null</em> until a load or send operation has been started.</p>
		 */
		public function get stream():* {
			return (this._stream);
		}//get stream
		
		/**
		 * The file path associated with this <code>SwagLoader</code> instance (i.e. the path to the file to be 
		 * downloaded / uploaded).
		 * <p>This value may either be a string which will be analyzed for the most appropriate transport method 
		 * (i.e. using Flash or AIR routines depending on the runtime), a <code>URLRequest</code> instance which
		 * will use <code>URLStream</code> by default, or a <code>File</code> instance which will use 
		 * <code>FileStream</code> by default. The transport method (<code>URLStream</code> or <code>FileStream</code>),
		 * can be changed manually if desired.</p>
		 * 
		 */
		public function get path():* {
			return (this._path);
		}//get path
		
		public function set path(pathSet:*):void {
			this._path=pathSet;			
		}//set path
		
		/**
		 * The raw loaded binary data for the <code>SwagLoader</code> instance.
		 * <p>This object contains all the data loaded by <code>SwagLoader</code> so far. Because
		 * this data may be read during a load operation, it should not be assumed to be complete
		 * until <code>SwagLoader</code> dipatches its completion event.</p>
		 * <p>If no load operation has been started yet, this object will be <em>null</em>.</p>
		 * 
		 */
		public function get loadedBinaryData():ByteArray {
			return (this._loadedBinaryData);
		}//get loadedBinaryData	
		
		/**
		 * The raw binary data used by the <code>SwagLoader</code> instance when sending.
		 * <p>This is typically used when data is being written to a file during local transport operations.</p>
		 * <p>If no send operation has been started yet, this object will be <em>null</em>.</p>
		 * 
		 */
		public function get sendBinaryData():ByteArray {
			return (this._sendBinaryData);
		}//get sendBinaryData	
		
		/**
		 * @return A reference to the data loaded by the <code>SwagLoader</code> instance in its native format,
		 * as specified when the load operation was started.
		 * <p>If a load hasn't completed or started yet, this value will be <em>null</em>.</p> 		 
		 */
		public function get loadedData():* {
			return (this._loadedData);
		}//get loadedData
		
		/**
		 * Identifies the type of transport being used to load the file data.
		 * <p>The valid transport types (currently local, or AIR, and remote, or URL),
		 * can be found as class constants of the <code>SwagLoader</code> class.		 
		 */
		public function get transport():String {
			if (this.path==null) {
				return (SwagLoader.NOTRANSPORT);
			}//if
			if (this.path is String) {
				var localPath:String=new String(this.path);				
			} else if (this.path is URLRequest) {
				localPath=new String(URLRequest(this.path).url);
			} else if (this.path is File) {
				localPath=new String(File(this.path).url);
			}//else if
			localPath=SwagDataTools.stripOutsideChars(localPath, SwagDataTools.SEPARATOR_RANGE+SwagDataTools.PUNCTUATION_RANGE);
			var transportString:String=SwagDataTools.getStringBefore(localPath, ":", false);
			//No transport specified...
			if ((transportString==null) || (transportString=="")) {
				if (SwagSystem.isAIR) {
					return (SwagLoader.LOCALTRANSPORT);
				} else {
					return (SwagLoader.REMOTETRANSPORT);
				}//else
			} else {
				//Transport is a local file URL or a local file path (starting with a drive letter).
				if ((transportString=="file") || (transportString=="app-storage") 
				  || (transportString=="app") || (transportString.length==1)) {
					if (SwagSystem.isAIR) {
						return (SwagLoader.LOCALTRANSPORT);
					} else {
						return (SwagLoader.REMOTETRANSPORT);
					}//else
				} else {
					return (SwagLoader.REMOTETRANSPORT);
				}//else
				return (SwagLoader.NOTRANSPORT);
			}//else
			return (SwagLoader.NOTRANSPORT);
		}//get transport
		
		/**
		 * The total bytes loaded for the <code>SwagLoader</code> instance.
		 * <p>If no load operation has been started, or if no data has yet been loaded, this value will
		 * be 0.</code>		 
		 * 
		 */
		public function get bytesLoaded():uint {
			var returnValue:uint=new uint();
			returnValue=0;
			if (this.loadedBinaryData!=null) {
				returnValue=this.loadedBinaryData.length;
			}//if
			return (returnValue)
		}//get bytesLoaded
		
		/**
		 * Extracts a file name from a specified path string. The path may either be a <code>File</code> reference
		 * or a string, and may either be a fully path, a partial (relative path), or simply a file name.
		 * 
		 * @param fileName The file path or <code>File</code> instance containing the path with the file name.
		 * @param includeExtension If <em>true</em>, the file extension is also included in the file name, otherwise
		 * just the filename prefix will be returned.
		 * 
		 * @return The file name, including extension (if specified), of the file found in the associated parameter, or an
		 * empty string if no file name could be found.
		 * 
		 */
		public static function getFileName(fullPath:*=null, includeExtension:Boolean=true):String {
			var fileName:String=new String();
			if (fullPath==null) {
				return (fileName);
			}//if
			if (fullPath is File) {				
				fileName=fullPath.url;
			} else if (fullPath is String) {
				fileName=fullPath;
			} else {
				return (fileName);
			}//else
			//Replace any forward slashes with bag slashes for consistency
			fileName=SwagDataTools.replaceString(fileName, "/", "\\");
			var finalSlashPosition:int=fileName.lastIndexOf("/");
			if (finalSlashPosition>-1) {				
				fileName=fileName.substr((finalSlashPosition+1), fileName.length);
			}//if
			if (!includeExtension) {
				var periodPosition:int=fileName.lastIndexOf(".");
				if (periodPosition>-1) {				
					fileName=fileName.substring(0, periodPosition);
				}//if
			}//if
			return (fileName);
		}//getFileName
		
		/**
		 * Extracts the file extension (the part after the last period) for the specified file or path.
		 *  
		 * @param fullPath A file path, full or partial (relative), as a string or <code>File</code> instance containing
		 * a valid file name.
		 * 
		 * @return The extension, or part after the final period (not including the period) of the file name, or a blank string
		 * if no valid file name could be found in the path. 
		 * 
		 */
		public static function getFileExtension(fullPath:*=null):String {			
			var fileExtension:String=new String();			
			var fileName:String=getFileName(fullPath, true);			
			if (fileName=="") {				
				return (fileExtension);
			}//if			
			var periodPosition:int=fileName.lastIndexOf(".");
			if (periodPosition>-1) {				
				fileExtension=fileName.substr((periodPosition+1), fileName.length);
			}//if
			return (fileExtension);
		}//getFileExtension
		
		
		/**
		 * Resolves the specified file name to a <code>File</code> reference pointing to the user's
		 * desktop directory.
		 * 
		 * @param fileName The file name to resolve the desktop-relative path for.
		 * 
		 * @return A <code>File</code> reference pointing to the file within the user's desktop directory. If
		 * the application isn't running as an AIR instance, <em>null</em> is returned. 
		 * 
		 */
		public static function resolveToDesktop(fileName:String=null):* {
			if (File==null) {
				return (null);
			}//if
			var fileInstance:*=File.desktopDirectory;
			if ((fileName!="") && (fileName!=null)) {
				fileInstance=fileInstance.resolvePath(fileName);
			}//if;
			return (fileInstance);
		}//resolveToDesktop
		
		/**
		 * Resolves the specified file name to a <code>File</code> reference pointing to the user's
		 * documents directory.
		 * 
		 * @param fileName The file name to resolve the documents-relative path for.
		 * 
		 * @return A <code>File</code> reference pointing to the file within the user's documents directory. If
		 * the application isn't running as an AIR instance, <em>null</em> is returned. 
		 * 
		 */
		public static function resolveToDocuments(fileName:String=null):* {
			if (File==null) {
				return (null);
			}//if
			var fileInstance:*=File.documentsDirectory;
			if ((fileName!="") && (fileName!=null)) {
				fileInstance=fileInstance.resolvePath(fileName);
			}//if
			return (fileInstance);
		}//resolveToDocuments
		
		/**
		 * Resolves the specified file name to a <code>File</code> reference pointing to the user's
		 * directory (typically the parent of the documents directory).
		 * 
		 * @param fileName The file name to resolve the user-relative path for.
		 * 
		 * @return A <code>File</code> reference pointing to the file within the user's directory. If
		 * the application isn't running as an AIR instance, <em>null</em> is returned. 
		 * 
		 */
		public static function resolveToUser(fileName:String=null):* {
			if (File==null) {
				return (null);
			}//if
			var fileInstance:*=File.userDirectory;
			if ((fileName!="") && (fileName!=null)) {
				fileInstance=fileInstance.resolvePath(fileName);
			}//if
			return (fileInstance);
		}//resolveToUser
		
		/**
		 * Resolves the specified file name to a <code>File</code> reference pointing to the application's
		 * installation directory. This is the same as prepending the "app:" URL scheme to file names.
		 * 
		 * @param fileName The file name to resolve the application installation-relative path for.
		 * 
		 * @return A <code>File</code> reference pointing to the file within the application's installation directory. If
		 * the application isn't running as an AIR instance, <em>null</em> is returned. Note that this directory is
		 * typically read-only.
		 * 
		 */
		public static function resolveToApplication(fileName:String=null):* {
			if (File==null) {
				return (null);
			}//if
			var fileInstance:*=File.applicationStorageDirectory;
			if ((fileName!="") && (fileName!=null)) {
				fileInstance=fileInstance.resolvePath(fileName);
			}//if
			return (fileInstance);
		}//resolveToApplication
		
		/**
		 * Resolves the specified file name to a <code>File</code> reference pointing to the application's
		 * storage directory. This is the same as prepending the "app-storage:" URL scheme to file names.
		 * 
		 * @param fileName The file name to resolve the application storage-relative path for.
		 * 
		 * @return A <code>File</code> reference pointing to the file within the application's storage directory. If
		 * the application isn't running as an AIR instance, <em>null</em> is returned. 
		 * 
		 */
		public static function resolveToAppStorage(fileName:String=null):* {
			if (File==null) {
				return (null);
			}//if
			var fileInstance:*=File.applicationStorageDirectory;
			if ((fileName!="") && (fileName!=null)) {
				fileInstance=fileInstance.resolvePath(fileName);
			}//if
			return (fileInstance);
		}//resolveToAppStorage
		
		/**
		 * @private 
		 * 
		 * Returns an instance of an AIR File class if the current runtime supports it, or <em>null</em>
		 * if the current runtime isn't AIR.
		 */
		public static function get File():Class {
			try {
				var classRef:Class=getDefinitionByName("flash.filesystem.File") as Class;
				return (classRef);
			} catch (e:ReferenceError) {
				return (null);	
			}//catch
			return (null);
		}//get File
		
		/**
		 * @private 
		 * 
		 * Returns an instance of an AIR FileStream class if the current runtime supports it, or <em>null</em>
		 * if the current runtime isn't AIR.
		 */
		public static function get FileStream():Class {
			try {
				var classRef:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
				return (classRef);
			} catch (e:ReferenceError) {
				return (null);	
			}//catch
			return (null);
		}//get FileStream
		
		/**
		 * @private 
		 * 
		 * Returns an instance of an AIR FileMode class if the current runtime supports it, or <em>null</em>
		 * if the current runtime isn't AIR.
		 */
		public static function get FileMode():Class {
			try {
				var classRef:Class=getDefinitionByName("flash.filesystem.FileMode") as Class;
				return (classRef);
			} catch (e:ReferenceError) {
				return (null);	
			}//catch
			return (null);
		}//get FileMode
		
	}//SwagLoader class
	
}//package