//
//  HistoryTableViewCell.swift
//  Dependn
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class RecordCircleTypeView: SHCommonInitView {
    private(set) var textLbl: UILabel!
    
    var color: UIColor = UIColor.appBlackColor() {
        didSet {
            textLbl.textColor = color
            backgroundColor = color.colorWithAlphaComponent(0.1)
            layer.borderColor = color.colorWithAlphaComponent(0.1).CGColor
            setNeedsDisplay()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.size.height / 2.0
    }
    
    override func commonInit() {
        super.commonInit()
        layer.borderWidth = 1
        textLbl = UILabel()
        textLbl.textAlignment = .Center
        textLbl.font = UIFont.systemFontOfSize(14, weight: UIFontWeightMedium)
        addSubview(textLbl)
        textLbl.snp_makeConstraints {
            $0.edges.equalTo(self)
        }
        color = UIColor.appBlackColor()
    }
}

final class HistoryTableViewCell: SHCommonInitTableViewCell {
    
    static let reuseIdentifier = "HistoryTableViewCell"
    
    private(set) var circleTypeView: RecordCircleTypeView!
    private(set) var dateLbl: UILabel!
    private(set) var intensityLbl: UILabel!
    
    override func commonInit() {
        super.commonInit()
        
        accessoryType = .DisclosureIndicator
        
        circleTypeView = RecordCircleTypeView()
        contentView.addSubview(circleTypeView)
        
        dateLbl = UILabel()
        dateLbl.numberOfLines = 0
        contentView.addSubview(dateLbl)
        
        intensityLbl = UILabel()
        intensityLbl.textAlignment = .Right
        contentView.addSubview(intensityLbl)
        
        configureLayoutConstraints()
    }
    
    private func configureLayoutConstraints() {
        circleTypeView.snp_makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.left.equalTo(contentView).offset(20)
            $0.width.height.equalTo(30)
        }
        
        intensityLbl.snp_makeConstraints {
            $0.right.equalTo(contentView).offset(-20)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
        }
        
        dateLbl.snp_makeConstraints {
            $0.left.equalTo(circleTypeView.snp_right).offset(10)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
            $0.right.equalTo(intensityLbl.snp_left).offset(-10)
        }
    }

}
