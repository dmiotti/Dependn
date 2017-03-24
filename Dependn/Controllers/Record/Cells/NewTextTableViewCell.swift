//
//  NewTextTableViewCell.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class NewTextTableViewCell: SHCommonInitTableViewCell {
    
    static let reuseIdentifier = "NewTextTableViewCell"
    
    fileprivate(set) var descLbl: UILabel!
    fileprivate(set) var contentLbl: UILabel!
    
    override func commonInit() {
        super.commonInit()
        
        accessoryType = .disclosureIndicator
        
        contentView.backgroundColor = UIColor.white
        
        descLbl = UILabel()
        descLbl.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        descLbl.textColor = UIColor.appLightTextColor()
        contentView.addSubview(descLbl)
        
        contentLbl = UILabel()
        contentLbl.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        contentLbl.textColor = UIColor.appBlackColor()
        contentView.addSubview(contentLbl)
        
        configureLayoutConstraints()
    }
    
    fileprivate func configureLayoutConstraints() {
        descLbl.snp.makeConstraints {
            $0.left.equalTo(contentView).offset(58)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
            $0.right.lessThanOrEqualTo(contentLbl.snp.left).offset(-15)
        }
        
        contentLbl.snp.makeConstraints {
            $0.right.equalTo(contentView)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
        }
    }

}
