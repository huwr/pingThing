import Cocoa

let StatusChangedNotification = Notification.Name(rawValue: "status-changed-notification")
let PingStoppedNotification = Notification.Name(rawValue: "ping-stopped-notification")
let PingStartedNotification = Notification.Name(rawValue: "ping-started-notification")

enum Status: String {
    case Success = "OK"
    case Failure = "Failing"
    case Error = "Error"
    case Unknown = "Unknown"
    case NotRunning = "Not Running"
}

class PingHelper: NSObject {
    private static let DefaultNumberOfSamples = 10
    
    var host: String
    var interval: Double
    var numberOfSamples: Int
    
    var simplePing: SimplePing?
    private var pingTimer: Timer?
    private var lastSequenceSent: UInt16?
    private var lastSentTime: Date?
    private(set) var lagTimes = [Double?]()
    private var lastLag: Double? {
        didSet {
            lagTimes.append(lastLag)
            if lagTimes.count > numberOfSamples {
                lagTimes.removeSubrange(0..<(lagTimes.count - numberOfSamples))
            }
        }
    }

    var averageLag: Double? {
        get {
            if !self.running {
                return nil
            }
            
            let filteredArray = lagTimes.filter { $0 != nil }
            
            if filteredArray.count == 0 {
                return nil
            }
            
            return Double(filteredArray.reduce(0.0) { $0 + $1! }) / Double(filteredArray.count)
        }
    }
    
    var dropOutRate: Double? {
        if !self.running {
            return nil
        }
        if lagTimes.count == 0 {
            return 0
        }
        let dropOuts = lagTimes.filter { $0 == nil }.count
        return Double(dropOuts) / Double(lagTimes.count)
    }
    
    private(set) var running = false {
        didSet {
            if running {
                NotificationCenter.default().post(name: PingStartedNotification, object: self)
            } else {
                NotificationCenter.default().post(name: PingStoppedNotification, object: self)
            }
        }
    }

    private(set) var status = Status.Unknown {
        didSet {
            NotificationCenter.default().post(name: StatusChangedNotification, object: self)
        }
    }
    
    init(host: String = DefaultHost, interval: Double = DefaultInterval, numberOfSamples: Int = DefaultNumberOfSamples) {
        self.host = host
        self.interval = interval
        self.numberOfSamples = numberOfSamples
    }
    
    func start() {
        if self.running {
            stop()
        }
        
        print("starting…")
        status = Status.Unknown
        simplePing = SimplePing(hostName: host)
            
        if let pinger = simplePing {
            pinger.delegate = self
            pinger.start()
            running = true
        } else {
            stop()
        }
        
    }
    
    func stop() {
        print("stopping…")

        if let pinger = simplePing {
            pinger.stop()
        }
        if let timer = pingTimer {
            timer.invalidate()
        }
        running = false
        status = Status.NotRunning
    }

    func sendPing() {
        if let pinger = simplePing {
            pinger.send(with: nil)
        }
    }
}

extension PingHelper: SimplePingDelegate {
    func simplePing(_ pinger: SimplePing!, didStartWithAddress address: Data!) {
        print("did start")
        self.sendPing()
        status = Status.Unknown
        pingTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(PingHelper.sendPing), userInfo: nil, repeats: true)
    }
    
    func simplePing(_ pinger: SimplePing!, didFailWithError error: NSError!) {
        status = Status.Failure
        print("failed with error: \(error)")
    }
    
    func simplePing(_ pinger: SimplePing!, didSendPacket packet: Data!, withSequenceNumber sequenceNumber:UInt16) {
        let seqNo = CFSwapInt16BigToHost(sequenceNumber)
        
        lastSequenceSent = seqNo
        lastSentTime = Date()
    }
    
    func simplePing(_ pinger: SimplePing!, didFailToSendPacket packet: Data!, error: NSError!) {
        status = Status.Error
        print("failed to send packet")
    }
    
    func simplePing(_ pinger: SimplePing!, didReceivePingResponsePacket packet: Data!) {
        status = Status.Success
        
        let seqNo = CFSwapInt16BigToHost(SimplePing.icmp(inPacket: packet).pointee.sequenceNumber)
        
        if seqNo < lastSequenceSent {
            print("out of order")
        } else {
            if let lastTime = lastSentTime {
                lastLag = Date().timeIntervalSince(lastTime) * 1_000
                print("pong \(seqNo) - lag \(lastLag)")
                print("running average: \(averageLag)")
            }
        }
    }
    
    func simplePing(_ pinger: SimplePing!, didReceiveUnexpectedPacket packet: Data!) {
//        println("received unexpected packet")
    }

}
