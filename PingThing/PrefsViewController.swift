//
//  PrefsViewController.swift
//  PingThing
//
//  Created by Huw Rowlands on 2.6.2015.
//  Copyright (c) 2015 DiUS Computing Pty Ltd. All rights reserved.
//

import Cocoa

class PrefsViewController: NSViewController {
    @IBOutlet weak var targetHostTextField: NSTextField!
    @IBOutlet weak var saveHostButton: NSButton!
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var intervalTextField: NSTextField!
    @IBOutlet weak var startStopButton: NSButtonCell!
    
    var currentStatus: Status? {
        didSet {
            if let status = currentStatus {
                statusTextField.stringValue = status.rawValue
                switch status {
                case .Success:
                    statusTextField.textColor = NSColor(calibratedRed: 0, green: 149/255.0, blue: 0, alpha: 1)
                case .Failure:
                    statusTextField.textColor = NSColor.orangeColor()
                case .Error:
                    statusTextField.textColor = NSColor.redColor()
                default:
                    statusTextField.textColor = NSColor.blackColor()
                }
            }
        }
    }
    
    @IBAction func intervalTextFieldChanged(sender: NSTextField) {
        AppDelegate.pingHelper.interval = intervalTextField.doubleValue
        savePrefs()
    }
    
    @IBAction func quit(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    @IBAction func targetHostTextFieldChanged(sender: NSTextField) {
        saveHostButton.performClick(self)
    }
    
    @IBAction func saveHostButtonPressed(sender: NSButton) {
        statusTextField.stringValue = "Starting…"
        statusTextField.textColor = NSColor.blackColor()
        AppDelegate.pingHelper.host = targetHostTextField.stringValue
        savePrefs()
    }
    
    @IBAction func startStopButtonPressed(sender: NSButtonCell) {
        if AppDelegate.pingHelper.running {
            AppDelegate.pingHelper.stop()
        } else {
            AppDelegate.pingHelper.start()
        }
    }
    
    @IBAction func launchAtLoginCheckbox(sender: NSButton) {
        println("Launch at login checkbox checked")
        println("Value: \(sender.state)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        listenToPings(onPingHelper: AppDelegate.pingHelper)
        updateStatusFromHelper()
        targetHostTextField.stringValue = AppDelegate.pingHelper.host
        intervalTextField.doubleValue = AppDelegate.pingHelper.interval
    }
    
    override func viewWillDisappear() {
        NSNotificationCenter.defaultCenter().removeObserver(AppDelegate.pingHelper)
    }
    
    private func updateStatusFromHelper() {
        self.currentStatus = AppDelegate.pingHelper.status
        self.startStopButton.title = AppDelegate.pingHelper.running ? "Stop" : "Start"
    }
    
    private func listenToPings(onPingHelper pingHelper: PingHelper) {
        NSNotificationCenter.defaultCenter().addObserverForName(PingReceivedNotification,
            object: pingHelper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateStatusFromHelper()
                }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PingStartedNotification,
            object: pingHelper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateStatusFromHelper()
                }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PingStoppedNotification,
            object: pingHelper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateStatusFromHelper()
                }
        }
    }
    
    private func savePrefs() {
        let prefs = NSUserDefaults.standardUserDefaults()
        prefs.setObject(AppDelegate.pingHelper.host, forKey: TargetHostUserDefaultsKey)
        prefs.setObject(AppDelegate.pingHelper.interval, forKey: PingIntervalUserDefaultsKey)
        prefs.synchronize()
    }
    
}
