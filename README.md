aa
asdas# DORateLimit

[![CI Status](http://img.shields.io/travis/danydev/DORateLimit.svg?style=flat)](https://travis-ci.org/danydev/RateLimit)
[![Version](https://img.shields.io/cocoapods/v/RateLimit.svg?style=flat)](http://cocoapods.org/pods/RateLimit)
[![License](https://img.shields.io/cocoapods/l/RateLimit.svg?style=flat)](http://cocoapods.org/pods/RateLimit)
[![Platform](https://img.shields.io/cocoapods/p/RateLimit.svg?style=flat)](http://cocoapods.org/pods/RateLimit)

DORateLimit allows you to rate limit your function calls both by using throttling and debouncing.
A good explanation about the differences between debouncing and throttling can be found [here](http://benalman.com/projects/jquery-throttle-debounce-plugin/).

## Usage

``` swift
RateLimit.throttle("throttleFunctionKey", threshold: 1.0) {
    print("triggering throttled closure")
}
    
RateLimit.debounce("debounceFunctionKey", threshold: 1.0) {
    print("triggering debounced closure")
}
```

## Installation

RateLimit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "DORateLimit"
```

## License

RateLimit is available under the MIT license. See the LICENSE file for more info.
