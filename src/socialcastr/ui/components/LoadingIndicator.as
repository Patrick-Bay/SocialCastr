package socialcastr.ui.components {
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.None;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.geom.PerspectiveProjection;
	import flash.geom.Point;
	
	import socialcastr.events.LoadingIndicatorEvent;
	import socialcastr.interfaces.ui.components.ILoadingIndictator;
	
	import swag.core.SwagDispatcher;
	import swag.core.instances.SwagMovieClip;
	
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
	public class LoadingIndicator extends MovieClip implements ILoadingIndictator	{
		
		//on stage
		public var rotateGraphic:MovieClip;
		public var broadcastDotGraphic:MovieClip;
		public var loadingText:TextField;
				
		private var _broadcastDotPlayback:SwagMovieClip=null;
		private var _fadeTween:Tween=null;
		
		public function LoadingIndicator()	{
			this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
		}//constructor
		
		public function hide(eventObj:LoadingIndicatorEvent):void {
			this.swapWithTop();
			this.stopFadeTween();
			this._fadeTween=new Tween(this, "alpha", None.easeNone, this.alpha, 0, 0.3, true);
			this._fadeTween.addEventListener(TweenEvent.MOTION_FINISH, this.onFadeComplete);
		}//hide
		
		public function show(eventObj:LoadingIndicatorEvent):void {
			this.swapWithTop();
			this.stopFadeTween();
			this.visible=true;
			this._fadeTween=new Tween(this, "alpha", None.easeNone, this.alpha, 1, 0.3, true);
			this._fadeTween.addEventListener(TweenEvent.MOTION_FINISH, this.onFadeComplete);
		}//show
		
		private function onFadeComplete(eventObj:TweenEvent):void {
			this.stopFadeTween();
			if (this.alpha==1) {
				var event:LoadingIndicatorEvent=new LoadingIndicatorEvent(LoadingIndicatorEvent.ONSHOW);
				SwagDispatcher.dispatchEvent(event, this);
			} else {
				this.visible=false;
				event=new LoadingIndicatorEvent(LoadingIndicatorEvent.ONHIDE);
				SwagDispatcher.dispatchEvent(event, this);
			}//else
		}//onFadeComplete
		
		private function stopFadeTween():void {
			this.swapWithTop();
			if (this._fadeTween!=null) {
				this._fadeTween.stop();
				this._fadeTween.removeEventListener(TweenEvent.MOTION_FINISH, this.onFadeComplete);
				this._fadeTween=null;
			}//if
		}//stopFadeTween
		
		public function update(eventObj:LoadingIndicatorEvent):void {
			this.swapWithTop();
			if (this.loadingText!=null) {
				this.loadingText.text=eventObj.updateText;
			}//if			
		}//update
		
		public function startLoadingAnimations(eventObj:LoadingIndicatorEvent):void {			
			this.swapWithTop();			
			this.stopRotationAnimation();
			this.startRotationAnimation();
			if (this._broadcastDotPlayback!=null) {
				this._broadcastDotPlayback.play();
			}//if			
		}//startLoadingAnimations
		
		public function stopLoadingAnimations(eventObj:LoadingIndicatorEvent):void {
			this.swapWithTop();	
			this.stopRotationAnimation();
			if (this._broadcastDotPlayback!=null) {
				this._broadcastDotPlayback.stop();
			}//if			
		}//stopLoadingAnimations
		
		private function startRotationAnimation():void {
			this.addEventListener(Event.ENTER_FRAME, this.onRotationAnimation);
		}//startRotationAnimation
		
		private function stopRotationAnimation():void {
			if (this.hasEventListener(Event.ENTER_FRAME)) {
				this.removeEventListener(Event.ENTER_FRAME, this.onRotationAnimation);
			}//if
		}//stopRotationAnimation
		
		private function onRotationAnimation(eventObj:Event):void {
			if (this.rotateGraphic==null) {
				this.stopRotationAnimation();
				return;
			}//if
			this.rotateGraphic.rotationY+=6;
			if (this.rotateGraphic.rotationY>360) {
				this.rotateGraphic.rotationY=360-this.rotateGraphic.rotationY;
			}//if
		}//onRotationAnimation
		
		private function swapWithTop():void {
			if (this.stage==null) {
				return;
			}
			var swapIndex:int=this.parent.numChildren-1;
			var thisIndex:int=this.parent.getChildIndex(this);
			if (swapIndex==thisIndex) {
				return;
			}//if
			try {
				this.parent.setChildIndex(this, swapIndex);
			} catch (error:*) {
				if (error is RangeError) {
					//Index isn't correct
				} else if (error is ArgumentError) {
					//Target isn't a child of the container
				} else {
					
				}//else
			}//catch
		}//swapWithTop
		
		private function set3DProjectionCenter():void {
			var projection:PerspectiveProjection=new PerspectiveProjection();
			projection.fieldOfView=45;
			projection.projectionCenter=new Point(this.rotateGraphic.width,(this.rotateGraphic.height/2));			
			this.transform.perspectiveProjection=projection;			
		}//set3DProjectionCenter
		
		private function addListeners():void {
			SwagDispatcher.addEventListener(LoadingIndicatorEvent.SHOW, this.show, this);
			SwagDispatcher.addEventListener(LoadingIndicatorEvent.HIDE, this.hide, this);
			SwagDispatcher.addEventListener(LoadingIndicatorEvent.UPDATE, this.update, this);
			SwagDispatcher.addEventListener(LoadingIndicatorEvent.UPDATE, this.update, this);
			SwagDispatcher.addEventListener(LoadingIndicatorEvent.START, this.startLoadingAnimations, this);
			SwagDispatcher.addEventListener(LoadingIndicatorEvent.STOP, this.stopLoadingAnimations, this);
		}//addListeners
		
		private function removeListeners():void {
			SwagDispatcher.removeEventListener(LoadingIndicatorEvent.SHOW, this.show);
			SwagDispatcher.removeEventListener(LoadingIndicatorEvent.HIDE, this.hide);
			SwagDispatcher.removeEventListener(LoadingIndicatorEvent.UPDATE, this.update);	
			SwagDispatcher.removeEventListener(LoadingIndicatorEvent.START, this.startLoadingAnimations);
			SwagDispatcher.removeEventListener(LoadingIndicatorEvent.STOP, this.stopLoadingAnimations);
		}//removeListeners
		
		private function setDefaults(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);		
			if (this.broadcastDotGraphic!=null) {
				this._broadcastDotPlayback=new SwagMovieClip(this.broadcastDotGraphic);
				this._broadcastDotPlayback.gotoAndStop(1);
			}//if
			this.set3DProjectionCenter();
			this.alpha=0;
			this.visible=false;
			this.addListeners();
		}//setDefaults
		
	}//LoadingIndicator class
	
}//package