//
//  TimeUtils.swift
//  Dependn
//
//  Created by David Miotti on 05/05/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit

func stringFromTimeInterval(interval: NSTimeInterval) -> String {
    let time = hoursMinutesSecondsFromInterval(interval)
    
    var str = ""
    if time.hours > 0 {
        str += "\(time.hours)h"
    } else if time.minutes > 0 {
        str += "\(time.minutes)m"
    } else if time.seconds < 60 {
        str += NSLocalizedString("less.than_minute", comment: "")
    } else {
        str += "\(time.seconds)s"
    }
    
    if let fraction = fractionFromInterval(interval) {
        str += fraction
    }
    
    return str
}

private func fractionFromInterval(interval: NSTimeInterval) -> String? {
    let time = hoursMinutesSecondsFromInterval(interval)
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

private func hoursMinutesSecondsFromInterval(interval: NSTimeInterval) -> (hours: Int, minutes: Int, seconds: Int) {
    let ti = Int(interval)
    let seconds = ti % 60
    let minutes = (ti / 60) % 60
    let hours = (ti / 3600)
    return (hours, minutes, seconds)
}
