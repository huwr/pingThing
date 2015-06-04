//
//  AppDelegate.swift
//  PingThing
//
//  Created by Huw Rowlands on 2.6.2015.
//  Copyright (c) 2015 DiUS Computing Pty Ltd. All rights reserved.
//

import Cocoa

let TargetHostUserDefaultsKey = "target-host"
let PingIntervalUserDefaultsKey = "ping-interval"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    //bug in XCode :( - NSSquareStatusItemLength == -2
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2)
    
    let StatusMenuItemTag = 0
    let StartStopMenuItemTag = 1
    
    static let pingHelper = PingHelper()
    var host: String = "8.8.8.8"
    
    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        checkUserDefaultsAndLoad()
        
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusBarPaused")
        }
        
        statusItem.menu = createMenu()
        listenToPings(onPingHelper: AppDelegate.pingHelper)
    }
    
    func checkUserDefaultsAndLoad() {
        let prefs = NSUserDefaults.standardUserDefaults()
        if let hostFromPrefs = prefs.objectForKey(TargetHostUserDefaultsKey) as? String {
            AppDelegate.pingHelper.host = hostFromPrefs
        }
    }
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        let startStopMenuTitle = AppDelegate.pingHelper.running ? "Stop" : "Start"
        let status = AppDelegate.pingHelper.status
        
        let statusMenuItem = NSMenuItem(title: "Status: \(status)", action: nil, keyEquivalent: "")
        statusMenuItem.tag = StatusMenuItemTag
        
        let startStopMenuItem = NSMenuItem(title: startStopMenuTitle,  action: Selector("startStopPing:"), keyEquivalent: "")
        startStopMenuItem.tag = StartStopMenuItemTag
        
        menu.addItem(statusMenuItem)
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(startStopMenuItem)
        menu.addItem(NSMenuItem(title: "Preferences…", action: Selector("openPrefs:"), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(NSMenuItem(title: "Quit PingThing", action: Selector("terminate:"), keyEquivalent: ""))
        
        return menu
    }
    
    private func updateMenus() {
        if let button = statusItem.button {
            switch AppDelegate.pingHelper.status {
            case Status.Success:
                button.image = NSImage(named: "StatusBarTick")
            case Status.NotRunning:
                button.image = NSImage(named: "StatusBarPaused")
            case Status.Failure:
                button.image = NSImage(named: "StatusBarCross")
            default:
                button.image = NSImage(named: "StatusBarWarning")
            }
        }
        
        if let menu = statusItem.menu {
            if let statusMenu = menu.itemWithTag(StatusMenuItemTag) {
                statusMenu.title = "Status: \(AppDelegate.pingHelper.status.rawValue)"
            }
            
            if let startStopMenu = menu.itemWithTag(StartStopMenuItemTag) {
                startStopMenu.title = AppDelegate.pingHelper.running ? "Stop" : "Start"
            }
        }
    }
    
    private func listenToPings(onPingHelper pingHelper: PingHelper) {
        NSNotificationCenter.defaultCenter().addObserverForName(PingReceivedNotification,
            object: pingHelper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateMenus()
                }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PingStartedNotification,
            object: pingHelper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateMenus()
                }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PingStoppedNotification,
            object: pingHelper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateMenus()
                }
        }
    }
    
    func startStopPing(sender: NSMenuItem) {
        AppDelegate.pingHelper.running ? AppDelegate.pingHelper.stop() : AppDelegate.pingHelper.start()
    }
    
    func openPrefs(sender: AnyObject) {
        window.makeKeyAndOrderFront(self)
        NSApp.activateIgnoringOtherApps(true)
    }
}

