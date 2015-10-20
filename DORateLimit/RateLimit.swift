//
//  RateLimit.swift
//  RateLimitExample
//
//  Created by Daniele Orrù on 28/06/15.
//  Copyright (c) 2015 Daniele Orru'. All rights reserved.
//

import Foundation

// TODO: Merge RateLimitInfo with RateLimitInfo2
class RateLimitInfo: NSObject {
    let lastExecutionDate: NSDate
    let timer: NSTimer?
    let throttleInfo: ThrottleInfo

    init(lastExecutionDate: NSDate, timer: NSTimer? = nil, throttleInfo: ThrottleInfo)
    {
        self.lastExecutionDate = lastExecutionDate
        self.timer = timer
        self.throttleInfo = throttleInfo
        super.init()
    }
}

// TODO: Rename class
class RateLimitInfo2: NSObject {
    let timer: NSTimer?
    let debounceInfo: DebounceInfo

    init(timer: NSTimer? = nil, debounceInfo: DebounceInfo)
    {
        self.timer = timer
        self.debounceInfo = debounceInfo
        super.init()
    }
}

// TODO: Merge ThrottleInfo with DebounceInfo
class ThrottleInfo: NSObject {
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
        super.init()
    }
}

// TODO: Merge ThrottleInfo with DebounceInfo
class DebounceInfo: NSObject {
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
        super.init()
    }
}

/**
*    Provide debounce and throttle functionality.
*/
public class RateLimit
{
    // TODO: Rename queue with a generic name
    private static let debounceQueue = dispatch_queue_create("org.orru.RateLimit", DISPATCH_QUEUE_SERIAL)

