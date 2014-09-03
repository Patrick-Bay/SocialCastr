package socialcastr.core.timeline {
	
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
	public class TimelineInvokeConstants {
		
		/**
		 * Invoked by the broadcaster to initiate a live video stream. Payload XML data associated
		 * with the <code>TimelineEvent</code> describes the stream.
		 */
		public static const VIDEO_START_LIVESTREAM:String="TimelineInvoke.AV.VIDEO_START_LIVESTREAM";
		/**
		 * Invoked by the broadcaster to stop a live video stream. Payload XML data associated
		 * with the <code>TimelineEvent</code> describes the stream.
		 */
		public static const VIDEO_STOP_LIVESTREAM:String="TimelineInvoke.AV.VIDEO_STOP_LIVESTREAM";
		/**
		 * Invoked by the broadcaster to initiate a recorded (shared) video stream. Payload XML data associated
		 * with the <code>TimelineEvent</code> describes the stream.
		 */
		public static const VIDEO_START_RECSTREAM:String="TimelineInvoke.AV.VIDEO_START_RECSTREAM";
		/**
		 * Invoked by the broadcaster to stop a recorded (shared) video stream. Payload XML data associated
		 * with the <code>TimelineEvent</code> describes the stream.
		 */
		public static const VIDEO_STOP_RECSTREAM:String="TimelineInvoke.AV.VIDEO_STOP_RECSTREAM";
		/**
		 * Invoked by the broadcaster to initiate a live audio stream. Payload XML data associated
		 * with the <code>TimelineEvent</code> describes the stream.
		 */
		public static const AUDIO_START_LIVESTREAM:String="TimelineInvoke.AV.AUDIO_START_LIVESTREAM";
		/**
		 * Invoked by the broadcaster to stop a live audio stream. Payload XML data associated
		 * with the <code>TimelineEvent</code> describes the stream.
		 */
		public static const AUDIO_STOP_LIVESTREAM:String="TimelineInvoke.AV.AUDIO_STOP_LIVESTREAM";
		/**
		 * Invoked by the broadcaster to initiate a recorded (shared) audio stream. Payload XML data associated
		 * with the <code>TimelineEvent</code> describes the stream.
		 */
		public static const AUDIO_START_RECSTREAM:String="TimelineInvoke.AV.AUDIO_START_RECSTREAM";
		/**
		 * Invoked by the broadcaster to initiate a recorded (shared) audio stream. Payload XML data associated
		 * with the <code>TimelineEvent</code> describes the stream.
		 */
		public static const AUDIO_STOP_RECSTREAM:String="TimelineInvoke.AV.AUDIO_STOP_RECSTREAM";
		/**
		 * Implicitly starts a video effect. Payload XML data associated with the <code>TimelineEvent</code> describes the effect
		 * for any registered effect modules or handlers.
		 */
		public static const VIDEO_EFFECT_START:String="TimelineInvoke.AV.VIDEO_EFFECT_START";
		/**
		 * Implicitly stops a video effect. The effect should be stopped if it hasn't completed, and do nothing if it has.
		 * Payload XML data associated with the <code>TimelineEvent</code> describes the effect for any registered effect modules or handlers.
		 */
		public static const VIDEO_EFFECT_STOP:String="TimelineInvoke.AV.VIDEO_EFFECT_STOP";
		/**
		 * Implicitly starts an audio effect. Payload XML data associated with the <code>TimelineEvent</code> describes the effect
		 * for any registered effect modules or handlers.
		 */
		public static const AUDIO_EFFECT_START:String="TimelineInvoke.AV.AUDIO_EFFECT_START";
		/**
		 * Implicitly stops an audio effect. The effect should be stopped if it hasn't completed, and do nothing if it has.
		 * Payload XML data associated with the <code>TimelineEvent</code> describes the effect for any registered effect modules or handlers.
		 */
		public static const AUDIO_EFFECT_STOP:String="TimelineInvoke.AV.AUDIO_EFFECT_STOP";
		
	}//TimelineInvokeConstants class
	
}//package