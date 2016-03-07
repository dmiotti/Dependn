//
//  RecordCircleTypeView.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
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
