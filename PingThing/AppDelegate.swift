import Cocoa

let TargetHostUserDefaultsKey = "target-host"
let PingIntervalUserDefaultsKey = "ping-interval"

let DefaultHost = "8.8.8.8"
let DefaultInterval = 2.0

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
    
    let StatusMenuItemTag = 0
    let StartStopMenuItemTag = 1
    
    var host: String = DefaultHost
    var interval: Double = DefaultInterval
    
    private(set)
    var pingHelper: PingHelper?
    
    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
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
    
    func checkUserDefaultsAndLoad(_ defaults: UserDefaults = UserDefaults.standard()) {
        if let hostFromPrefs = defaults.object(forKey: TargetHostUserDefaultsKey) as? String {
            self.host = hostFromPrefs
        }
        if let intervalFromPrefs = defaults.object(forKey: PingIntervalUserDefaultsKey) as? Double {
            self.interval = intervalFromPrefs
        }
    }
    
    private func buildMenu(_ helper: PingHelper) -> NSMenu {
        let menu = NSMenu()
        
        let statusMenuItem = NSMenuItem(title: "Status: \(helper.status)", action: nil, keyEquivalent: "")
        statusMenuItem.tag = StatusMenuItemTag
        
        let startStopMenuItem = NSMenuItem(title: "Start",  action: #selector(AppDelegate.startStopPing(_:)), keyEquivalent: "")
        startStopMenuItem.representedObject = helper
        startStopMenuItem.tag = StartStopMenuItemTag
        
        menu.addItem(statusMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(startStopMenuItem)
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(AppDelegate.openPrefsWindow(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit PingThing", action: #selector(NSApplication.shared().terminate), keyEquivalent: ""))
        
        updateMenus(fromHelper: helper)

        return menu
    }
    
    private func listenToPings(_ helper: PingHelper) {
        [StatusChangedNotification, PingStartedNotification, PingStoppedNotification].forEach { notification in
            NotificationCenter.default().addObserver(forName: notification, object: helper,
                queue: OperationQueue.main()) { [unowned self] _ in
                    self.updateMenus(fromHelper: helper)
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
            if let statusMenu = menu.item(withTag: StatusMenuItemTag) {
                statusMenu.title = "Status: \(helper.status.rawValue)"
            }
            
            if let startStopMenu = menu.item(withTag: StartStopMenuItemTag) {
                startStopMenu.title = helper.running ? "Pause" : "Start"
            }
        }
    }
    
    func startStopPing(_ sender: NSMenuItem) {
        if let helper = sender.representedObject as? PingHelper {
            helper.running ? helper.stop() : helper.start()
        }
    }
    
    func openPrefsWindow(_ sender: AnyObject) {
        window.makeKeyAndOrderFront(self)
        NSApp.activateIgnoringOtherApps(true)
    }
}

