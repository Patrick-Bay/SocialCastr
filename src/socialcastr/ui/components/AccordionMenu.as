package socialcastr.ui.components {
	
	import flash.display.MovieClip;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.events.AccordionMenuButtonEvent;
	import socialcastr.events.AccordionMenuEvent;
	import socialcastr.events.PanelEvent;
	import socialcastr.ui.components.AccordionMenuButton;
	import socialcastr.ui.input.MovieClipButton;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.instances.SwagMovieClip;
	
	
	/**
	 * Creates and manages a menu that slides out from a single button in the style of an accordion.
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
	public class AccordionMenu extends MovieClip {		
		
		private static var _menus:Array=new Array();
		
		private var _menuButton:AccordionMenuButton;
		private var _menuGroup:String=null;
		private var _clip:SwagMovieClip;		
		private var _menuOpen:Boolean=false;
		
		public function AccordionMenu(menuID:String)	{
			this._menuGroup=menuID;
			_menus.push(this);
			this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			super();
		}//constructor
		
		/**
		 * Initializes the accordion menu. This method should only be called after data has been loaded
		 * and fully parsed by the <code>Settings</code> class on which the Accordion Menu depends.
		 */
		public function initialize(menuID:String=null):void {
			this.alpha=1;
			this.visible=true;
			if (this._menuGroup==null) {
				this._menuGroup=menuID;
			}//if
			if (this._menuGroup==null) {
				return;
			}//if
			var menuData:XML=Settings.getMenuDataByGroup(this._menuGroup);
			if (menuData==null) {
				return;
			}//if
			if (SwagDataTools.isXML(menuData.@x)) {
				this.x=Number(String(menuData.@x));
			}//if
			if (SwagDataTools.isXML(menuData.@y)) {
				this.y=Number(String(menuData.@y));
			}//if
			var buttonNodes:XMLList=menuData.button as XMLList;
			if (buttonNodes==null) {
				return;
			}//if
			if (buttonNodes.length()==0) {
				return;
			}//if
			this.createMainMenuButton(menuData);
			for (var count:uint=0; count<buttonNodes.length(); count++) {
				var currentButtonNode:XML=buttonNodes[count] as XML;
				var newButton:AccordionMenuButton=new AccordionMenuButton(this._menuGroup, currentButtonNode);
				this.addChild(newButton);
			}//for
			this._menuButton.swapWithTop();
		}//initialize
		
		public function onMainMenuButtonClick(eventObj:AccordionMenuButtonEvent):void {
			if (this._menuOpen) {
				this._menuOpen=false;
				AccordionMenuButton.closeGroup(this._menuGroup, 60);
			} else {
				this._menuOpen=true;
				AccordionMenuButton.openGroup(this._menuGroup, 60);
			}//else
		}//onMainMenuButtonClick
		
		public function closeMenu():void {
			if (this._menuOpen) {
				this._menuOpen=false;
				AccordionMenuButton.closeGroup(this._menuGroup, 60);
			}//if
		}//closeMenu
		
		public function openMenu():void {
			if (!this._menuOpen) {
				this._menuOpen=true;
				AccordionMenuButton.openGroup(this._menuGroup, 60);
			}//if
		}//closeMenu
		
		private function createMainMenuButton(buttonData:XML):void {
			this._menuButton=new AccordionMenuButton(this._menuGroup, buttonData);
			this._menuButton.isStatic=true;		
			SwagDispatcher.addEventListener(AccordionMenuButtonEvent.CLICK, this.onMainMenuButtonClick, this, this._menuButton);
			this.addChild(this._menuButton);
			this._menuButton.show();
		}//createMainMenuButton
		
		public function onPanelUpdate(eventObj:PanelEvent):void {
			this._clip.swapWithTop();
			this._menuButton.swapWithTop();
		}//onPanelUpdate
		
		private function onStageClick(eventObj:MouseEvent):void {
			var itemsUnderClick:Array=this.stage.getObjectsUnderPoint(new Point(eventObj.stageX, eventObj.stageY));
			for (var count:uint=0; count<itemsUnderClick.length; count++) {
				var currentItem:DisplayObject=itemsUnderClick[count] as DisplayObject;
				if (this.contains(currentItem)) {
					return;
				}//if
			}//for
			this.closeMenu();
		}//onStageClick
		
		public function get group():String {
			return (this._menuGroup);
		}//get group
		
		public function get mainMenuButton():AccordionMenuButton {
			return (this._menuButton);
		}//mainMenuButton
		
		public static function getMenuByGroup(groupName:String):AccordionMenu {
			for (var count:uint=0; count<_menus.length; count++) {
				var currentMenu:AccordionMenu=_menus[count] as AccordionMenu;
				if (currentMenu.group==groupName) {
					return (currentMenu);
				}//if
			}//for
			return (null);
		}//getMenuByGroup
		
		private function addListeners():void {
			this.stage.addEventListener(MouseEvent.CLICK, this.onStageClick);
			SwagDispatcher.addEventListener(PanelEvent.ONSHOW, this.onPanelUpdate, this, null);
			SwagDispatcher.addEventListener(PanelEvent.ONHIDE, this.onPanelUpdate, this, null);
		}//addListeners
		
		private function removeListeners():void {
			this.stage.removeEventListener(MouseEvent.CLICK, this.onStageClick);
			SwagDispatcher.removeEventListener(PanelEvent.ONSHOW, this.onPanelUpdate, null);
			SwagDispatcher.removeEventListener(PanelEvent.ONHIDE, this.onPanelUpdate, null);
		}//removeListeners
		
		public function setDefaults(eventObj:Event):void {
			this.alpha=0;
			this.visible=false;
			this._clip=new SwagMovieClip(this);
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			this.addListeners();
			this.initialize();
		}//setDefaults
		
	}//AccordionMenu
	
}//package