//
//  StatsPanelView.swift
//  Dependn
//
//  Created by David Miotti on 08/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import SwiftHelpers
import CocoaLumberjack

final class ValueLabelView: SHCommonInitView {

    private(set) var valueLbl: UILabel!
    private(set) var fractionLbl: UILabel!
    private var titleLbl: UILabel!
    
    var title: String? {
        set {
            updateTitle(newValue)
        }
        get {
            return titleLbl.attributedText?.string
        }
    }
    
    func updateTitle(newTitle: String?) {
        if let newTitle = newTitle?.uppercaseString {
            let attr = NSMutableAttributedString(string: newTitle)
            let range = NSMakeRange(0, attr.length)
            attr.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(10, weight: UIFontWeightSemibold), range: range)
            attr.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor().colorWithAlphaComponent(0.6), range: range)
            attr.addAttribute(NSKernAttributeName, value: 0.83, range: range)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .Center
            attr.addAttribute(NSParagraphStyleAttributeName, value: paragraph, range: range)
            titleLbl.attributedText = attr
        } else {
            titleLbl.attributedText = nil
        }
    }

    override func commonInit() {
        super.commonInit()

        valueLbl = UILabel()
        valueLbl.textColor = UIColor.whiteColor()
        valueLbl.font = UIFont.systemFontOfSize(46, weight: UIFontWeightLight)
        valueLbl.textAlignment = .Center
        valueLbl.numberOfLines = 1
        valueLbl.adjustsFontSizeToFitWidth = true
        valueLbl.text = " "
        addSubview(valueLbl)

        titleLbl = UILabel()
        titleLbl.adjustsFontSizeToFitWidth = true
        addSubview(titleLbl)
        
        fractionLbl = UILabel()
        fractionLbl.textColor = UIColor.whiteColor()
        fractionLbl.font = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
        addSubview(fractionLbl)

        configureLayoutConstraints()
    }

    private func configureLayoutConstraints() {
        valueLbl.snp_makeConstraints {
            $0.centerY.equalTo(self).offset(-5)
            $0.centerX.equalTo(self)
            $0.left.greaterThanOrEqualTo(self)
            $0.right.lessThanOrEqualTo(self)
        }
        titleLbl.snp_makeConstraints {
            $0.top.equalTo(valueLbl.snp_bottom)
            $0.centerX.equalTo(self)
            $0.left.greaterThanOrEqualTo(self)
            $0.right.lessThanOrEqualTo(self)
        }
        fractionLbl.snp_makeConstraints {
            $0.right.equalTo(valueLbl)
            $0.top.equalTo(valueLbl)
        }
    }

}

private let kStatsPanelDateFormatter = NSDateFormatter(dateFormat: "MMMM")

final class StatsPanelView: SHCommonInitView {
    
    private(set) var addiction: Addiction?
    private(set) var color: UIColor?
    
    private let operationQueue = NSOperationQueue()
    
    private lazy var numberFormatter: NSNumberFormatter = {
        let fmt = NSNumberFormatter()
        fmt.numberStyle = .DecimalStyle
        fmt.maximumFractionDigits = 1
        return fmt
    }()
    
    private var nameLbl: UILabel!
    private var periodLbl: UILabel!
    
    private var stackView: UIStackView!
    private var todayValue: ValueLabelView!
    private var weekValue: ValueLabelView!
    private var intervalValue: ValueLabelView!
    
    private var refreshTimer: NSTimer?
    
