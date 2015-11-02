//
//  RateLimitTests.swift
//  RateLimit Tests
//
//  Created by Daniele Orrù on 31/10/15.
//  Copyright © 2015 Daniele Orru'. All rights reserved.
//

import XCTest

class RateLimitTests: XCTestCase {

    func testDebounceTriggersOnceWhenContinuoslyCalledBeforeThreshold()
    {
        let threshold = 1.0
        var closureCallsCount = 0
        let readyExpectation = expectationWithDescription("ready")

        let startTimestamp = NSDate().timeIntervalSince1970
        var currentTimestamp = NSDate().timeIntervalSince1970
        while((currentTimestamp - startTimestamp) < threshold - 0.5) {
            // Action: Call debounce multiple times for (threshold - 0.5) seconds
            RateLimit.debounce("debounceKey_t1", threshold: threshold) {
                ++closureCallsCount
            }
            currentTimestamp = NSDate().timeIntervalSince1970
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64((threshold + 0.5) * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            // Expectation: The closure has been called just 1 time
            XCTAssertEqual(1, closureCallsCount)
            readyExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testDebounceTriggersOnceWhenContinuoslyCalledAfterThreshold()
    {
        let threshold = 1.0
        var closureCallsCount = 0
        let readyExpectation = expectationWithDescription("ready")

        let startTimestamp = NSDate().timeIntervalSince1970
        var currentTimestamp = NSDate().timeIntervalSince1970
        while((currentTimestamp - startTimestamp) < threshold + 0.5) {
            // Action: Call debounce multiple times for (threshold + 0.5) seconds
            RateLimit.debounce("debounceKey_t2", threshold: threshold) {
                ++closureCallsCount
            }
            currentTimestamp = NSDate().timeIntervalSince1970
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64((threshold + 0.5) * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            // Expectation: The closure has been called just 1 time
            XCTAssertEqual(1, closureCallsCount)
            readyExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testDebounceTriggersWhenCalledAfterThreshold()
    {
        let threshold = 1.0
        var closureCallsCount = 0

        let readyExpectation = expectationWithDescription("ready")

        let callThrottle = {
            RateLimit.debounce("debounceKey_t3", threshold: threshold) {
                ++closureCallsCount
            }
        }

        // Action: Call the closure 1 time
        callThrottle()

        // Action: Call again the closure after *waiting* (threshold + 0.5) seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64((threshold + 0.5) * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            callThrottle()
            // Expectation: The closure has been called 2 times
            XCTAssertEqual(2, closureCallsCount)
            readyExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testDebounceRespectsTriggerAtBeginDisabled()
    {
        let threshold = 1.0
        var closureCallsCount = 0

        let readyExpectation = expectationWithDescription("ready")

        // Action: debounce with atBegin false
        RateLimit.debounce("debounceKey_t4", threshold: threshold, atBegin: false) {
            ++closureCallsCount
        }

        // Expectation: Closure should have NOT been called at this time
        XCTAssertEqual(0, closureCallsCount)

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64((threshold + 0.5) * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            // Expectation: After (threshold + 0.5) seconds, the closure has been called
            XCTAssertEqual(1, closureCallsCount)
            readyExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testDebounceRespectsTriggerAtBeginEnabled()
    {
        let threshold = 1.0
        var closureCallsCount = 0

        // Action: debounce with atBegin true
        RateLimit.debounce("debounceKey_t5", threshold: threshold) {
            ++closureCallsCount
        }

        // Expectation: Closure should have been immediately called
        XCTAssertEqual(1, closureCallsCount)
    }

    func testDebounceRespectsDifferentKeys()
    {
        let threshold = 1.0
        var closureCallsCount = 0

        // Action: call debounce twice with different keys
        RateLimit.debounce("debounceKey_t6_1", threshold: threshold) {
            ++closureCallsCount
        }
        RateLimit.debounce("debounceKey_t6_2", threshold: threshold) {
            ++closureCallsCount
        }

        // Expectation: Closure should have been called 1 time each
        XCTAssertEqual(2, closureCallsCount)
    }

    func testThrottleIgnoresTriggerWhenContinuoslyCalledBeforeThreshold()
    {
        let threshold = 1.0
        var closureCallsCount = 0
        let readyExpectation = expectationWithDescription("ready")

        let startTimestamp = NSDate().timeIntervalSince1970
        var currentTimestamp = NSDate().timeIntervalSince1970
        while((currentTimestamp - startTimestamp) < threshold - 0.5) {
            // Action: Call throttle multiple times for (threshold - 0.5) seconds
            RateLimit.throttle("throttleKey_t1", threshold: threshold) {
                ++closureCallsCount
            }
            currentTimestamp = NSDate().timeIntervalSince1970
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64((threshold + 0.5) * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            // Expectation: The closure has been called 1 time
            XCTAssertEqual(1, closureCallsCount)
            readyExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testThrottleTriggersWhenContinuoslyCalledAfterThreshold()
    {
        let threshold = 1.0
        var closureCallsCount = 0
        let readyExpectation = expectationWithDescription("ready")

        let startTimestamp = NSDate().timeIntervalSince1970
        var currentTimestamp = NSDate().timeIntervalSince1970
        while((currentTimestamp - startTimestamp) < threshold + 0.5) {
            // Action: Call throttle continuosly for (threshold + 0.5) seconds
            RateLimit.throttle("throttleKey_t2", threshold: threshold) {
                ++closureCallsCount
            }
            currentTimestamp = NSDate().timeIntervalSince1970
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64((threshold + 0.5) * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            // Expectation: Closure should have been called 2 times
            XCTAssertEqual(2, closureCallsCount)
            readyExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testThrottleAllowsTriggerAfterThreshold()
    {
        let threshold = 1.0
        var closureCallsCount = 0

        let readyExpectation = expectationWithDescription("ready")

        let callThrottle = {
            RateLimit.throttle("throttleKey_t3", threshold: threshold) {
                ++closureCallsCount
            }
        }

        // Action: Call the closure 1 time
        callThrottle()

        // Action: Call again the closure after *waiting* (threshold + 0.5) seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64((threshold + 0.5) * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            callThrottle()
            // Expectation: The closure has been called 2 times
            XCTAssertEqual(2, closureCallsCount)
            readyExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testThrottleRespectsTrailingEnabled()
    {
        let threshold = 1.0
        var closureCallsCount = 0

        let readyExpectation = expectationWithDescription("ready")

        // Action: Call throttle twice
        for _ in 1...2 {
            RateLimit.throttle("throttleKey_t4", threshold: threshold, trailing: true) {
                ++closureCallsCount
            }
        }

        // Expectation: Closure should have been called 1 time at this point
        XCTAssertEqual(1, closureCallsCount)

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64((threshold + 0.5) * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            // Expectation: Trailing is enabled, that means that another trailing closure trigger should have been performed at this point
            XCTAssertEqual(2, closureCallsCount)
            readyExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testThrottleRespectsTrailingDisabled()
    {
        let threshold = 1.0
        var closureCallsCount = 0

        let readyExpectation = expectationWithDescription("ready")

        // Action: Call throttle twice
        for _ in 1...2 {
            RateLimit.throttle("throttleKey_t5", threshold: threshold) {
                ++closureCallsCount
            }
        }

        // Expectation: The closure has been already called 1 time at this point
        XCTAssertEqual(1, closureCallsCount)

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64((threshold + 0.5) * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            // Expectation: Trailing is disabled, the closure should haven't been called more than once
            XCTAssertEqual(1, closureCallsCount)
            readyExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testThrottleRespectsDifferentKeys()
    {
        let threshold = 1.0
        var closureCallsCount = 0

        // Action: call debounce twice with different keys
        RateLimit.throttle("throttleKey_t6_1", threshold: threshold) {
            ++closureCallsCount
        }
        RateLimit.throttle("throttleKey_t6_2", threshold: threshold) {
            ++closureCallsCount
        }

        // Expectation: Closure should have been called 1 time each
        XCTAssertEqual(2, closureCallsCount)
    }
}
