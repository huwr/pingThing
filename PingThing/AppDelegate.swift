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
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
    
    let StatusMenuItemTag = 0
    let StartStopMenuItemTag = 1
    
    var host: String = PingHelper.DefaultHost
    var interval: Double = PingHelper.DefaultInterval
    
    private(set)
    var pingHelper: PingHelper?
    
    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        checkUserDefaultsAndLoad()
        
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusBarPaused")
        }
        
        self.pingHelper = PingHelper(host: host, interval: interval)
        
        if let helper = self.pingHelper {
            statusItem.menu = buildMenu(helper)
            listenToPings(helper)
            helper.start()
        }
    }
    
    func checkUserDefaultsAndLoad(defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        if let hostFromPrefs = defaults.objectForKey(TargetHostUserDefaultsKey) as? String {
            self.host = hostFromPrefs
        }
        if let intervalFromPrefs = defaults.objectForKey(PingIntervalUserDefaultsKey) as? Double {
            self.interval = intervalFromPrefs
        }
    }
    
    private func buildMenu(helper: PingHelper) -> NSMenu {
        let menu = NSMenu()
        
        let startStopMenuTitle = helper.running ? "Stop" : "Start"
        
        let statusMenuItem = NSMenuItem(title: "Status: \(helper.status)", action: nil, keyEquivalent: "")
        statusMenuItem.tag = StatusMenuItemTag
        
        let startStopMenuItem = NSMenuItem(title: startStopMenuTitle,  action: #selector(AppDelegate.startStopPing(_:)), keyEquivalent: "")
        startStopMenuItem.representedObject = helper
        startStopMenuItem.tag = StartStopMenuItemTag
        
        menu.addItem(statusMenuItem)
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(startStopMenuItem)
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(AppDelegate.openPrefsWindow(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(NSMenuItem(title: "Quit PingThing", action: #selector(NSApplication.sharedApplication().terminate), keyEquivalent: ""))
        
        return menu
    }
    
    private func listenToPings(helper: PingHelper) {
        NSNotificationCenter.defaultCenter().addObserverForName(StatusChangedNotification,
            object: helper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateMenus(fromHelper: helper)
                }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PingStartedNotification,
            object: helper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateMenus(fromHelper: helper)
                }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PingStoppedNotification,
            object: helper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateMenus(fromHelper: helper)
                }
        }
    }
    
    private func updateMenus(fromHelper helper: PingHelper) {
        if let button = statusItem.button {
            switch helper.status {
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
                statusMenu.title = "Status: \(helper.status.rawValue)"
            }
            
            if let startStopMenu = menu.itemWithTag(StartStopMenuItemTag) {
                startStopMenu.title = helper.running ? "Stop" : "Start"
            }
        }
    }
    
    func startStopPing(sender: NSMenuItem) {
        if let helper = sender.representedObject as? PingHelper {
            helper.running ? helper.stop() : helper.start()
        }
    }
    
    func openPrefsWindow(sender: AnyObject) {
        window.makeKeyAndOrderFront(self)
        NSApp.activateIgnoringOtherApps(true)
    }
}

