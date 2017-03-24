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

    fileprivate(set) var valueLbl: UILabel!
    fileprivate(set) var fractionLbl: UILabel!
    fileprivate var titleLbl: UILabel!
    
    var title: String? {
        set {
            updateTitle(newValue)
        }
        get {
            return titleLbl.attributedText?.string
        }
    }
    
    func updateTitle(_ newTitle: String?) {
        if let newTitle = newTitle?.uppercased() {
            let attr = NSMutableAttributedString(string: newTitle)
            let range = NSMakeRange(0, attr.length)
            attr.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 10, weight: UIFontWeightSemibold), range: range)
            attr.addAttribute(NSForegroundColorAttributeName, value: UIColor.white.withAlphaComponent(0.6), range: range)
            attr.addAttribute(NSKernAttributeName, value: 0.83, range: range)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            attr.addAttribute(NSParagraphStyleAttributeName, value: paragraph, range: range)
            titleLbl.attributedText = attr
        } else {
            titleLbl.attributedText = nil
        }
    }

    override func commonInit() {
        super.commonInit()

        valueLbl = UILabel()
        valueLbl.textColor = UIColor.white
        valueLbl.font = UIFont.systemFont(ofSize: 46, weight: UIFontWeightLight)
        valueLbl.textAlignment = .center
        valueLbl.numberOfLines = 1
        valueLbl.adjustsFontSizeToFitWidth = true
        valueLbl.text = " "
        addSubview(valueLbl)

        titleLbl = UILabel()
        titleLbl.adjustsFontSizeToFitWidth = true
        addSubview(titleLbl)
        
        fractionLbl = UILabel()
        fractionLbl.textColor = UIColor.white
        fractionLbl.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium)
        addSubview(fractionLbl)

        configureLayoutConstraints()
    }

    fileprivate func configureLayoutConstraints() {
        valueLbl.snp.makeConstraints {
            $0.centerY.equalTo(self).offset(-5)
            $0.centerX.equalTo(self)
            $0.left.greaterThanOrEqualTo(self)
            $0.right.lessThanOrEqualTo(self)
        }
        titleLbl.snp.makeConstraints {
            $0.top.equalTo(valueLbl.snp.bottom)
            $0.centerX.equalTo(self)
            $0.left.greaterThanOrEqualTo(self)
            $0.right.lessThanOrEqualTo(self)
        }
        fractionLbl.snp.makeConstraints {
            $0.right.equalTo(valueLbl)
            $0.top.equalTo(valueLbl)
        }
    }

}

private let kStatsPanelDateFormatter = DateFormatter(dateFormat: "MMMM")

final class StatsPanelView: SHCommonInitView {
    
    fileprivate(set) var addiction: Addiction?
    fileprivate(set) var color: UIColor?
    
    fileprivate let operationQueue = OperationQueue()
    
