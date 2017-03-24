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
    fileprivate(set) var textLbl: UILabel!
    
    var color: UIColor = UIColor.appBlackColor() {
        didSet {
            textLbl.textColor = color
            backgroundColor = color.withAlphaComponent(0.1)
            layer.borderColor = color.withAlphaComponent(0.1).cgColor
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
        textLbl.textAlignment = .center
        textLbl.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
        addSubview(textLbl)
        textLbl.snp.makeConstraints {
            $0.edges.equalTo(self)
        }
        color = UIColor.appBlackColor()
    }
}
