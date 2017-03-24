//
//  TableHeaderView.swift
//  Dependn
//
//  Created by David Miotti on 10/05/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class TableHeaderView: SHCommonInitView {
    
    var title: String? {
        didSet {
            titleLbl.text = title
        }
    }
    
    fileprivate let titleLbl = UILabel()
    
    override func commonInit() {
        super.commonInit()
        
        backgroundColor = "F5FAFF".UIColor
        alpha = 0.93
        
        titleLbl.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium)
        titleLbl.textColor = "7D9BB8".UIColor
        addSubview(titleLbl)
        
        titleLbl.snp.makeConstraints {
            $0.left.equalTo(self).offset(15)
            $0.bottom.equalTo(self).offset(-6)
        }
        
        let sepTop = UIView()
        sepTop.backgroundColor = UIColor.appSeparatorColor()
        addSubview(sepTop)
        sepTop.snp.makeConstraints {
            $0.top.equalTo(self)
            $0.left.equalTo(self)
            $0.right.equalTo(self)
            $0.height.equalTo(0.5)
        }
        
        let sepBtm = UIView()
        sepBtm.backgroundColor = UIColor.appSeparatorColor()
        addSubview(sepBtm)
        sepBtm.snp.makeConstraints {
            $0.bottom.equalTo(self)
            $0.left.equalTo(self)
            $0.right.equalTo(self)
            $0.height.equalTo(0.5)
        }
    }

}
