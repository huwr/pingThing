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
    @IBOutlet weak var intervalTextField: NSTextField!
    @IBOutlet weak var startStopButton: NSButtonCell!
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var lagTextField: NSTextField!
    @IBOutlet weak var packetLossTextField: NSTextField!
    
    var currentStatus: Status? {
        didSet {
            guard let status = currentStatus else {
                return
            }

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
    
    var currentLag: Double? {
        didSet {
            if let lag = currentLag {
                lagTextField.stringValue = String(format: "%.3f ms", lag)
                lagTextField.textColor = NSColor.blackColor()
            } else {
                lagTextField.stringValue = "No data"
                lagTextField.textColor = NSColor.darkGrayColor()
            }
        }
    }
    
    var currentLoss: Double? {
        didSet {
            if let loss = currentLoss {
                packetLossTextField.stringValue = String(format: "%3.2f%%", loss * 100)
                packetLossTextField.textColor = NSColor.blackColor()
            } else {
                packetLossTextField.stringValue = "No data"
                packetLossTextField.textColor = NSColor.darkGrayColor()
            }
        }
    }
    
    var pingHelper: PingHelper?
    
    @IBAction func intervalTextFieldChanged(sender: NSTextField) {
        guard let helper = pingHelper else {
            return
        }
        helper.interval = intervalTextField.doubleValue
        helper.start()
        savePrefs(fromPingHelper: helper)
    }
    
    @IBAction func quit(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    @IBAction func targetHostTextFieldChanged(sender: NSTextField) {
        saveHostButton.performClick(self)
    }
    
    @IBAction func saveHostButtonPressed(sender: NSButton) {
        guard let helper = pingHelper else {
            return
        }
        
        statusTextField.stringValue = "Starting…"
        statusTextField.textColor = NSColor.blackColor()
        helper.host = targetHostTextField.stringValue
        helper.start()
        savePrefs(fromPingHelper: helper)
    }
    
    @IBAction func startStopButtonPressed(sender: NSButtonCell) {
        guard let helper = pingHelper else {
            return
        }
        
        if helper.running {
            helper.stop()
        } else {
            helper.start()
        }
    }
    
    @IBAction func launchAtLoginCheckbox(sender: NSButton) {
        print("Launch at login checkbox checked")
        print("Value: \(sender.state)")
    }
    
    override func viewWillAppear() {
        if let appDelegate = NSApplication.sharedApplication().delegate as? AppDelegate {
            pingHelper = appDelegate.pingHelper
        }
        
        if let helper = pingHelper {
            listenToPings(onPingHelper: helper)
            self.updateViewControls(fromPingHelper: helper)
            self.updateViewStatus(fromPingHelper: helper)
        }
    }
    
    override func viewWillDisappear() {
        if let helper = pingHelper {
            NSNotificationCenter.defaultCenter().removeObserver(helper)
        }
    }
    
    private func updateViewStatus(fromPingHelper pingHelper: PingHelper) {
        currentStatus = pingHelper.status
        currentLag = pingHelper.averageLag
        currentLoss = pingHelper.dropOutRate
        startStopButton.title = pingHelper.running ? "Pause" : "Start"
    }
    
    private func updateViewControls(fromPingHelper pingHelper: PingHelper) {
        targetHostTextField.stringValue = pingHelper.host
        intervalTextField.doubleValue = pingHelper.interval
    }
    
    private func listenToPings(onPingHelper pingHelper: PingHelper) {
        NSNotificationCenter.defaultCenter().addObserverForName(StatusChangedNotification,
            object: pingHelper,
            queue: NSOperationQueue.mainQueue()) { [unowned self] _ in
                self.updateViewStatus(fromPingHelper: pingHelper)
            }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PingStartedNotification,
            object: pingHelper,
            queue: NSOperationQueue.mainQueue()) { [unowned self] _ in
                self.updateViewStatus(fromPingHelper: pingHelper)
            }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PingStoppedNotification,
            object: pingHelper,
            queue: NSOperationQueue.mainQueue()) { [unowned self] _ in
                self.updateViewStatus(fromPingHelper: pingHelper)
            }
    }
    
    private func savePrefs(fromPingHelper helper: PingHelper, usingDefaults defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        defaults.setObject(helper.host, forKey: TargetHostUserDefaultsKey)
        defaults.setObject(helper.interval, forKey: PingIntervalUserDefaultsKey)
        defaults.synchronize()
    }
}
