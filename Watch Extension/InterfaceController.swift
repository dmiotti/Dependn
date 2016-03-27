//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by David Miotti on 13/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var statsTable: WKInterfaceTable!
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }
    
    private func loadTableData(dataSource: [Dictionary<String, AnyObject>]) {
        statsTable.setNumberOfRows(dataSource.count, withRowType: "StatsTableRowController")
        
        for (index, data) in dataSource.enumerate() {
            if let row = statsTable.rowControllerAtIndex(index) as? StatsTableRowController {
                if let name = data["name"] as? String {
                    row.addictionLbl.setText(name.capitalizedString)
                }
                if let today = data["today"] as? Int {
                    row.todayValueLbl.setText("\(today)")
                }
                if let thisweek = data["thisweek"] as? Int {
                    row.thisWeekValueLbl.setText("\(thisweek)")
                }
                if let sincelast = data["sincelast"] as? NSTimeInterval {
                    row.sinceLastValueLbl.setText(stringFromTimeInterval(sincelast))
                }
            }
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session?.sendMessage(["action": "stats"], replyHandler: { (response) in
                if let values = response["stats"] as? [Dictionary<String, AnyObject>] {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.loadTableData(values)
                    }
                }
                }, errorHandler: { (err) in
                    print(err)
            })
        }
        
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    // MARK: - Private Helpers
    
    private func hoursMinutesSecondsFromInterval(interval: NSTimeInterval) -> (hours: Int, minutes: Int, seconds: Int) {
        let ti = Int(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        return (hours, minutes, seconds)
    }
    
    private func stringFromTimeInterval(interval: NSTimeInterval) -> String {
        let time = hoursMinutesSecondsFromInterval(interval)
        
        var valueText: String
        let unitText: String
        if time.hours > 0 {
            valueText = "\(time.hours)"
            unitText = "h"
        } else if time.minutes > 0 {
            valueText = "\(time.minutes)"
            unitText = "m"
        } else {
            valueText = "\(time.seconds)"
            unitText = "s"
        }
        
        if let fraction = fractionFromInterval(interval) {
            valueText += "\(fraction)"
        }
        
        valueText += unitText
        
        return valueText
    }
    
    private func fractionFromInterval(interval: NSTimeInterval) -> String? {
        let time = self.hoursMinutesSecondsFromInterval(interval)
        if time.hours <= 0 || time.minutes < 15 {
            return nil
        }
        
        if time.minutes < 30 {
            return self.fraction(1, denominator: 4)
        } else if time.minutes < 45 {
            return self.fraction(1, denominator: 2)
        }
        
        return self.fraction(3, denominator: 4)
    }
    
    private func fraction(numerator: Int, denominator: Int) -> String {
        var result = ""
        
        // build numerator
        let one = "\(numerator)"
        for char in one.characters {
            if let num = Int(String(char)), val = superscriptFromInt(num) {
                result.appendContentsOf(val)
            }
        }
        
        // build denominator
        let two = "\(denominator)"
        result.appendContentsOf("/")
        for char in two.characters {
            if let num = Int(String(char)), val = subscriptFromInt(num) {
                result.appendContentsOf(val)
            }
        }
        
        return result
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
}

extension InterfaceController: WCSessionDelegate {
    
}
