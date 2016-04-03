//
//  RateLimit.swift
//  RateLimitExample
//
//  Created by Daniele Orrù on 28/06/15.
//  Copyright (c) 2015 Daniele Orru'. All rights reserved.
//

import Foundation

class ThrottleInfo {
    let key: String
    let threshold: NSTimeInterval
    let trailing: Bool
    let closure: () -> ()

    init(key: String, threshold: NSTimeInterval, trailing: Bool, closure: () -> ())
    {
        self.key = key
        self.threshold = threshold
        self.trailing = trailing
        self.closure = closure
    }
}

class ThrottleExecutionInfo {
    let lastExecutionDate: NSDate
    let timer: NSTimer?
    let throttleInfo: ThrottleInfo

    init(lastExecutionDate: NSDate, timer: NSTimer? = nil, throttleInfo: ThrottleInfo)
    {
        self.lastExecutionDate = lastExecutionDate
        self.timer = timer
        self.throttleInfo = throttleInfo
    }
}

class DebounceInfo {
    let key: String
    let threshold: NSTimeInterval
    let atBegin: Bool
    let closure: () -> ()

    init(key: String, threshold: NSTimeInterval, atBegin: Bool, closure: () -> ())
    {
        self.key = key
        self.threshold = threshold
        self.atBegin = atBegin
        self.closure = closure
    }
}

class DebounceExecutionInfo {
    let timer: NSTimer?
    let debounceInfo: DebounceInfo

    init(timer: NSTimer? = nil, debounceInfo: DebounceInfo)
    {
        self.timer = timer
        self.debounceInfo = debounceInfo
    }
}

/**
    Provide debounce and throttle functionality.
*/
public class RateLimit
{
    private static let queue = dispatch_queue_create("org.orru.RateLimit", DISPATCH_QUEUE_SERIAL)

    private static var throttleExecutionDictionary = [String : ThrottleExecutionInfo]()
    private static var debounceExecutionDictionary = [String : DebounceExecutionInfo]()