    // TODO: merge rateLimitDictionary with rateLimitDictionary2
    private static var rateLimitDictionary = [String : RateLimitInfo]()
    private static var rateLimitDictionary2 = [String : RateLimitInfo2]()

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
        if let rateLimitInfo = self.rateLimitInfoForKey(key) {
            let timeDifference = rateLimitInfo.lastExecutionDate.timeIntervalSinceDate(now)
            if timeDifference < 0 && fabs(timeDifference) < threshold {
                //NSLog("discarded (timeDifference: \(timeDifference) - threshold: \(threshold)")
                if trailing && rateLimitInfo.timer == nil {
                    let timer = NSTimer.scheduledTimerWithTimeInterval(threshold, target: self, selector: "throttleTimerFired:", userInfo: ["rateLimitInfo" : rateLimitInfo], repeats: false)
                    let throttleInfo = ThrottleInfo(key: key, threshold: threshold, trailing: trailing, closure: closure)
                    self.setRateLimitInfoForKey(RateLimitInfo(lastExecutionDate: rateLimitInfo.lastExecutionDate, timer: timer, throttleInfo: throttleInfo), forKey: key)
                }
            } else {
                canExecuteClosure = true
            }
        } else {
            canExecuteClosure = true
        }
        if canExecuteClosure {
            //NSLog("OK")
            let throttleInfo = ThrottleInfo(key: key, threshold: threshold, trailing: trailing, closure: closure)
            self.setRateLimitInfoForKey(RateLimitInfo(lastExecutionDate: now, timer: nil, throttleInfo: throttleInfo), forKey: key)
            closure()
        }
    }

    @objc private static func throttleTimerFired(timer: NSTimer)
    {
        // TODO: use constant for "rateLimitInfo"
        let id = timer.userInfo!["rateLimitInfo"] as! RateLimitInfo
        self.throttle(id.throttleInfo.key, threshold: id.throttleInfo.threshold, trailing: id.throttleInfo.trailing, closure: id.throttleInfo.closure)
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
        if let rateLimitInfo = self.rateLimitInfoForKey2(key) {
            if let timer = rateLimitInfo.timer where timer.valid {
                timer.invalidate()
                let debounceInfo = DebounceInfo(key: key, threshold: threshold, atBegin: atBegin, closure: closure)
                // TODO: use constant for "rateLimitInfo"
                let timer = NSTimer.scheduledTimerWithTimeInterval(threshold, target: self, selector: "throttleTimerFired2:", userInfo: ["rateLimitInfo" : debounceInfo], repeats: false)
                self.setRateLimitInfoForKey2(RateLimitInfo2(timer: timer, debounceInfo: debounceInfo), forKey: key)

            } else {
                if (atBegin) {
                    canExecuteClosure = true
                } else {
                    let debounceInfo = DebounceInfo(key: key, threshold: threshold, atBegin: atBegin, closure: closure)
                    // TODO: use constant for "rateLimitInfo"
                    let timer = NSTimer.scheduledTimerWithTimeInterval(threshold, target: self, selector: "throttleTimerFired2:", userInfo: ["rateLimitInfo" : debounceInfo], repeats: false)
                    self.setRateLimitInfoForKey2(RateLimitInfo2(timer: timer, debounceInfo: debounceInfo), forKey: key)
                }
            }
        } else {
            if (atBegin) {
                canExecuteClosure = true
            } else {
                let debounceInfo = DebounceInfo(key: key, threshold: threshold, atBegin: atBegin, closure: closure)
                // TODO: use constant for "rateLimitInfo"
                let timer = NSTimer.scheduledTimerWithTimeInterval(threshold, target: self, selector: "throttleTimerFired2:", userInfo: ["rateLimitInfo" : debounceInfo], repeats: false)
                self.setRateLimitInfoForKey2(RateLimitInfo2(timer: timer, debounceInfo: debounceInfo), forKey: key)
            }
        }
        if canExecuteClosure {
            let debounceInfo = DebounceInfo(key: key, threshold: threshold, atBegin: atBegin, closure: closure)
            // TODO: use constant for "rateLimitInfo"
            let timer = NSTimer.scheduledTimerWithTimeInterval(threshold, target: self, selector: "throttleTimerFired2:", userInfo: ["rateLimitInfo" : debounceInfo], repeats: false)
            self.setRateLimitInfoForKey2(RateLimitInfo2(timer: timer, debounceInfo: debounceInfo), forKey: key)
            closure()
        }
    }

    // TODO: Rename method
    @objc private static func throttleTimerFired2(timer: NSTimer)
    {
        // TODO: use constant for "rateLimitInfo"
        let id = timer.userInfo!["rateLimitInfo"] as! DebounceInfo
        if (!id.atBegin) {
            id.closure()
        }
    }

    public static func resetAllRateLimit()
    {
        dispatch_sync(debounceQueue) {
            for key in self.rateLimitDictionary.keys {
                if let rateLimitInfo = self.rateLimitDictionary[key], let timer = rateLimitInfo.timer where timer.valid {
                    timer.invalidate()
                }
                self.rateLimitDictionary[key] = nil
            }
            for key in self.rateLimitDictionary2.keys {
                if let rateLimitInfo = self.rateLimitDictionary2[key], let timer = rateLimitInfo.timer where timer.valid {
                    timer.invalidate()
                }
                self.rateLimitDictionary2[key] = nil
            }
        }
    }

    public static func resetRateLimitForKey(key: String)
    {
        dispatch_sync(debounceQueue) {
            if let rateLimitInfo = self.rateLimitDictionary[key], let timer = rateLimitInfo.timer where timer.valid {
                timer.invalidate()
            }
            self.rateLimitDictionary[key] = nil
            if let rateLimitInfo = self.rateLimitDictionary2[key], let timer = rateLimitInfo.timer where timer.valid {
                timer.invalidate()
            }
            self.rateLimitDictionary2[key] = nil
        }
    }

    // TODO: merge rateLimitInfoForKey with rateLimitInfoForKey2
    private static func rateLimitInfoForKey(key: String) -> RateLimitInfo?
    {
        var rateLimitInfo: RateLimitInfo?
        dispatch_sync(debounceQueue) {
            rateLimitInfo = self.rateLimitDictionary[key]
        }
        return rateLimitInfo
    }

    // TODO: merge rateLimitInfoForKey with rateLimitInfoForKey2
    private static func rateLimitInfoForKey2(key: String) -> RateLimitInfo2?
    {
        var rateLimitInfo: RateLimitInfo2?
        dispatch_sync(debounceQueue) {
            rateLimitInfo = self.rateLimitDictionary2[key]
        }
        return rateLimitInfo
    }

    // TODO: merge setRateLimitInfoForKey with setRateLimitInfoForKey2
    private static func setRateLimitInfoForKey(rateLimitInfo: RateLimitInfo, forKey key: String)
    {
        dispatch_sync(debounceQueue) {
            self.rateLimitDictionary[key] = rateLimitInfo
        }
    }

    // TODO: merge setRateLimitInfoForKey with setRateLimitInfoForKey2
    private static func setRateLimitInfoForKey2(rateLimitInfo: RateLimitInfo2, forKey key: String)
    {
        dispatch_sync(debounceQueue) {
            self.rateLimitDictionary2[key] = rateLimitInfo
        }
    }
}
