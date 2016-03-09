//
//  HistoryTableViewCell.swift
//  Dependn
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class HistoryTableViewCell: SHCommonInitTableViewCell {
    
    static let reuseIdentifier = "HistoryTableViewCell"
    
    private(set) var circleTypeView: RecordCircleTypeView!
    private(set) var dateLbl: UILabel!
    private(set) var intensityCircle: IntensityGradientView!
    
    override func commonInit() {
        super.commonInit()
        
        accessoryType = .DisclosureIndicator
        
        circleTypeView = RecordCircleTypeView()
        contentView.addSubview(circleTypeView)
        
        dateLbl = UILabel()
        dateLbl.numberOfLines = 0
        contentView.addSubview(dateLbl)
        
        intensityCircle = IntensityGradientView()
        contentView.addSubview(intensityCircle)
        
        configureLayoutConstraints()
    }
    
    private func configureLayoutConstraints() {
        circleTypeView.snp_makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.left.equalTo(contentView).offset(20)
            $0.width.height.equalTo(30)
        }
        
        intensityCircle.snp_makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.right.equalTo(contentView)
            $0.width.height.equalTo(28)
        }
        
        dateLbl.snp_makeConstraints {
            $0.left.equalTo(circleTypeView.snp_right).offset(14)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
            $0.right.equalTo(intensityCircle.snp_left).offset(-10)
        }
    }

}
