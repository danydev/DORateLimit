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
    let threshold: TimeInterval
    let trailing: Bool
    let closure: () -> ()

    init(key: String, threshold: TimeInterval, trailing: Bool, closure: @escaping () -> ())
    {
        self.key = key
        self.threshold = threshold
        self.trailing = trailing
        self.closure = closure
    }
}

class ThrottleExecutionInfo {
    let lastExecutionDate: Date
    let timer: Timer?
    let throttleInfo: ThrottleInfo

    init(lastExecutionDate: Date, timer: Timer? = nil, throttleInfo: ThrottleInfo)
    {
        self.lastExecutionDate = lastExecutionDate
        self.timer = timer
        self.throttleInfo = throttleInfo
    }
}

class DebounceInfo {
    let key: String
    let threshold: TimeInterval
    let atBegin: Bool
    let closure: () -> ()

    init(key: String, threshold: TimeInterval, atBegin: Bool, closure: @escaping () -> ())
    {
        self.key = key
        self.threshold = threshold
        self.atBegin = atBegin
        self.closure = closure
    }
}

class DebounceExecutionInfo {
    let timer: Timer?
    let debounceInfo: DebounceInfo

    init(timer: Timer? = nil, debounceInfo: DebounceInfo)
    {
        self.timer = timer
        self.debounceInfo = debounceInfo
    }
}

/**
    Provide debounce and throttle functionality.
*/
open class RateLimit
{
    fileprivate static let queue = DispatchQueue(label: "org.orru.RateLimit", attributes: [])

    fileprivate static var throttleExecutionDictionary = [String : ThrottleExecutionInfo]()
    fileprivate static var debounceExecutionDictionary = [String : DebounceExecutionInfo]()

