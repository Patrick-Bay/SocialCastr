package socialcastr.core.timeline {
	
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import socialcastr.References;
	import socialcastr.core.Timeline;
	import socialcastr.core.TimelineElement;
	import socialcastr.events.TimelineEvent;
	import socialcastr.ui.Panel;
	import socialcastr.ui.components.VideoDisplayComponent;
	import socialcastr.ui.panels.BroadcastPanel;
	
	import swag.core.SwagDataTools;
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
	public class SimpleVideoFadeEffect extends BaseTimelineEffect	{
		
		public const effectType:String="video";
		public const effectName:String="SimpleVideoFade";
		public const effectVersion:String="1.0";
		/**		 
		 * The direction of the fade; true=fade in, false=fade out		 
		 */
		public var fadeIn:Boolean=true;
		/**		 
		 * The speed of the fade, in milliseconds.		 
		 */
		public var fadeSpeed:int=1000;
		
		private var _fadeTimer:Timer=null;
		private var _currentFadeCount:int=1000;
		
		/**
		 * Provides a simple video effect for any <code>VideoDisplayComponent</code> instance via
		 * Timeline broadcasts.
		 *  
		 * @param effectTarget
		 * 
		 */
		public function SimpleVideoFadeEffect(effectTarget:*) {	
			this.addListeners();
			super(effectTarget);
		}//constructor
		
		override public function onTimelineInvoke(eventObj:TimelineEvent):void {			
			try {
				if (this.target is VideoDisplayComponent) {
					if (eventObj.invoke==TimelineInvokeConstants.VIDEO_EFFECT_START) {
						if (super.verifyEffect(eventObj.payload, this.effectType, this.effectName, this.effectVersion)) {								
							if (eventObj.payload.@fadeIn=="false") {
								this.fadeIn=false;
							} else {
								this.fadeIn=true;
							}//else
							if (SwagDataTools.isXML(eventObj.payload.@fadeSpeed)) {
								this.fadeSpeed=int(String(eventObj.payload.@fadeSpeed));
							}//if
							this.startEffect();
						}//if
					}//if
				}//if
			} catch (e:*) {				
			}//catch
		}//onTimelineInvoke	
		
		private function startEffect():void {
			this.stopEffect();
			this._fadeTimer=new Timer(10); //10ths of a second
			if (this.fadeIn) {
				this._currentFadeCount=0;
			} else {
				this._currentFadeCount=this.fadeSpeed;
			}//else
			this._fadeTimer.addEventListener(TimerEvent.TIMER, this.onTimerTick);
			this._fadeTimer.start();
		}//startEffect
		
		private function onTimerTick(eventObj:TimerEvent):void {
			if (this.target is VideoDisplayComponent) {
				var alphaPercent:Number=this._currentFadeCount/this.fadeSpeed;
				this.target.alpha=alphaPercent;
				if (this.fadeIn) {
					this._currentFadeCount+=10; //One 10th of a second for every loop
					if (this.target.alpha>=1) {
						this.target.alpha=1;
						this.stopEffect();
					}//if
				} else {
					this._currentFadeCount-=10;
					if (this.target.alpha<=0) {
						this.target.alpha=0;
						this.stopEffect();
					}//if
				}//else			
			}//if
		}//onTimerTick
		
		private function stopEffect():void {
			if (this._fadeTimer!=null) {
				this._fadeTimer.stop();
				this._fadeTimer=null;
			}//if
		}//stopEffect
		
		private function onKeyPress(eventObj:KeyboardEvent):void {			
			if (this.target is VideoDisplayComponent) {
				if (String.fromCharCode(eventObj.charCode)=="]") {
					this.fadeIn=true;
					this.addToTimeline(this.targetTimeline);
				}//if
				if (String.fromCharCode(eventObj.charCode)=="[") {
					this.fadeIn=false;					
					this.addToTimeline(this.targetTimeline);
				}//if				
			}//if
		}//onKeyPress
		
		private function addListeners():void {
			CONFIG::BROADCASTR {
				References.main.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyPress);
			}
		}//addListeners
		
		private function removeListeners():void {
			CONFIG::BROADCASTR {
				References.main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyPress);
			}
		}//removeListeners
		
		override public function addToTimeline(timeline:Timeline):void {
			var broadcastPanel:Panel=References.panelManager.getPanelByID("broadcast") as Panel;
			References.debug("addToTimeline: Broadcast panel reference="+broadcastPanel.content);
			var offsetTime:int=0;
			if (broadcastPanel!=null) {
				try {
					offsetTime=int(BroadcastPanel(broadcastPanel.content).mediaBroadcast.stream.time);
				} catch (e:*) {					
				}//catch
			}//if	
			offsetTime*=1000; //time is in secconds
			References.debug("addToTimeline: offsetTime="+offsetTime);
			var elementXML:XML=super.createTimelineEffectXML(this.effectType, this.effectName, this.effectVersion, offsetTime);
			trace ("Created element to broadcast: "+elementXML.toXMLString());
			var payloadXML:XML=elementXML.children()[0] as XML;
			if (this.fadeIn) {
				payloadXML.@fadeIn="true";
			} else {
				payloadXML.@fadeIn="false";
			}//else
			payloadXML.@fadeSpeed=String(this.fadeSpeed);
			timeline.broadcastElement(elementXML, true, true);
		}//addToTimeline
		
	}//SimpleVideoFadeEffect class
	
}//package