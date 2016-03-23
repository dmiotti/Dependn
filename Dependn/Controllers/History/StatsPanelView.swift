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
        
        operationQueue.cancelAllOperations()
        
        operationQueue.suspended = true
        
        let now = NSDate().endOfDay
        
        let sinceLastOp = TimeSinceLastRecord(addiction: addiction)
        sinceLastOp.completionBlock = {
            dispatch_async(dispatch_get_main_queue()) {
                if let interval = sinceLastOp.interval {
                    self.intervalValue.valueLbl.attributedText = self.attributedStringFromTimeInterval(interval)
                } else {
                    self.intervalValue.valueLbl.attributedText = nil
                    self.intervalValue.valueLbl.text = "0h"
                }
            }
        }
        
        let weekRange = TimeRange(start: now.beginningOfWeek, end: now)
        let weekCountOp = CountOperation(addiction: addiction, range: weekRange)
        weekCountOp.completionBlock = {
            dispatch_async(dispatch_get_main_queue()) {
                if let count = weekCountOp.total {
                    self.weekValue.valueLbl.text = self.numberFormatter.stringFromNumber(count);
                } else {
                    self.weekValue.valueLbl.text = " ";
                }
            }
        }
        
        let todayRange = TimeRange(start: now.beginningOfDay, end: now)
        let todayCountOp = CountOperation(addiction: addiction, range: todayRange)
        todayCountOp.completionBlock = {
            dispatch_async(dispatch_get_main_queue()) {
                if let count = todayCountOp.total {
                    self.todayValue.valueLbl.text = self.numberFormatter.stringFromNumber(count);
                } else {
                    self.todayValue.valueLbl.text = " ";
                }
            }
        }
        
        operationQueue.addOperation(sinceLastOp)
        operationQueue.addOperation(weekCountOp)
        operationQueue.addOperation(todayCountOp)
        
        operationQueue.suspended = false
    }
    
    // MARK: - Private Helpers
    
    private func attributedStringFromTimeInterval(interval: NSTimeInterval) -> NSAttributedString {
        let ti = Int(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        let valueText: String
        let unitText: String
        if hours > 0 {
            valueText = "\(hours)"
            unitText = "h"
        } else if minutes > 0 {
            valueText = "\(minutes)"
            unitText = "m"
        } else {
            valueText = "\(seconds)"
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
    
}