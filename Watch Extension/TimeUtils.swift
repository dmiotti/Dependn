//
//  TimeUtils.swift
//  Dependn
//
//  Created by David Miotti on 05/05/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit

func stringFromTimeInterval(interval: TimeInterval) -> String {
    let time = hoursMinutesSecondsFromInterval(interval: interval)
    
    var str = ""
    if time.hours > 0 {
        str += "\(time.hours)h"
    } else if time.minutes > 0 {
        str += "\(time.minutes)m"
    } else {
        str += "\(time.seconds)s"
    }
    
    if let fraction = fractionFromInterval(interval: interval) {
        str += fraction
    }
    
    return str
}

private func fractionFromInterval(interval: TimeInterval) -> String? {
    let time = hoursMinutesSecondsFromInterval(interval: interval)
    if time.hours <= 0 || time.minutes < 15 {
        return nil
    }
    
    if time.minutes < 30 {
        return String(numerator: 1, denominator: 4)
    } else if time.minutes < 45 {
        return String(numerator: 1, denominator: 2)
    }
    
    return String(numerator: 3, denominator: 4)
}

private func hoursMinutesSecondsFromInterval(interval: TimeInterval) -> (hours: Int, minutes: Int, seconds: Int) {
    let ti = Int(interval)
    let seconds = ti % 60
    let minutes = (ti / 60) % 60
    let hours = (ti / 3600)
    return (hours, minutes, seconds)
}

public extension String {
    
    public init?(numerator: Int, denominator: Int) {
        var result = ""
        
        // build numerator
        let one = "\(numerator)"
        for char in one.characters {
            if let num = Int(String(char)), let val = superscriptFromInt(num: num) {
                result.append(val)
            }
        }
        
        // build denominator
        let two = "\(denominator)"
        result.append("/")
        for char in two.characters {
            if let num = Int(String(char)), let val = subscriptFromInt(num: num) {
                result.append(val)
            }
        }
        
        self.init(result)
    }
}

private func superscriptFromInt(num: Int) -> String? {
    let superscriptDigits: [Int: String] = [
        0: "\u{2070}",
        1: "\u{00B9}",
        2: "\u{00B2}",
        3: "\u{00B3}",
        4: "\u{2074}",
        5: "\u{2075}",
        6: "\u{2076}",
        7: "\u{2077}",
        8: "\u{2078}",
        9: "\u{2079}" ]
    return superscriptDigits[num]
}

private func subscriptFromInt(num: Int) -> String? {
    let subscriptDigits: [Int: String] = [
        0: "\u{2080}",
        1: "\u{2081}",
        2: "\u{2082}",
        3: "\u{2083}",
        4: "\u{2084}",
        5: "\u{2085}",
        6: "\u{2086}",
        7: "\u{2087}",
        8: "\u{2088}",
        9: "\u{2089}" ]
    return subscriptDigits[num]
}
