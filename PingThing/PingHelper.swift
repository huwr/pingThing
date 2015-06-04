//
//  PingHelper.swift
//  PingThing
//
//  Created by Huw Rowlands on 3.6.2015.
//  Copyright (c) 2015 DiUS Computing Pty Ltd. All rights reserved.
//

import Cocoa

let StatusChangedNotification = "status-changed-notification"
let PingStoppedNotification = "ping-stopped-notification"
let PingStartedNotification = "ping-started-notification"

enum Status: String {
    case Success = "OK"
    case Failure = "Failing"
    case Error = "Error"
    case Unknown = "Unknown"
    case NotRunning = "Not Running"
}

class PingHelper: NSObject {
    var simplePing: SimplePing?
    private var pingTimer: NSTimer?
    private var lastSequenceSent: UInt16?
    private var lastSentTime: NSDate?
    var maxLagTimes = 10
    var lagTimes = [Double?]()
    private var lastLag: Double? {
        didSet {
            lagTimes.append(lastLag)
            if lagTimes.count > maxLagTimes {
                lagTimes.removeRange(0..<(lagTimes.count - maxLagTimes))
            }
        }
    }

    var averageLag: Double? {
        get {
            let filteredArray = lagTimes.filter { $0 != nil }
            
            if filteredArray.count == 0 {
                return nil
            }
            
            return Double(filteredArray.reduce(0.0) { $0 + $1! }) / Double(filteredArray.count)
        }
    }
    
    var dropOutRate: Double {
        if lagTimes.count == 0 {
            return 0
        }
        let dropOuts = lagTimes.filter { $0 == nil }.count
        return Double(dropOuts) / Double(lagTimes.count)
    }
    
    private(set) var running = false {
        didSet {
            if running {
                NSNotificationCenter.defaultCenter().postNotificationName(PingStartedNotification, object: self)
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName(PingStoppedNotification, object: self)
            }
        }
    }

    private(set) var status = Status.Unknown {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(StatusChangedNotification, object: self)
        }
    }
    
    var interval = 2.0 { /* secs */
        didSet {
            restart()
        }
    }
    
    var host: String = "" {
        didSet {
            restart()
        }
    }
    
    func restart() {
        stop()
        start()
    }
    
    func start() {
        println("starting…")
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
        println("stopping…")
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
        println("sending ping")
        if let pinger = simplePing {
            pinger.sendPingWithData(nil)
        }
    }
}

extension PingHelper: SimplePingDelegate {
    func simplePing(pinger: SimplePing!, didStartWithAddress address: NSData!) {
        println("did start")
        self.sendPing()
        status = Status.Unknown
        pingTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: Selector("sendPing"), userInfo: nil, repeats: true)
    }
    
    func simplePing(pinger: SimplePing!, didFailWithError error: NSError!) {
        //everything's ruined.
        status = Status.Failure
        println("failed with error: \(error)")
    }
    
    func simplePing(pinger: SimplePing!, didSendPacket packet: NSData!, withSequenceNumber sequenceNumber:UInt16) {
        let seqNo = CFSwapInt16BigToHost(sequenceNumber)
        
        lastSequenceSent = seqNo
        lastSentTime = NSDate()
        
        println("ping \(seqNo)")
    }
    
    func simplePing(pinger: SimplePing!, didFailToSendPacket packet: NSData!, error: NSError!) {
        status = Status.Error
        println("failed to send packet")
    }
    
    func simplePing(pinger: SimplePing!, didReceivePingResponsePacket packet: NSData!) {
        status = Status.Success
        
        let seqNo = CFSwapInt16BigToHost(SimplePing.icmpInPacket(packet).memory.sequenceNumber)
        
        if seqNo < lastSequenceSent {
            println("out of order")
        } else {
            if let lastTime = lastSentTime {
                lastLag = NSDate().timeIntervalSinceDate(lastTime) * 1_000
                println("pong \(seqNo) lat \(lastLag)")
            }
        }
    }
    
    func simplePing(pinger: SimplePing!, didReceiveUnexpectedPacket packet: NSData!) {
//        println("received unexpected packet")
    }
}
