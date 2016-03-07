//
//  NewDateTableViewCell.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class NewDateTableViewCell: SHCommonInitTableViewCell {
    
    static let reuseIdentifier = "NewDateTableViewCell"
    
    private var dateLbl: UILabel!
    private var calImgView: UIImageView!
    var chosenDateLbl: UILabel!

    override func commonInit() {
        super.commonInit()
        
        separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0)
        
        accessoryType = .DisclosureIndicator
        
        calImgView = UIImageView(image: UIImage(named: "cal_icon"))
        calImgView.contentMode = .Center
        contentView.addSubview(calImgView)
        
        dateLbl = UILabel()
        dateLbl.text = L("new_record.date")
        dateLbl.textColor = "A2B8CC".UIColor
        dateLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        contentView.addSubview(dateLbl)
        
        chosenDateLbl = UILabel()
        chosenDateLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        chosenDateLbl.textColor = UIColor.appBlackColor()
        chosenDateLbl.textAlignment = .Right
        chosenDateLbl.adjustsFontSizeToFitWidth = true
        contentView.addSubview(chosenDateLbl)
        
        configureLayoutConstraints()
    }
    
    private func configureLayoutConstraints() {
        calImgView.snp_makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.left.equalTo(contentView).offset(20)
            $0.width.height.equalTo(30)
        }
        dateLbl.snp_makeConstraints {
            $0.left.equalTo(calImgView.snp_right).offset(14)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
        }
        chosenDateLbl.snp_makeConstraints {
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
            $0.right.equalTo(contentView)
            $0.left.greaterThanOrEqualTo(dateLbl.snp_right).offset(10)
        }
    }

}
