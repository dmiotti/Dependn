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

    fileprivate var circleView: UIView!
    fileprivate(set) var textLbl: UILabel!
    fileprivate(set) var button: UIButton!
    
    override func commonInit() {
        super.commonInit()
        
        circleView = UIView()
        circleView.backgroundColor = UIColor.appBlueColor()
        circleView.layer.shadowColor = "31627D".UIColor.cgColor
        circleView.layer.shadowOffset = CGSize(width: 0, height: 3)
        circleView.layer.shadowOpacity = 0.20
        circleView.layer.shadowRadius = 9
        addSubview(circleView)
        
        textLbl = UILabel()
        textLbl.textColor = UIColor.white
        textLbl.textAlignment = .center
        textLbl.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightBold)
        textLbl.adjustsFontSizeToFitWidth = true
        addSubview(textLbl)
        
        button = UIButton(type: .system)
        addSubview(button)
        
        configureLayoutConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        circleView.layer.cornerRadius = circleView.frame.size.height / 2
    }
    
    fileprivate func configureLayoutConstraints() {
        circleView.snp.makeConstraints {
            $0.edges.equalTo(self)
        }
        
        textLbl.snp.makeConstraints {
            $0.edges.equalTo(self)
        }
        
        button.snp.makeConstraints {
            $0.edges.equalTo(self)
        }
    }

}
