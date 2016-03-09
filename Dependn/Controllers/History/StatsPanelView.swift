//
//  StatsPanelView.swift
//  Dependn
//
//  Created by David Miotti on 08/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import SwiftHelpers

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
        valueLbl.text = "2h"
        addSubview(valueLbl)

        titleLbl = UILabel()
        addSubview(titleLbl)

        configureLayoutConstraints()
    }

    private func configureLayoutConstraints() {
        valueLbl.snp_makeConstraints {
            $0.centerY.equalTo(self).offset(-5)
            $0.centerX.equalTo(self)
        }
        titleLbl.snp_makeConstraints {
            $0.top.equalTo(valueLbl.snp_bottom)
            $0.centerX.equalTo(self)
        }
    }

}

private let kStatsPanelDateFormatter = NSDateFormatter(dateFormat: "MMMM")

final class StatsPanelView: SHCommonInitView {
    
    private(set) var addiction: Addiction?
    private(set) var color: UIColor?
    
    private var nameLbl: UILabel!
    private var periodLbl: UILabel!
    
    private var stackView: UIStackView!
    private var todayValue: ValueLabelView!
    private var weekValue: ValueLabelView!
    private var intervalValue: ValueLabelView!
    
    override func commonInit() {
        super.commonInit()
        
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
        stackView.distribution = .FillProportionally
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
    }
    
}