    fileprivate lazy var numberFormatter: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 1
        return fmt
    }()
    
    fileprivate var nameLbl: UILabel!
    fileprivate var periodLbl: UILabel!
    
    fileprivate var stackView: UIStackView!
    fileprivate var todayValue: ValueLabelView!
    fileprivate var weekValue: ValueLabelView!
    fileprivate var intervalValue: ValueLabelView!
    
    fileprivate var refreshTimer: Timer?
    
    override func commonInit() {
        super.commonInit()
                
        nameLbl = UILabel()
        nameLbl.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightSemibold)
        nameLbl.textColor = UIColor.white
        addSubview(nameLbl)
        
        periodLbl = UILabel()
        periodLbl.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)
        periodLbl.textColor = UIColor.white.withAlphaComponent(0.6)
        addSubview(periodLbl)
        
        todayValue = ValueLabelView()
        todayValue.title = L("statspanel.today")

        weekValue = ValueLabelView()
        weekValue.title = L("statspanel.this_week")

        intervalValue = ValueLabelView()
        intervalValue.title = L("statspanel.interval")
        
        stackView = UIStackView(arrangedSubviews: [todayValue, weekValue, intervalValue])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.backgroundColor = UIColor.brown
        addSubview(stackView)
        
        configureLayoutConstraints()
        
        NotificationCenter.default.addObserver(self, selector: #selector(StatsPanelView.applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StatsPanelView.applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        startTimer()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopTimer()
    }
    
    fileprivate func configureLayoutConstraints() {
        nameLbl.snp.makeConstraints {
            $0.top.equalTo(self).offset(14)
            $0.left.equalTo(self).offset(16)
        }
        periodLbl.snp.makeConstraints {
            $0.top.equalTo(self).offset(14)
            $0.right.equalTo(self).offset(-16)
        }
        stackView.snp.makeConstraints {
            $0.edges.equalTo(self)
        }
    }
    
    func updateWithAddiction(_ addiction: Addiction) {
        self.addiction = addiction
        
        nameLbl.text = addiction.name.uppercased()
        periodLbl.text = kStatsPanelDateFormatter.string(from: Date()).uppercased()
        
        performOperations()
    }
    
    func performOperations() {
        guard let addiction = addiction else {
            return
        }
        
        operationQueue.cancelAllOperations()
        
        let statsOp = ShortStatsOperation(addictions: [addiction])
        statsOp.completionBlock = {
            DispatchQueue.main.async {
                if let results = statsOp.results.first {
                    // Today count
                    if let todayCount = results.todayCount {
                        self.todayValue.valueLbl.text = self.numberFormatter.string(from: NSNumber(value: todayCount))
                    } else {
                        self.todayValue.valueLbl.text = " "
                    }
                    
                    // This week
                    if let thisWeek = results.thisWeekCount {
                        self.weekValue.valueLbl.text = self.numberFormatter.string(from: NSNumber(value: thisWeek))
                    } else {
                        self.weekValue.valueLbl.text = " "
                    }
                    
                    // Since last
                    if let interval = results.sinceLast {
                        self.intervalValue.valueLbl.attributedText = self.attributedString(from: interval)
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
    
    fileprivate func stopTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    fileprivate func startTimer() {
        stopTimer()
        refreshTimer = Timer.scheduledTimer(
            timeInterval: 15,
            target: self,
            selector: #selector(StatsPanelView.performOperations),
            userInfo: nil, repeats: true)
    }
    
    func applicationDidEnterBackground(_ notification: Notification) {
        stopTimer()
    }
    
    func applicationWillEnterForeground(_ notification: Notification) {
        startTimer()
    }
    
    // MARK: - Private Helpers
    
    fileprivate func hoursMinutesSecondsFromInterval(_ interval: TimeInterval) -> (hours: Int, minutes: Int, seconds: Int) {
        let ti = Int(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        return (hours, minutes, seconds)
    }
    
    fileprivate func attributedString(from interval: TimeInterval) -> NSAttributedString {
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
        attr.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 46, weight: UIFontWeightLight), range: range)
        attr.addAttribute(NSForegroundColorAttributeName, value: UIColor.white, range: range)
        let unitRange = attr.string.rangeString(unitText)
        attr.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 20, weight: UIFontWeightLight), range: unitRange)
        return attr
    }
    
    fileprivate func fractionFromInterval(_ interval: TimeInterval) -> String? {
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
    
    fileprivate func fraction(_ numerator: Int, denominator: Int) -> String {
        var result = ""
        
        // build numerator
        let one = "\(numerator)"
        for char in one.characters {
            if let num = Int(String(char)), let val = superscriptFromInt(num) {
                result.append(val)
            }
        }
        
        // build denominator
        let two = "\(denominator)"
        result.append("/")
        for char in two.characters {
            if let num = Int(String(char)), let val = subscriptFromInt(num) {
                result.append(val)
            }
        }
        
        return result
    }
    
    fileprivate func superscriptFromInt(_ num: Int) -> String? {
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
    
    fileprivate func subscriptFromInt(_ num: Int) -> String? {
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
