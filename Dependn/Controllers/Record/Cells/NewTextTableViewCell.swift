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
    
    var feelingField: UITextField!
    
    override func commonInit() {
        super.commonInit()
        
        accessoryType = .DisclosureIndicator
        
        contentView.backgroundColor = UIColor.whiteColor()
        
        feelingField = UITextField()
        feelingField.userInteractionEnabled = false
        feelingField.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        feelingField.textColor = UIColor.appBlackColor()
        contentView.addSubview(feelingField)
        
        configureLayoutConstraints()
    }
    
    private func configureLayoutConstraints() {
        feelingField.snp_makeConstraints {
            $0.left.equalTo(contentView).offset(58)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
            $0.right.equalTo(contentView).offset(-20)
        }
    }

}