    /**
    Throttle call to a closure using a given threshold

    - parameter name:
    - parameter threshold:
    - parameter trailing:
    - parameter closure:
    */
    public static func throttle(_ key: String, threshold: TimeInterval, trailing: Bool = false, closure: @escaping ()->())
    {
        let now = Date()
        var canExecuteClosure = false
        if let rateLimitInfo = self.throttleInfoForKey(key) {
            let timeDifference = rateLimitInfo.lastExecutionDate.timeIntervalSince(now)
            if timeDifference < 0 && fabs(timeDifference) < threshold {
                if trailing && rateLimitInfo.timer == nil {
                    let timer = Timer.scheduledTimer(timeInterval: threshold, target: self, selector: #selector(RateLimit.throttleTimerFired(_:)), userInfo: ["rateLimitInfo" : rateLimitInfo], repeats: false)
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

    @objc fileprivate static func throttleTimerFired(_ timer: Timer)
    {
        if let userInfo = timer.userInfo as? [String : AnyObject], let rateLimitInfo = userInfo["rateLimitInfo"] as? ThrottleExecutionInfo {
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
    public static func debounce(_ key: String, threshold: TimeInterval, atBegin: Bool = true, closure: @escaping ()->())
    {
        var canExecuteClosure = false
        if let rateLimitInfo = self.debounceInfoForKey(key) {
            if let timer = rateLimitInfo.timer, timer.isValid {
                timer.invalidate()
                let debounceInfo = DebounceInfo(key: key, threshold: threshold, atBegin: atBegin, closure: closure)
                let timer = Timer.scheduledTimer(timeInterval: threshold, target: self, selector: #selector(RateLimit.debounceTimerFired(_:)), userInfo: ["rateLimitInfo" : debounceInfo], repeats: false)
                self.setDebounceInfoForKey(DebounceExecutionInfo(timer: timer, debounceInfo: debounceInfo), forKey: key)

            } else {
                if (atBegin) {
                    canExecuteClosure = true
                } else {
                    let debounceInfo = DebounceInfo(key: key, threshold: threshold, atBegin: atBegin, closure: closure)
                    let timer = Timer.scheduledTimer(timeInterval: threshold, target: self, selector: #selector(RateLimit.debounceTimerFired(_:)), userInfo: ["rateLimitInfo" : debounceInfo], repeats: false)
                    self.setDebounceInfoForKey(DebounceExecutionInfo(timer: timer, debounceInfo: debounceInfo), forKey: key)
                }
            }
        } else {
            if (atBegin) {
                canExecuteClosure = true
            } else {
                let debounceInfo = DebounceInfo(key: key, threshold: threshold, atBegin: atBegin, closure: closure)
                let timer = Timer.scheduledTimer(timeInterval: threshold, target: self, selector: #selector(RateLimit.debounceTimerFired(_:)), userInfo: ["rateLimitInfo" : debounceInfo], repeats: false)
                self.setDebounceInfoForKey(DebounceExecutionInfo(timer: timer, debounceInfo: debounceInfo), forKey: key)
            }
        }
        if canExecuteClosure {
            let debounceInfo = DebounceInfo(key: key, threshold: threshold, atBegin: atBegin, closure: closure)
            let timer = Timer.scheduledTimer(timeInterval: threshold, target: self, selector: #selector(RateLimit.debounceTimerFired(_:)), userInfo: ["rateLimitInfo" : debounceInfo], repeats: false)
            self.setDebounceInfoForKey(DebounceExecutionInfo(timer: timer, debounceInfo: debounceInfo), forKey: key)
            closure()
        }
    }

    @objc fileprivate static func debounceTimerFired(_ timer: Timer)
    {
        if let userInfo = timer.userInfo as? [String : AnyObject], let debounceInfo = userInfo["rateLimitInfo"] as? DebounceInfo, !debounceInfo.atBegin  {
            debounceInfo.closure()
        }
    }

    /**
     Reset rate limit information for both bouncing and throlling
     */
    public static func resetAllRateLimit()
    {
        queue.sync {
            for key in self.throttleExecutionDictionary.keys {
                if let rateLimitInfo = self.throttleExecutionDictionary[key], let timer = rateLimitInfo.timer, timer.isValid {
                    timer.invalidate()
                }
                self.throttleExecutionDictionary[key] = nil
            }
            for key in self.debounceExecutionDictionary.keys {
                if let rateLimitInfo = self.debounceExecutionDictionary[key], let timer = rateLimitInfo.timer, timer.isValid {
                    timer.invalidate()
                }
                self.debounceExecutionDictionary[key] = nil
            }
        }
    }

    /**
     Reset rate limit information for both bouncing and throlling for a specific key
     */
    public static func resetRateLimitForKey(_ key: String)
    {
        queue.sync {
            if let rateLimitInfo = self.throttleExecutionDictionary[key], let timer = rateLimitInfo.timer, timer.isValid {
                timer.invalidate()
            }
            self.throttleExecutionDictionary[key] = nil
            if let rateLimitInfo = self.debounceExecutionDictionary[key], let timer = rateLimitInfo.timer, timer.isValid {
                timer.invalidate()
            }
            self.debounceExecutionDictionary[key] = nil
        }
    }

    fileprivate static func throttleInfoForKey(_ key: String) -> ThrottleExecutionInfo?
    {
        var rateLimitInfo: ThrottleExecutionInfo?
        queue.sync {
            rateLimitInfo = self.throttleExecutionDictionary[key]
        }
        return rateLimitInfo
    }

    fileprivate static func setThrottleInfoForKey(_ rateLimitInfo: ThrottleExecutionInfo, forKey key: String)
    {
        queue.sync {
            self.throttleExecutionDictionary[key] = rateLimitInfo
        }
    }

    fileprivate static func debounceInfoForKey(_ key: String) -> DebounceExecutionInfo?
    {
        var rateLimitInfo: DebounceExecutionInfo?
        queue.sync {
            rateLimitInfo = self.debounceExecutionDictionary[key]
        }
        return rateLimitInfo
    }

    fileprivate static func setDebounceInfoForKey(_ rateLimitInfo: DebounceExecutionInfo, forKey key: String)
    {
        queue.sync {
            self.debounceExecutionDictionary[key] = rateLimitInfo
        }
    }
}
