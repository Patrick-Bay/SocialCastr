package socialcastr.core.timeline {
	
	import socialcastr.References;
	import socialcastr.core.Timeline;
	import socialcastr.core.TimelineElement;
	import socialcastr.core.timeline.TimelineInvokeConstants;
	import socialcastr.events.TimelineEvent;
	import socialcastr.interfaces.core.timeline.IBaseTimelineEffect;
	import socialcastr.ui.panels.ChannelPlayerPanel;
	
	import swag.core.SwagDispatcher;
	
	/**
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
	public class StreamControlEffect extends BaseTimelineEffect	{
		
		public function StreamControlEffect(effectTarget:*)	{			
			super(effectTarget);
		}//contructor
		
		override public function onTimelineInvoke(eventObj:TimelineEvent):void {
			try {
				if (this.target is ChannelPlayerPanel) {					
					switch (eventObj.invoke) {
						case TimelineInvokeConstants.VIDEO_START_LIVESTREAM:
							References.debug("StreamControlEffect invoked via \""+eventObj.invoke+"\"; starting video playback.");							
							ChannelPlayerPanel(this.target).startVideoPlayBack(eventObj);
							break;
						case TimelineInvokeConstants.AUDIO_START_LIVESTREAM:
							References.debug("StreamControlEffect invoked via \""+eventObj.invoke+"\"; starting audio playback.");
							ChannelPlayerPanel(this.target).startAudioPlayback(eventObj);
							break;
						case TimelineInvokeConstants.VIDEO_START_RECSTREAM:
							References.debug("StreamControlEffect invoked via \""+eventObj.invoke+"\"; starting video playback.");							
							ChannelPlayerPanel(this.target).startVideoPlayBack(eventObj);
							break;
						case TimelineInvokeConstants.AUDIO_START_RECSTREAM:
							References.debug("StreamControlEffect invoked via \""+eventObj.invoke+"\"; starting audio playback.");
							ChannelPlayerPanel(this.target).startAudioPlayback(eventObj);
							break;
						default: break;
					}//switch
				}//if
			} catch (e:*) {				
			}//catch
		}//onTimelineInvoke		
		
	}//StreamControlEffect class
	
}//package