//
//  AddictionTableViewCell.swift
//  Dependn
//
//  Created by David Miotti on 05/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class AddictionTableViewCell: SHCommonInitTableViewCell {
    
    static var reuseIdentifier = "AddictionTableViewCell"
    
    var addiction: Addiction? {
        didSet {
            configureWithAddiction()
        }
    }
    
    var choosen: Bool = false {
        didSet {
            accessoryType = choosen ? .Checkmark : .None
        }
    }
    
    private var circleView: RecordCircleTypeView!
    private var textLbl: UILabel!
    
    override func commonInit() {
        super.commonInit()
        
        circleView = RecordCircleTypeView()
        contentView.addSubview(circleView)
        
        textLbl = UILabel()
        textLbl.textColor = UIColor.appBlackColor()
        textLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        contentView.addSubview(textLbl)
        
        configureLayoutConstraints()
    }
    
    private func configureLayoutConstraints() {
        circleView.snp_makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.left.equalTo(contentView).offset(20)
            $0.width.height.equalTo(30)
        }
        
        textLbl.snp_makeConstraints {
            $0.left.equalTo(circleView.snp_right).offset(10)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
            $0.right.equalTo(contentView).offset(-10)
        }
    }
    
    private func configureWithAddiction() {
        if let addiction = addiction {
            let name = addiction.name.capitalizedString
            textLbl.text = name
            circleView.color = addiction.color.UIColor
            if let first = addiction.name.capitalizedString.characters.first {
                circleView.textLbl.text = "\(first)"
            }
        } else {
            textLbl.text = nil
            circleView.textLbl.text = nil
        }
    }
    
}
