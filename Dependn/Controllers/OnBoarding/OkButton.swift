//
//  OkButton.swift
//  Dependn
//
//  Created by David Miotti on 01/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class OkButton: SHCommonInitView {

    private var circleView: UIView!
    private(set) var textLbl: UILabel!
    private(set) var button: UIButton!
    
    override func commonInit() {
        super.commonInit()
        
        circleView = UIView()
        circleView.backgroundColor = UIColor.appBlueColor()
        circleView.layer.shadowColor = "31627D".UIColor.CGColor
        circleView.layer.shadowOffset = CGSize(width: 0, height: 3)
        circleView.layer.shadowOpacity = 0.20
        circleView.layer.shadowRadius = 9
        addSubview(circleView)
        
        textLbl = UILabel()
        textLbl.textColor = UIColor.whiteColor()
        textLbl.textAlignment = .Center
        textLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightBold)
        textLbl.adjustsFontSizeToFitWidth = true
        addSubview(textLbl)
        
        button = UIButton(type: .System)
        addSubview(button)
        
        configureLayoutConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        circleView.layer.cornerRadius = circleView.frame.size.height / 2
    }
    
    private func configureLayoutConstraints() {
        circleView.snp_makeConstraints {
            $0.edges.equalTo(self)
        }
        
        textLbl.snp_makeConstraints {
            $0.edges.equalTo(self)
        }
        
        button.snp_makeConstraints {
            $0.edges.equalTo(self)
        }
    }

}
