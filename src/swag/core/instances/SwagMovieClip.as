package swag.core.instances {
	
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import socialcastr.References;
	
	import swag.core.SwagDispatcher;
	import swag.events.SwagMovieClipEvent;
	import swag.interfaces.core.instances.ISwagMovieClip;
	
	/**
	 * Extends and enhances the standard Flash MovieClip object.
	 * <p>SwagMovieClip aims to add to the standard MovieClip functionality through things like greater playback control, 
	 * frame beacons (events dispatched when the movie clip reaches a certain frame), and so on.</p>
	 * <p>The <code>SwagMovieClip</code> class may either be extended by a <code>MovieClip</code> object, or
	 * it may be referenced and controlled externally by updating this class' <code>target</code> property.</p>
	 * <p><strong>N.B.</strong>: Unless your class is extending the <code>SwagMovieClip</code> class, you must <strong>always</strong> 
	 * reference the <code>target</code> property instead of this instance's inherited properties since <code>target</code> and 
	 * <code>this</code> <strong>will not</strong> be the same object!</p>
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
	public class SwagMovieClip extends MovieClip implements ISwagMovieClip {
		
		/**
		 * @private 
		 */
		private var _target:MovieClip=null;
		/**
		 * @private 
		 */
		private var _ready:Boolean=false;
		/**
		 * @private 
		 */
		private var _rangeStart:int=1;
		/**
		 * @private 
		 */
		private var _rangeEnd:int=1;
		/**
		 * @private 
		 */
		private var _rangeReset:Boolean=false;
		
		
		/**
		 * Default constructor for the class.
		 *  
		 * @param targetClip The target <code>MovieClip</code> to associate with this class instance. If this
		 * value is <em>null</em> and is not later assigned via the <code>target</code> property,
		 * it is assumed that the target is <code>this</code> (i.e. the extending MovieClip class).
		 * 
		 */
		public function SwagMovieClip(targetClip:MovieClip=null) {
			this._target=targetClip;			
			super();
		}//constructor
		
		/**
		 * Swaps the associated <code>MovieClip</code> instance with the top-most MovieClip in the parent container.
		 * <p>This is similar to calling the <code>swapChildrenAt</code> method except that there's no
		 * need to retrieve the index values of either this instance or the target (swapping with), instance.</p>  
		 * 
		 */
		public function swapWithTop():void {
			if (this.target==null) {
				return;
			}//if
			if (this.target.parent==null) {
				return;
			}//if
			var swapIndex:int=this.target.parent.numChildren-1;
			try {
				this.target.parent.setChildIndex(this.target, swapIndex);
			} catch (error:*) {
				if (error is RangeError) {
					//Index isn't correct
				} else if (error is ArgumentError) {
					//Target isn't a child of the container
				} else {
					
				}//else
			}//catch
		}//swapWithTop
		
		/**
		 * Plays the associated movie between specified frames. If no movie clip has been associated with this
		 * class instance, nothing will happen.
		 *  
		 * @param startFrame The frame label or frame number to begin the playback at. If this frame comes after the
		 * <code>endFrame</code>, the movie clip will play backwards.
		 * @param endFrame The frame label or frame number to end the playback at. If this frame comes before  the
		 * <code>startFrame</code>, the movie clip will play backwards.
		 * @param resetOnEnd If <em>true</em>, the associated movie clip will reset back to the start of the range,
		 * otherwise (<em>false</em>), it will stop on the ending frame. 
		 * 
		 * @return <em>True</em> if the animation was successfully started, <em>false</em> if it was not (the frames
		 * specified were out of range or otherwise invalid).
		 * 
		 */
		public function playRange(startFrame:*, endFrame:*, resetOnEnd:Boolean=false):Boolean {
			if (this.target==null) {
				return (false);
			}//if
			this._rangeStart=this.findFrame(startFrame);			
			this._rangeEnd=this.findFrame(endFrame);			
			if ((this._rangeStart==0) || (this._rangeEnd==0)) {
				return (false);
			}//if
			var event:SwagMovieClipEvent=new SwagMovieClipEvent(SwagMovieClipEvent.START);
			SwagDispatcher.dispatchEvent(event, this);
			if (this._rangeStart==this._rangeEnd) {
				this.target.gotoAndStop(this._rangeStart);
				event=new SwagMovieClipEvent(SwagMovieClipEvent.END);
				SwagDispatcher.dispatchEvent(event, this);
			} else {				
				this._rangeReset=resetOnEnd;
				this.target.gotoAndStop(this._rangeStart);
				this.target.addEventListener(Event.ENTER_FRAME, this.frameMonitor);
			}//else
			return (true);
		}//playRange
		
		/**
		 * Plays a range a frames starting at a sepcific location until a label frame is encountered.
		 * <p>If the specified label frame doesn't exist, the associated movie clip will play to the end.<p>
		 * 
		 * @param startFrame The starting frame label or name at which to begin playback.
		 * @param includeLabelFrame If <em>true</em>, the labelled frame will be included in the playback range. 
		 * If <em>false</em>, the frame before the label frame will be the end of the range. If no labelled frame can
		 * be found before the end of the clip, the playback range will always include the last frame of the clip.		 * 
		 * @param resetOnEnd If <em>true</em>, the associated movie clip will reset back to the start of the range,
		 * otherwise (<em>false</em>), it will stop on the ending frame. 
		 * 
		 * @return <em>True</em> if the animation was successfully started, <em>false</em> if it was not (the frame
		 * specified were out of range or otherwise invalid).
		 * 
		 */
		public function playToNextLabel(startFrame:*, includeLabelFrame:Boolean=false, resetOnEnd:Boolean=false):Boolean {
			this._rangeStart=this.findFrame(startFrame);			
			this._rangeEnd=this.findFrameLabelAfter(this._rangeStart, includeLabelFrame);
			if ((this._rangeStart==0) || (this._rangeEnd==0)) {				
				return (false);
			}//if
			var event:SwagMovieClipEvent=new SwagMovieClipEvent(SwagMovieClipEvent.START);
			SwagDispatcher.dispatchEvent(event, this);			
			if (this._rangeStart==this._rangeEnd) {	
				this.target.gotoAndStop(this._rangeStart);
				event=new SwagMovieClipEvent(SwagMovieClipEvent.END);
				SwagDispatcher.dispatchEvent(event, this);
			} else {
				if (this.target==this) {				
					super.gotoAndStop(this._rangeStart);
					this._rangeReset=resetOnEnd;				
					super.addEventListener(Event.ENTER_FRAME, this.frameMonitor);
				} else if (this.target!=null) {
					this.target.gotoAndStop(this._rangeStart);
					this._rangeReset=resetOnEnd;				
					this.target.addEventListener(Event.ENTER_FRAME, this.frameMonitor);
				} else {
					return (false);
				}//else
			}//else
			return (true);			
		}//playToNextLabel
		
		/**
		 * Stops playback of the associated MovieClip object. This is the same as calling <code>stop</code>
		 * on the movie clip itself but this method also broadcasts a <code>SwagMovieClipEvent.END</code> event.
		 */
		override public function stop():void {
			if (this.target==this) {
				super.stop();
			} else {
				this.target.stop();
			}//else
		}//stop
		
		/**
		 * Goes to a specific frame in the associated MovieClip object. This is the same as calling <code>gotoAndStop</code>
		 * on the movie clip itself but this method also broadcasts a <code>SwagMovieClipEvent.END</code> event.
		 * 
		 * @param frame The target frame to place the movie clip at.
		 */
		override public function gotoAndStop(frame:Object, scene:String = null):void {
			if (this.target==this) {
				super.gotoAndStop(frame, scene);
			} else {
				this.target.gotoAndStop(frame, scene);
			}//else
		}//gotoAndStop
		
		/**
		 * Starts playback of the associated MovieClip object. This is the same as calling <code>play</code>
		 * on the movie clip itself but this method also broadcasts a <code>SwagMovieClipEvent.START</code> event.
		 */
		override public function play():void {
			if (this.target==this) {
				super.play();
			} else {
				this.target.play();
			}//else
			var event:SwagMovieClipEvent=new SwagMovieClipEvent(SwagMovieClipEvent.START);
			SwagDispatcher.dispatchEvent(event, this);
		}//play
		
		/**
		 * Goes to a specific frame in the associated MovieClip object and begins playback. This is the same as calling 
		 * <code>gotoAndPlay</code> on the movie clip itself but this method also broadcasts a <code>SwagMovieClipEvent.START</code>
		 * event.
		 * 
		 * @param frame The target frame to place the movie clip at and begin playback.
		 */
		override public function gotoAndPlay(frame:Object, scene:String = null):void {
			if (this.target==this) {
				super.gotoAndPlay(frame, scene);
			} else {
				this.target.gotoAndPlay(frame, scene);
			}//else
			var event:SwagMovieClipEvent=new SwagMovieClipEvent(SwagMovieClipEvent.START);
			SwagDispatcher.dispatchEvent(event, this);
		}//gotoAndPlay
		
		/**
		 * Monitors the frame playback for the associated movie clip.
		 *  
		 * @private
		 * 
		 */
		private function frameMonitor (eventObj:Event):void {
			if (this.target==null) {
				return;
			}//if
			var currentFrame:int=this.target.currentFrame;
			if (this._rangeStart<this._rangeEnd) {
				//play forward
				if (currentFrame<this._rangeEnd) {
					currentFrame++;	
					this.target.gotoAndStop(currentFrame);
					var event:SwagMovieClipEvent=new SwagMovieClipEvent(SwagMovieClipEvent.FRAME);
					SwagDispatcher.dispatchEvent(event, this);
					return;
				} else {
					this.target.gotoAndStop(this._rangeEnd);
					event=new SwagMovieClipEvent(SwagMovieClipEvent.END);
					SwagDispatcher.dispatchEvent(event, this);
					this.target.removeEventListener(Event.ENTER_FRAME, this.frameMonitor);
					return;
				}//else
			} else {
				//play backwards
				if (currentFrame>this._rangeEnd) {
					currentFrame--;
					this.target.gotoAndStop(currentFrame);
					event=new SwagMovieClipEvent(SwagMovieClipEvent.FRAME);
					SwagDispatcher.dispatchEvent(event, this);
					return;
				} else {
					this.target.gotoAndStop(this._rangeEnd);
					event=new SwagMovieClipEvent(SwagMovieClipEvent.END);
					SwagDispatcher.dispatchEvent(event, this);
					this.target.removeEventListener(Event.ENTER_FRAME, this.frameMonitor);
					return;
				}//else
			}//else
			this.target.removeEventListener(Event.ENTER_FRAME, this.frameMonitor);
		}//frameMonitor
		
		/**
		 * Finds a frame specified either by a label or by a frame number. If the frame is a label,
		 * this function returns the frame number of that label. If the specified frame is a number,
		 * it's range-checked to ensure that it's larger than 0 and less than or equal to the maximum frames 
		 * in the clip. 
		 * The function returns 0 only if the target clip hasn't been specified yet or if the frame parameter
		 * is not of a recognized type.
		 * @private 
		 * 
		 */
		private function findFrame(frame:*):int {
			if (this.target==null) {
				return (0);
			}//if
			//Range check the starting frame if it's a number...
			if ((frame is int) || (frame is uint) || (frame is Number)) {
				if (frame < 1) {
					return (1);
				}//if
				if (frame > this.target.totalFrames) {
					return (this.target.totalFrames);
				}//if
				return (int(frame));
			}//if
			//Find the starting frame if it's a label...
			if (frame is String) {				
				var labelString:String=new String();
				labelString=frame;			
				labelString=labelString.toLowerCase();			
				for (var count:uint=0; count<this.target.currentLabels.length; count++) {
					var labelObj:FrameLabel=this.target.currentLabels[count] as FrameLabel;
					var currentLabelString:String=new String();				
					currentLabelString=labelObj.name;
					currentLabelString=currentLabelString.toLowerCase();
					if (labelString==currentLabelString) {
						return (labelObj.frame);
					}//if
				}//for				
				//Frame not found, return current one
				return (this.target.currentFrame);
			}//if
			return (0);
		}//findFrame
		
		/**
		 * Finds the first labelled frame after the specified frame number, or the final frame of the animation if
		 * no matching labelled frame can be found.
		 * <p>A 0 index is returned only if the target clip has not yet been assigned.</p> 
		 * @private 
		 * 
		 */
		private function findFrameLabelAfter(startFrame:*, includeLabelFrame:Boolean=false):int {			
			if (this.target==null) {
				return (0);
			}//if
			var beginFrame:int=new int(this.target.totalFrames);
			//Range check the starting frame if it's a number...
			if ((startFrame is int) || (startFrame is uint) || (startFrame is Number)) {				
				if (startFrame < 1) {
					beginFrame=1;
				} else if (startFrame > this.target.totalFrames) {
					beginFrame=this.target.totalFrames;
				} else {
					beginFrame=startFrame;
				}//else
			}//if		
			//Find the starting frame if it's a label...
			if (startFrame is String) {								
				var labelString:String=new String();
				labelString=startFrame;			
				labelString=labelString.toLowerCase();			
				for (var count:int=0; count<this.target.currentLabels.length; count++) {
					var labelObj:FrameLabel=this.target.currentLabels[count] as FrameLabel;
					var currentLabelString:String=new String();				
					currentLabelString=labelObj.name;
					currentLabelString=currentLabelString.toLowerCase();
					if (labelString==currentLabelString) {
						beginFrame=labelObj.frame;						
					}//if
				}//for							
			}//if						
			var returnFrame:int=new int();
			returnFrame=beginFrame;			
			var frameFound:Boolean=false;
			//Run backwards through existing labels...					
			for (count=(this.target.currentLabels.length-1); count>=0; count--) {
				labelObj=this.target.currentLabels[count] as FrameLabel;
				if (labelObj!=null) {
					if (labelObj.frame>beginFrame) {
						returnFrame=labelObj.frame;
						frameFound=true;
					}//if
				}//if
			}//for	
			if ((!includeLabelFrame) && frameFound) {
				returnFrame--;
			}//if
			if (!frameFound) {
				//If no frame found, return the end frame...
				returnFrame=this.target.totalFrames;
			}//if
			if (returnFrame<1) {
				returnFrame=1;
			}//if
			return (returnFrame);
		}//findFrameLabelAfter
		
		/**
		 * The target <code>MovieClip</code> instance that SwagMovieClip is to control. 
		 * <p>By assigning a target, the specified <code>MovieClip</code> doesn't need to
		 * extend the <code>SwagMovieClip</code> class. Setting this value to <em>null</em>
		 * instructs <code>SwagMovieClip</code> to use itself or any extending class.</p>
		 * <p>Unless your class is extending the <code>SwagMovieClip</code> class, you must
		 * <strong>always</strong> reference the <code>target</code> property instead of
		 * this instance's properties since <code>target</code> and <code>this</code>
		 * <strong>will not</strong> be the same object!</p>
		 * 
		 */
		public function set target(targetSet:MovieClip):void {			
			this._target=targetSet;			
		}//set target
		
		public function get target():MovieClip {
			if ((this._target==this) || (this._target==null)) {
				return (this);
			} else {
				return (this._target);
			}//else
		}//get target	
		
	}//SwagMovieClip class
	
}//package