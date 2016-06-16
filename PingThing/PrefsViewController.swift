import Cocoa

class PrefsViewController: NSViewController {
    let fontManager = NSFontManager()
    
    @IBOutlet weak var targetHostTextField: NSTextField!
    @IBOutlet weak var saveHostButton: NSButton!
    @IBOutlet weak var intervalTextField: NSTextField!
    @IBOutlet weak var startStopButton: NSButtonCell!
    @IBOutlet weak var statusTextField: NSTextField!
    
    @IBOutlet weak var lagTextField: NSTextField! {
        didSet {
            if #available(OSX 10.11, *) {
                if let font = lagTextField.font {
                    lagTextField.font = NSFont.monospacedDigitSystemFont(ofSize: font.pointSize, weight: CGFloat(fontManager.weight(of: font)))
                }
            }
        }
    }
    
    @IBOutlet weak var packetLossTextField: NSTextField! {
        didSet {
            if #available(OSX 10.11, *) {
                if let font = packetLossTextField.font {
                    packetLossTextField.font = NSFont.monospacedDigitSystemFont(ofSize: font.pointSize, weight: CGFloat(fontManager.weight(of: font)))
                }
            }
        }
    }
    
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
                statusTextField.textColor = NSColor.orange()
            case .Error:
                statusTextField.textColor = NSColor.red()
            default:
                statusTextField.textColor = NSColor.black()
            }
        }
    }
    
    var currentLag: Double? {
        didSet {
            if let lag = currentLag {
                lagTextField.stringValue = String(format: "%.3f ms", lag)
                lagTextField.textColor = NSColor.black()
            } else {
                lagTextField.stringValue = "No data"
                lagTextField.textColor = NSColor.darkGray()
            }
        }
    }
    
    var currentLoss: Double? {
        didSet {
            if let loss = currentLoss {
                packetLossTextField.stringValue = String(format: "%3.2f%%", loss * 100)
                packetLossTextField.textColor = NSColor.black()
            } else {
                packetLossTextField.stringValue = "No data"
                packetLossTextField.textColor = NSColor.darkGray()
            }
        }
    }
    
    var pingHelper: PingHelper?
    
    @IBAction func intervalTextFieldChanged(_ sender: NSTextField) {
        guard let helper = pingHelper else {
            return
        }
        helper.interval = intervalTextField.doubleValue
        helper.start()
        savePrefs(fromPingHelper: helper)
    }
    
    @IBAction func quit(_ sender: AnyObject) {
        NSApplication.shared().terminate(self)
    }
    
    @IBAction func targetHostTextFieldChanged(_ sender: NSTextField) {
        saveHostButton.performClick(self)
    }
    
    @IBAction func saveHostButtonPressed(_ sender: NSButton) {
        guard let helper = pingHelper else {
            return
        }
        
        statusTextField.stringValue = "Starting…"
        statusTextField.textColor = NSColor.black()
        helper.host = targetHostTextField.stringValue
        helper.start()
        savePrefs(fromPingHelper: helper)
    }
    
    @IBAction func startStopButtonPressed(_ sender: NSButtonCell) {
        guard let helper = pingHelper else {
            return
        }
        
        if helper.running {
            helper.stop()
        } else {
            helper.start()
        }
    }
    
    @IBAction func launchAtLoginCheckbox(_ sender: NSButton) {
        print("Launch at login checkbox checked")
        print("Value: \(sender.state)")
    }
    
    override func viewWillAppear() {
        if let appDelegate = NSApplication.shared().delegate as? AppDelegate {
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
            NotificationCenter.default().removeObserver(helper)
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
        
        [StatusChangedNotification, PingStartedNotification, PingStoppedNotification].forEach { notification in
            
            
            
            NotificationCenter.default().addObserver(forName: notification, object: pingHelper,
                queue: OperationQueue.main()) { [unowned self] _ in
                    self.updateViewStatus(fromPingHelper: pingHelper)
            }
            
            
        }
    }
    
    private func savePrefs(fromPingHelper helper: PingHelper, usingDefaults defaults: UserDefaults = UserDefaults.standard()) {
        defaults.set(helper.host, forKey: TargetHostUserDefaultsKey)
        defaults.set(helper.interval, forKey: PingIntervalUserDefaultsKey)
        defaults.synchronize()
    }
}
