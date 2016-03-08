//
//  StatsCell.swift
//  Dependn
//
//  Created by David Miotti on 24/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class StatsCell: SHCommonInitTableViewCell {
    
    static let reuseIdentifier = "StatsCell"
    
    var titleLbl: UILabel!
    var valueLbl: UILabel!
    
    override func commonInit() {
        super.commonInit()
        
        titleLbl = UILabel()
        titleLbl.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        titleLbl.adjustsFontSizeToFitWidth = true
        titleLbl.textColor = UIColor.appBlackColor()
        contentView.addSubview(titleLbl)
        
        valueLbl = UILabel()
        valueLbl.textAlignment = .Right
        valueLbl.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        valueLbl.textColor = UIColor.appBlackColor()
        contentView.addSubview(valueLbl)
        
        configureLayoutConstraints()
    }
    
    private func configureLayoutConstraints() {
        titleLbl.snp_makeConstraints {
            $0.left.equalTo(contentView).offset(20)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
            $0.right.equalTo(valueLbl.snp_left)
        }
        
        valueLbl.snp_makeConstraints {
            $0.centerY.equalTo(titleLbl)
            $0.right.equalTo(contentView).offset(-20)
        }
        
        titleLbl.setContentCompressionResistancePriority(
            UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        
        valueLbl.setContentCompressionResistancePriority(
            UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
    }
    
}
