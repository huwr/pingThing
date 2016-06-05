//
//  PingHelperTests.swift
//  PingThing
//
//  Created by Huw Rowlands on 11.6.2015.
//  Copyright (c) 2015 DiUS Computing Pty Ltd. All rights reserved.
//

import Cocoa
import XCTest

class PingHelperTests: XCTestCase {

    let testHost = "www.example.com"
    let testInterval = 40.0
    let testSamples = 100

//    override func setUp() {
//        super.setUp()
//    }
    
    func testInit() {
        let pingHelper = PingHelper(host: testHost, interval: testInterval, numberOfSamples: testSamples)
        XCTAssert(pingHelper.host == testHost, "host is right")
        XCTAssert(pingHelper.interval == testInterval, "interval is right")
        XCTAssert(pingHelper.numberOfSamples == testSamples, "number of samples is right")
    }
    
    func testAverageLagShouldReturnNilIfNotRunning() {
        let pingHelper = PingHelper()
        XCTAssert(!pingHelper.running, "helper is not running")
        XCTAssert(pingHelper.averageLag == nil)
    }
    
    func testAverageLagShouldReturnAverageOfLagTimes() {
        class MockPingHelper: PingHelper {
            override var running: Bool {
                get {
                    return true
                }
            }
            override var lagTimes: [Double?] {
                get {
                    return [1.0, 2.0, 3.0]
                }
            }
        }
        let pingHelper = MockPingHelper()
        XCTAssertEqual(pingHelper.averageLag!, 2.0)
    }
    
    func testAverageLagShouldIgnoreNilsWhenCalculatingAverage() {
        class MockPingHelper: PingHelper {
            override var running: Bool {
                get {
                    return true
                }
            }
            override var lagTimes: [Double?] {
                get {
                    return [nil, nil, 3.0, nil]
                }
            }
        }
        let pingHelper = MockPingHelper()
        XCTAssertEqual(pingHelper.averageLag!, 3.0)
    }
    
    func testAverageLagShouldReturnNilIfThereAreNoSamples() {
        class MockPingHelper: PingHelper {
            override var running: Bool {
                get {
                    return true
                }
            }
        }
        let pingHelper = MockPingHelper()
        XCTAssert(pingHelper.averageLag == nil)
    }
    
    func testDropOutRateShouldReturnNilIfNotRunning() {
        let pingHelper = PingHelper()
        XCTAssert(!pingHelper.running, "helper is not running")
        XCTAssert(pingHelper.dropOutRate == nil)
    }
    
    func testDropOutRateShouldReturn0ForNoSamples() {
        class MockPingHelper: PingHelper {
            override var running: Bool {
                get {
                    return true
                }
            }
        }
        let pingHelper = MockPingHelper()
        XCTAssertEqual(pingHelper.dropOutRate!, 0.0)
    }
    
    func testDropOutRateShouldReturnRateOfDropOuts() {
        class MockPingHelper: PingHelper {
            override var running: Bool {
                get {
                    return true
                }
            }
            override var lagTimes: [Double?] {
                get {
                    return [nil, nil, 3.0, nil]
                }
            }
        }
        let pingHelper = MockPingHelper()
        XCTAssertEqual(pingHelper.dropOutRate!, (3/4.0))
    }
    
    func testStartingShouldStopBeforeStartingIfAlreadyRunning() {
        class MockPingHelper: PingHelper {
            var stopWasCalled = false
            override var running: Bool {
                get {
                    return true
                }
            }
            override func stop() {
                stopWasCalled = true
                super.stop()
            }
        }
        
        let pingHelper = MockPingHelper()
        pingHelper.start()
        XCTAssert(pingHelper.stopWasCalled)
    }
}
