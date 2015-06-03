//
//  PingHelper.swift
//  PingThing
//
//  Created by Huw Rowlands on 3.6.2015.
//  Copyright (c) 2015 DiUS Computing Pty Ltd. All rights reserved.
//

import Cocoa

let PingReceivedNotification = "ping-received-notification"
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
    var interval = 2.0 /* secs */
    private var pingTimer: NSTimer?

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
            NSNotificationCenter.defaultCenter().postNotificationName(PingReceivedNotification, object: self)
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
    
    func simplePing(pinger: SimplePing!, didSendPacket packet: NSData!) {
        println("ping!")
    }
    
    func simplePing(pinger: SimplePing!, didFailToSendPacket packet: NSData!, error: NSError!) {
        status = Status.Error
        println("failed to send packet")
    }
    
    func simplePing(pinger: SimplePing!, didReceivePingResponsePacket packet: NSData!) {
        status = Status.Success
        println("pong!");
    }
    
    func simplePing(pinger: SimplePing!, didReceiveUnexpectedPacket packet: NSData!) {
//        println("received unexpected packet")
    }
}