    override func commonInit() {
        super.commonInit()
        
        UIFontTextStyleHeadline
        
        nameLbl = UILabel()
        nameLbl.font = UIFont.systemFontOfSize(12, weight: UIFontWeightSemibold)
        nameLbl.textColor = UIColor.whiteColor()
        addSubview(nameLbl)
        
        periodLbl = UILabel()
        periodLbl.font = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
        periodLbl.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
        addSubview(periodLbl)
        
        todayValue = ValueLabelView()
        todayValue.title = L("statspanel.today")

        weekValue = ValueLabelView()
        weekValue.title = L("statspanel.this_week")

        intervalValue = ValueLabelView()
        intervalValue.title = L("statspanel.interval")
        
        stackView = UIStackView(arrangedSubviews: [todayValue, weekValue, intervalValue])
        stackView.axis = .Horizontal
        stackView.distribution = .FillEqually
        stackView.spacing = 0
        stackView.backgroundColor = UIColor.brownColor()
        addSubview(stackView)
        
        configureLayoutConstraints()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StatsPanelView.applicationDidEnterBackground(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StatsPanelView.applicationWillEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        startTimer()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        stopTimer()
    }
    
    private func configureLayoutConstraints() {
        nameLbl.snp_makeConstraints {
            $0.top.equalTo(self).offset(14)
            $0.left.equalTo(self).offset(16)
        }
        periodLbl.snp_makeConstraints {
            $0.top.equalTo(self).offset(14)
            $0.right.equalTo(self).offset(-16)
        }
        stackView.snp_makeConstraints {
            $0.edges.equalTo(self)
        }
    }
    
    func updateWithAddiction(addiction: Addiction) {
        self.addiction = addiction
        
        nameLbl.text = addiction.name.uppercaseString
        periodLbl.text = kStatsPanelDateFormatter.stringFromDate(NSDate()).uppercaseString
        
        performOperations()
    }
    
    func performOperations() {
        guard let addiction = addiction else {
            return
        }
        
        operationQueue.cancelAllOperations()
        
        let statsOp = ShortStatsOperation(addictions: [addiction])
        statsOp.completionBlock = {
            dispatch_async(dispatch_get_main_queue()) {
                if let results = statsOp.results.first {
                    // Today count
                    if let todayCount = results.todayCount {
                        self.todayValue.valueLbl.text = self.numberFormatter.stringFromNumber(todayCount)
                    } else {
                        self.todayValue.valueLbl.text = " "
                    }
                    
                    // This week
                    if let thisWeek = results.thisWeekCount {
                        self.weekValue.valueLbl.text = self.numberFormatter.stringFromNumber(thisWeek)
                    } else {
                        self.weekValue.valueLbl.text = " "
                    }
                    
                    // Since last
                    if let interval = results.sinceLast {
                        self.intervalValue.valueLbl.attributedText = self.attributedStringFromTimeInterval(interval)
                        self.intervalValue.fractionLbl.text = self.fractionFromInterval(interval)
                    } else {
                        self.intervalValue.valueLbl.attributedText = nil
                        self.intervalValue.valueLbl.text = "0h"
                        self.intervalValue.fractionLbl.text = nil
                    }
                }
            }
        }
        
        operationQueue.addOperation(statsOp)
    }
    
    // MARK: - Handleling timer
    
    private func stopTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func startTimer() {
        stopTimer()
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(
            15,
            target: self,
            selector: #selector(StatsPanelView.performOperations),
            userInfo: nil, repeats: true)
    }
    
    func applicationDidEnterBackground(notification: NSNotification) {
        stopTimer()
    }
    
    func applicationWillEnterForeground(notification: NSNotification) {
        startTimer()
    }
    
    // MARK: - Private Helpers
    
    private func hoursMinutesSecondsFromInterval(interval: NSTimeInterval) -> (hours: Int, minutes: Int, seconds: Int) {
        let ti = Int(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        return (hours, minutes, seconds)
    }
    
    private func attributedStringFromTimeInterval(interval: NSTimeInterval) -> NSAttributedString {
        let time = hoursMinutesSecondsFromInterval(interval)
        
        let valueText: String
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
        
        let attr = NSMutableAttributedString(string: "\(valueText)\(unitText)")
        let range = NSMakeRange(0, attr.length)
        attr.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(46, weight: UIFontWeightLight), range: range)
        attr.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: range)
        let unitRange = attr.string.rangeString(unitText)
        attr.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(20, weight: UIFontWeightLight), range: unitRange)
        return attr
    }
    
    private func fractionFromInterval(interval: NSTimeInterval) -> String? {
        let time = hoursMinutesSecondsFromInterval(interval)
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