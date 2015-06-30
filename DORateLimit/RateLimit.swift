//
//  RateLimit.swift
//  RateLimitExample
//
//  Created by Daniele Orrù on 28/06/15.
//  Copyright (c) 2015 Daniele Orru'. All rights reserved.
//

import Foundation

struct RateLimitInfo {
    let lastExecutionDate: NSDate
    let scheduled: Bool
}

/**
*    Provide debounce and throttle functionality.
*/
public class RateLimit
{
    private static let debounceQueue = dispatch_queue_create("org.orru.RateLimit", DISPATCH_QUEUE_SERIAL)
    private static var rateLimitDictionary = [String : RateLimitInfo]()

    /**
    Trhrottle call to a closure using a given threshold

    :param: name
    :param: threshold
    :param: trailing
    :param: closure
    */
    public static func throttle(name: String, threshold: NSTimeInterval, trailing: Bool = false, closure: ()->())
    {
        let now = NSDate()
        var canExecuteClosure = false
        if let rateLimitInfo = self.rateLimitInfoForKey(name) {
            let timeDifference = rateLimitInfo.lastExecutionDate.timeIntervalSinceDate(now)
            if timeDifference < 0 && fabs(timeDifference) < threshold {
                //NSLog("discarded (timeDifference: \(timeDifference) - threshold: \(threshold)")

                if trailing && !rateLimitInfo.scheduled {
                    self.setRateLimitInfoForKey(RateLimitInfo(lastExecutionDate: rateLimitInfo.lastExecutionDate, scheduled: true), forKey: name)
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * Int64(threshold)), dispatch_get_main_queue(), {
                        self.throttle(name, threshold: threshold, trailing: trailing, closure: closure)
                    })
                }
            } else {
                canExecuteClosure = true
            }
        } else {
            canExecuteClosure = true
        }
        if canExecuteClosure {
            NSLog("OK")
            self.setRateLimitInfoForKey(RateLimitInfo(lastExecutionDate: now, scheduled: false), forKey: name)
            closure()
        }
    }

    public static func debounce(name: String, threshold: NSTimeInterval, atBegin: Bool = true, closure: ()->())
    {
        let now = NSDate()
        var canExecuteClosure = false
        var scheduled = false
        if let rateLimitInfo = self.rateLimitInfoForKey(name) {
            scheduled = rateLimitInfo.scheduled
            let timeDifference = rateLimitInfo.lastExecutionDate.timeIntervalSinceDate(now)
            if timeDifference < 0 && fabs(timeDifference) < threshold {
                //NSLog("discarded (timeDifference: \(timeDifference) - threshold: \(threshold)")
            } else {
                canExecuteClosure = true
            }
        } else {
            canExecuteClosure = true
        }
        if canExecuteClosure {
            self.setRateLimitInfoForKey(RateLimitInfo(lastExecutionDate: now, scheduled: scheduled), forKey: name)
            if atBegin {
                //NSLog("OK")
                closure()
            } else {
                if let rateLimitInfo = self.rateLimitInfoForKey(name) {
                    if !rateLimitInfo.scheduled {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * Int64(threshold)), dispatch_get_main_queue(), {
                            self.debounce2(name, threshold: threshold, atBegin: atBegin, closure: closure)
                        })
                    }
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * Int64(threshold)), dispatch_get_main_queue(), {
                        self.debounce2(name, threshold: threshold, atBegin: atBegin, closure: closure)
                    })
                }
            }
        } else {
            //NSLog("discarded")
            if !atBegin {
                self.setRateLimitInfoForKey(RateLimitInfo(lastExecutionDate: now, scheduled: scheduled), forKey: name)
            }
        }
    }

    public static func debounce2(name: String, threshold: NSTimeInterval, atBegin: Bool = true, closure: ()->())
    {
        let now = NSDate()
        if let rateLimitInfo = self.rateLimitInfoForKey(name) {
            let timeDifference = rateLimitInfo.lastExecutionDate.timeIntervalSinceDate(now)
            if timeDifference < 0 && fabs(timeDifference) < threshold {
                NSLog("discarded (timeDifference: \(timeDifference) - threshold: \(threshold)")
                if !rateLimitInfo.scheduled {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * Int64(threshold)), dispatch_get_main_queue(), {
                        self.debounce2(name, threshold: threshold, atBegin: atBegin, closure: closure)
                    })
                }
            } else {
                //NSLog("OKb")
                self.setRateLimitInfoForKey(RateLimitInfo(lastExecutionDate: now, scheduled: false), forKey: name)
                closure()
            }
        } else {
            //NSLog("OKc")
            self.setRateLimitInfoForKey(RateLimitInfo(lastExecutionDate: now, scheduled: false), forKey: name)
            closure()
        }
    }

    public static func resetRateLimitForKey(key: String)
    {
        dispatch_sync(debounceQueue) {
            self.rateLimitDictionary[key] = nil
        }
    }

    private static func rateLimitInfoForKey(key: String) -> RateLimitInfo?
    {
        var rateLimitInfo: RateLimitInfo?
        dispatch_sync(debounceQueue) {
            rateLimitInfo = self.rateLimitDictionary[key]
        }
        return rateLimitInfo
    }

    private static func setRateLimitInfoForKey(rateLimitInfo: RateLimitInfo, forKey key: String)
    {
        dispatch_sync(debounceQueue) {
            self.rateLimitDictionary[key] = rateLimitInfo
        }
    }
}
