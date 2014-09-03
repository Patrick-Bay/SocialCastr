package socialcastr.ui {
	
	import flash.display.DisplayObjectContainer;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import socialcastr.References;
	import socialcastr.Settings;
	import socialcastr.events.AccordionMenuButtonEvent;
	import socialcastr.interfaces.ui.IPanel;
	import socialcastr.interfaces.ui.IPanelContent;
	import socialcastr.interfaces.ui.IPanelManager;
	import socialcastr.ui.components.AccordionMenu;
	
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import swag.core.SwagSystem;
	
	/**
	 * Manages the creation and destruction of application panels.
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
	public class PanelManager implements IPanelManager {
				
		private var _defaultTarget:DisplayObjectContainer;				
		
		public function PanelManager() {
			this.addListeners();
		}//constructor
		
		public function createStartupPanel():IPanel {
			if (this._defaultTarget==null) {
				return (null);
			}//if						
			if (Panel.panelExists(Settings.startupPanelID)) {				
				var panelRef:Panel=Panel.getPanelsByID(Settings.startupPanelID)[0] as Panel;
				panelRef.show(panelRef.defaultShowDirection);
				return (panelRef);
			} else {
				var startupPanelClass:Class=Settings.startupPanelClass;
				if (startupPanelClass==null) {
					return (null);
				}//if
				var newPanel:Panel=new Panel(startupPanelClass);
				if (newPanel.content!=null) {
					newPanel.content.panelData=Settings.getPanelDefinitionByID(Settings.startupPanelID);
					newPanel.content.parentPanel=newPanel;
					this._defaultTarget.addChild(newPanel);
					newPanel.initialize();
					newPanel.show(newPanel.defaultShowDirection);
					return (newPanel);
				} else {
					newPanel.destroy();
					newPanel=null;
					return (null);
				}//else				
				return (null);
			}//else
		}//createStartupPanel
		
		public function createSilentPanels():Array {
			if (this._defaultTarget==null) {
				return (null);
			}//if			
			var panelClassIDs:Array=Settings.silentStartupPanelIDs;
			var panelClasses:Array=Settings.silentStartupPanelClasses;			
			var createdPanels:Array=new Array();
			if (panelClasses.length==0) {
				return (createdPanels);
			}//if
			for (var count:uint=0; count<panelClasses.length; count++) {				
				if (!Panel.panelExists(String(panelClassIDs[count]))) {				
					var currentPanelContentClass:Class=panelClasses[count] as Class;
					if (currentPanelContentClass!=null) {
						var newPanel:Panel=new Panel(currentPanelContentClass);					
						if (newPanel.content!=null) {
							newPanel.isSilent=true;
							newPanel.content.panelData=Settings.getPanelDefinitionByID(panelClassIDs[count] as String);
							newPanel.content.parentPanel=newPanel;
							this._defaultTarget.addChild(newPanel);
							newPanel.initialize();
							createdPanels.push(newPanel);											
						} else {
							newPanel.destroy();
							newPanel=null;							
						}//else					
					}//if
				}//if
			}//for
			return (createdPanels);
		}//createStartupPanel
		
		public function togglePanel(panelID:String, suspendCurrentPanels:Boolean=true):IPanel {				
			if (Panel.modalPanelActive) {
				return (null);
			}//if
			if ((panelID=="") || (panelID==null)) {
				return (null);
			}//if						
			var panelList:Array=Panel.getPanelsByID(panelID, false);			
			if ((panelList==null) || (panelList.length==0)) {
				var currentPanel:Panel=this.createPanelByID(panelID) as Panel;				
				if (currentPanel!=null) {	
					if (suspendCurrentPanels) {
						this.suspendActivePanels(currentPanel.oppositeHideDirection);
					}//if
					currentPanel.show(currentPanel.defaultShowDirection);
					return (currentPanel);
				}//if
			} else {					
				for (var count:uint=0; count<panelList.length; count++) {
					currentPanel=panelList[count] as Panel;					
					if (!currentPanel.active) {								
						if (suspendCurrentPanels) {							
							this.suspendActivePanels(currentPanel.oppositeHideDirection);
						}//if
						currentPanel.show(currentPanel.defaultShowDirection);										
						return (currentPanel);
					} else {
						if (suspendCurrentPanels) {
							if (this.resumeSuspendedPanels(currentPanel.oppositeShowDirection)) {								
								currentPanel.hide(currentPanel.defaultHideDirection);
								return (currentPanel);
							}//if
						} else {
							currentPanel.hide(currentPanel.defaultHideDirection);
						}//else
					}//else
				}//for
			}//else
			return (null);
		}//togglePanel
		
		public function onMenuSelection(eventObj:AccordionMenuButtonEvent):void {
			var mainMenu:AccordionMenu=AccordionMenu.getMenuByGroup("main");
			if (mainMenu==null) {
				return;
			}//if
			if (eventObj.source.group!="main") {
				return;
			}//if
			if (eventObj.source==mainMenu.mainMenuButton) {
				//Clicked on the main menu button. No actual menu selection made.
				return;
			}//if
			var selectedPanelID:String=eventObj.source.panel;			
			if (selectedPanelID==null) {
				return;				
			}//if
			this.togglePanel(selectedPanelID, true);			
			if (mainMenu!=null) {
				mainMenu.closeMenu();
			}//if
		}//onMenuSelection
		
		public function suspendActivePanels(hideDirection:String):Boolean {			
			var panelList:Vector.<Panel>=Panel.panels;
			var panelSuspended:Boolean=false;
			for (var count:uint=0; count<panelList.length; count++) {
				var currentPanel:Panel=panelList[count] as Panel;				
				if ((!currentPanel.suspended) && (currentPanel.active)) {	 					
					currentPanel.suspend(hideDirection);
					panelSuspended=true;
				}//if
			}//for
			return (panelSuspended);
		}//suspendActivePanels
		
		public function resumeSuspendedPanels(showDirection:String):Boolean {
			var panelList:Vector.<Panel>=Panel.panels;
			var panelResumed:Boolean=false;
			for (var count:uint=0; count<panelList.length; count++) {
				var currentPanel:Panel=panelList[count] as Panel;				
				if (currentPanel.suspended) {
					currentPanel.resume(showDirection);
					panelResumed=true;
				}//if				
			}//for
			return (panelResumed);
		}//resumeSuspendedPanels
		
		/**
		 * Creates a panel from the specified panel ID if it doesn't exist. If the panel already
		 * exists, no new panel is created.
		 *  
		 * @param panelID The panel ID to create.
		 * 
		 * @return A reference to the newly created panel instance, or <em>null</em> if the panel
		 * already exists or otherwise couldn't be created. 
		 * 
		 */
		public function createPanelByID(panelID:String):IPanel {
			if (!Panel.panelExists(panelID)) {		
				var currentPanelContentClass:Class=Settings.getPanelClassByID(panelID) as Class;
				if (currentPanelContentClass!=null) {
					var newPanel:Panel=new Panel(currentPanelContentClass);					
					if (newPanel.content!=null) {							
						newPanel.content.panelData=Settings.getPanelDefinitionByID(panelID);
						newPanel.content.parentPanel=newPanel;
						this._defaultTarget.addChild(newPanel);
						newPanel.initialize();
						return(newPanel);											
					} else {
						newPanel.destroy();
						newPanel=null;							
					}//else					
				}//if
			}//it			
			return (null);	
		}//createPanelByID
		
		/**
		 * Retrieves a panel instance, either newly created or existsing, by a specicified ID.
		 * <p>This method is similar to the <code>togglePanel</code> method except that it doesn't attempt
		 * to hide and restore panels but rather simply creates or returns a panel instance. No
		 * checking is done to determine if the panel instance is active or not.</p>
		 *  
		 * @param panelID The panel ID to create or return.
		 * 
		 * @return A reference to panel instance, or <em>null</em> if the panel doesn't exist
		 * and can't be created. 
		 * 
		 */
		public function getPanelByID(panelID:String):IPanel {
			if (panelID==null) {
				return (null);
			}//if
			var returnPanel:IPanel=null;
			var panelList:Array=Panel.getPanelsByID(panelID, false);			
			if (panelList.length>0) {
				returnPanel=panelList[0] as IPanel;				
			} else {
				returnPanel=this.createPanelByID(panelID);				
			}//else
			return (returnPanel);
		}//getPanelByID
		
		public function createPanelByXML(panelXML:XML):IPanel {
			return (null);
		}//createPanelByXML
		
		public function get activePanels():Array {
			return (Panel.activePanels);
		}//get activePanels		
		
		public function set target(targetSet:DisplayObjectContainer):void {
			this._defaultTarget=targetSet;
			this._defaultTarget.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyPress);
			this._defaultTarget.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyPress);
			this._defaultTarget.stage.removeEventListener(KeyboardEvent.KEY_UP, this.onKeyRelease);
			this._defaultTarget.stage.addEventListener(KeyboardEvent.KEY_UP, this.onKeyRelease);
		}//set target
		
		public function get target():DisplayObjectContainer {
			return (this._defaultTarget);
		}//get target
		
		private function addListeners():void {
			SwagDispatcher.addEventListener(AccordionMenuButtonEvent.CLICK, this.onMenuSelection, this, null);
		}//addListeners
		
		private function removeListeners():void {
			SwagDispatcher.removeEventListener(AccordionMenuButtonEvent.CLICK, this.onMenuSelection, null);
		}//removeListeners
			
		
		/**
		 * Finds a panel ID associated with a specific shortcut key. 
		 * @param shortcutKey The shortcut key to search for.
		 * @return The panel ID associated with the specified shortcut key. If no such key can be
		 * found, <em>null</em> is returned.
		 * 
		 */
		private function shortcutKeyPanelID(shortcutKey:String):String {
			if (!SwagDataTools.isXML(Settings.settingsData.panels)) {
				return (null);
			}//if
			var shortcutCompareString:String=new String(shortcutKey);
			shortcutCompareString=shortcutCompareString.toLowerCase();
			shortcutCompareString=SwagDataTools.stripChars(shortcutCompareString, SwagDataTools.SEPARATOR_RANGE);			
			var panelsNode:XML=Settings.settingsData.panels[0] as XML;
			var panelNodes:XMLList=panelsNode.panel as XMLList;
			for (var count:uint=0; count<panelNodes.length(); count++) {
				var panelData:XML=panelNodes[count] as XML;
				if (SwagDataTools.isXML(panelData.@shortcut)) {
					var shortcutString:String=new String(panelData.@shortcut);				
					shortcutString=shortcutString.toLowerCase();
					shortcutString=SwagDataTools.stripChars(shortcutString, SwagDataTools.SEPARATOR_RANGE);					
					if (shortcutCompareString==shortcutString) {
						var panelID:String=new String (panelData.@id);						
						return (panelID);
					}//if
				}//if
			}//for
			return (null);
		}//shortcutKeyPanelID
		
		/**
		 * Finds the panel XML node associated with a specific shortcut key. 
		 * @param shortcutKey The shortcut key to search for.
		 * @return The panel XML node associated with the specified shortcut key. If no such key can be
		 * found, <em>null</em> is returned.
		 * 
		 */
		private function shortcutKeyPanelXML(shortcutKey:String):XML {
			if (!SwagDataTools.isXML(Settings.settingsData.panels)) {
				return (null);
			}//if
			var shortcutCompareString:String=new String(shortcutKey);
			shortcutCompareString=shortcutCompareString.toLowerCase();
			shortcutCompareString=SwagDataTools.stripChars(shortcutCompareString, SwagDataTools.SEPARATOR_RANGE);
			var panelsNode:XML=Settings.settingsData.panels[0] as XML;
			var panelNodes:XMLList=panelsNode.panel as XMLList;
			for (var count:uint=0; count<panelNodes.length(); count++) {
				var panelData:XML=panelNodes[count] as XML;
				if (SwagDataTools.isXML(panelData.@shortcut)) {
					var shortcutString:String=new String(panelData.@shortcut);
					shortcutString=shortcutString.toLowerCase();
					shortcutString=SwagDataTools.stripChars(shortcutString, SwagDataTools.SEPARATOR_RANGE);
					if (shortcutCompareString==shortcutString) {
						return (panelData);
					}//if
				}//if
			}//for
			return (null);
		}//shortcutKeyPanelXML
		
		/**
		 * Finds the panel name associated with a specific shortcut key. 
		 * @param shortcutKey The shortcut key to search for.
		 * @return The panel name associated with the specified shortcut key. If no such key can be
		 * found, <em>null</em> is returned.
		 * 
		 */
		private function shortcutKeyPanelName(shortcutKey:String):String {
			if (!SwagDataTools.isXML(Settings.settingsData.panels)) {
				return (null);
			}//if
			var shortcutCompareString:String=new String(shortcutKey);
			shortcutCompareString=shortcutCompareString.toLowerCase();
			shortcutCompareString=SwagDataTools.stripChars(shortcutCompareString, SwagDataTools.SEPARATOR_RANGE);
			var panelsNode:XML=Settings.settingsData.panels[0] as XML;
			var panelNodes:XMLList=panelsNode.panel as XMLList;
			for (var count:uint=0; count<panelNodes.length(); count++) {
				var panelData:XML=panelNodes[count] as XML;
				if (SwagDataTools.isXML(panelData.@shortcut)) {
					var shortcutString:String=new String(panelData.@shortcut);
					shortcutString=shortcutString.toLowerCase();
					shortcutString=SwagDataTools.stripChars(shortcutString, SwagDataTools.SEPARATOR_RANGE);
					if (shortcutCompareString==shortcutString) {
						var panelName:String=new String (panelData.@name);
						return (panelName);
					}//if
				}//if
			}//for
			return (null);
		}//shortcutKeyPanelName
	
		private function onKeyPress(eventObj:KeyboardEvent):void {
			var key:String=String.fromCharCode(eventObj.keyCode);
			//Note that not all keystrokes are valid in browsers (and even standalone Flash player)...
			//need to test valid key strokes for this function extensively!
			//trace ("Pressed key: "+key+" ("+eventObj.keyCode+")");
			if (eventObj.ctrlKey && eventObj.altKey) {
				this.togglePanel(this.shortcutKeyPanelID(key))
				return;
			}//if
			if (SwagSystem.isMobile) {		
				//On Android, these match the menu and back keys
				switch (eventObj.keyCode) {
					case Keyboard["BACK"]:				
						eventObj.preventDefault();
						eventObj.stopImmediatePropagation();
						break;
					case Keyboard["MENU"]:
						eventObj.preventDefault();
						eventObj.stopImmediatePropagation();
						break;
					default:
						break;
				}//switch	
			}//if
		}//onKeyPress
		
		private function onKeyRelease(eventObj:KeyboardEvent):void {	
			if (SwagSystem.isMobile) {		
				switch (eventObj.keyCode) {
					//Use identifiers to keep this downward-compilable (to CS5)
					case Keyboard["BACK"]:
						References.debugPanel.debug("Back button on mobile device");
						eventObj.preventDefault();
						eventObj.stopImmediatePropagation();
						break;
					case Keyboard["MENU"]:
						References.debugPanel.debug("Menu button on mobile device");
						eventObj.preventDefault();
						eventObj.stopImmediatePropagation();
						break;
					default:
						break;
				}//switch
			}//onKeyRelease
		}//if		
	}//PanelManager class
	
}//package