    /**
    Throttle call to a closure using a given threshold

    - parameter name:
    - parameter threshold:
    - parameter trailing:
    - parameter closure:
    */
    public static func throttle(key: String, threshold: NSTimeInterval, trailing: Bool = false, closure: ()->())
    {
        let now = NSDate()
        var canExecuteClosure = false
        if let rateLimitInfo = self.throttleInfoForKey(key) {
            let timeDifference = rateLimitInfo.lastExecutionDate.timeIntervalSinceDate(now)
            if timeDifference < 0 && fabs(timeDifference) < threshold {
                if trailing && rateLimitInfo.timer == nil {
                    let timer = NSTimer.scheduledTimerWithTimeInterval(threshold, target: self, selector: #selector(RateLimit.throttleTimerFired(_:)), userInfo: ["rateLimitInfo" : rateLimitInfo], repeats: false)
                    let throttleInfo = ThrottleInfo(key: key, threshold: threshold, trailing: trailing, closure: closure)
                    self.setThrottleInfoForKey(ThrottleExecutionInfo(lastExecutionDate: rateLimitInfo.lastExecutionDate, timer: timer, throttleInfo: throttleInfo), forKey: key)
                }
            } else {
                canExecuteClosure = true
            }
        } else {
            canExecuteClosure = true
        }
        if canExecuteClosure {
            let throttleInfo = ThrottleInfo(key: key, threshold: threshold, trailing: trailing, closure: closure)
            self.setThrottleInfoForKey(ThrottleExecutionInfo(lastExecutionDate: now, timer: nil, throttleInfo: throttleInfo), forKey: key)
            closure()
        }
    }

    @objc private static func throttleTimerFired(timer: NSTimer)
    {
        if let userInfo = timer.userInfo as? [String : AnyObject], rateLimitInfo = userInfo["rateLimitInfo"] as? ThrottleExecutionInfo {
            self.throttle(rateLimitInfo.throttleInfo.key, threshold: rateLimitInfo.throttleInfo.threshold, trailing: rateLimitInfo.throttleInfo.trailing, closure: rateLimitInfo.throttleInfo.closure)
        }
    }

    /**
    Debounce call to a closure using a given threshold

    - parameter key:
    - parameter threshold:
    - parameter atBegin:
    - parameter closure:
    */
    public static func debounce(key: String, threshold: NSTimeInterval, atBegin: Bool = true, closure: ()->())
    {
        var canExecuteClosure = false
        if let rateLimitInfo = self.debounceInfoForKey(key) {
            if let timer = rateLimitInfo.timer where timer.valid {
                timer.invalidate()
                let debounceInfo = DebounceInfo(key: key, threshold: threshold, atBegin: atBegin, closure: closure)
                let timer = NSTimer.scheduledTimerWithTimeInterval(threshold, target: self, selector: #selector(RateLimit.debounceTimerFired(_:)), userInfo: ["rateLimitInfo" : debounceInfo], repeats: false)
                self.setDebounceInfoForKey(DebounceExecutionInfo(timer: timer, debounceInfo: debounceInfo), forKey: key)

            } else {
                if (atBegin) {
                    canExecuteClosure = true
                } else {
                    let debounceInfo = DebounceInfo(key: key, threshold: threshold, atBegin: atBegin, closure: closure)
                    let timer = NSTimer.scheduledTimerWithTimeInterval(threshold, target: self, selector: #selector(RateLimit.debounceTimerFired(_:)), userInfo: ["rateLimitInfo" : debounceInfo], repeats: false)
                    self.setDebounceInfoForKey(DebounceExecutionInfo(timer: timer, debounceInfo: debounceInfo), forKey: key)
                }
            }
        } else {
            if (atBegin) {
                canExecuteClosure = true
            } else {
                let debounceInfo = DebounceInfo(key: key, threshold: threshold, atBegin: atBegin, closure: closure)
                let timer = NSTimer.scheduledTimerWithTimeInterval(threshold, target: self, selector: #selector(RateLimit.debounceTimerFired(_:)), userInfo: ["rateLimitInfo" : debounceInfo], repeats: false)
                self.setDebounceInfoForKey(DebounceExecutionInfo(timer: timer, debounceInfo: debounceInfo), forKey: key)
            }
        }
        if canExecuteClosure {
            let debounceInfo = DebounceInfo(key: key, threshold: threshold, atBegin: atBegin, closure: closure)
            let timer = NSTimer.scheduledTimerWithTimeInterval(threshold, target: self, selector: #selector(RateLimit.debounceTimerFired(_:)), userInfo: ["rateLimitInfo" : debounceInfo], repeats: false)
            self.setDebounceInfoForKey(DebounceExecutionInfo(timer: timer, debounceInfo: debounceInfo), forKey: key)
            closure()
        }
    }

    @objc private static func debounceTimerFired(timer: NSTimer)
    {
        if let userInfo = timer.userInfo as? [String : AnyObject], debounceInfo = userInfo["rateLimitInfo"] as? DebounceInfo where !debounceInfo.atBegin  {
            debounceInfo.closure()
        }
    }

    /**
     Reset rate limit information for both bouncing and throlling
     */
    public static func resetAllRateLimit()
    {
        dispatch_sync(queue) {
            for key in self.throttleExecutionDictionary.keys {
                if let rateLimitInfo = self.throttleExecutionDictionary[key], let timer = rateLimitInfo.timer where timer.valid {
                    timer.invalidate()
                }
                self.throttleExecutionDictionary[key] = nil
            }
            for key in self.debounceExecutionDictionary.keys {
                if let rateLimitInfo = self.debounceExecutionDictionary[key], let timer = rateLimitInfo.timer where timer.valid {
                    timer.invalidate()
                }
                self.debounceExecutionDictionary[key] = nil
            }
        }
    }

    /**
     Reset rate limit information for both bouncing and throlling for a specific key
     */
    public static func resetRateLimitForKey(key: String)
    {
        dispatch_sync(queue) {
            if let rateLimitInfo = self.throttleExecutionDictionary[key], let timer = rateLimitInfo.timer where timer.valid {
                timer.invalidate()
            }
            self.throttleExecutionDictionary[key] = nil
            if let rateLimitInfo = self.debounceExecutionDictionary[key], let timer = rateLimitInfo.timer where timer.valid {
                timer.invalidate()
            }
            self.debounceExecutionDictionary[key] = nil
        }
    }

    private static func throttleInfoForKey(key: String) -> ThrottleExecutionInfo?
    {
        var rateLimitInfo: ThrottleExecutionInfo?
        dispatch_sync(queue) {
            rateLimitInfo = self.throttleExecutionDictionary[key]
        }
        return rateLimitInfo
    }

    private static func setThrottleInfoForKey(rateLimitInfo: ThrottleExecutionInfo, forKey key: String)
    {
        dispatch_sync(queue) {
            self.throttleExecutionDictionary[key] = rateLimitInfo
        }
    }

    private static func debounceInfoForKey(key: String) -> DebounceExecutionInfo?
    {
        var rateLimitInfo: DebounceExecutionInfo?
        dispatch_sync(queue) {
            rateLimitInfo = self.debounceExecutionDictionary[key]
        }
        return rateLimitInfo
    }

    private static func setDebounceInfoForKey(rateLimitInfo: DebounceExecutionInfo, forKey key: String)
    {
        dispatch_sync(queue) {
            self.debounceExecutionDictionary[key] = rateLimitInfo
        }
    }
}
