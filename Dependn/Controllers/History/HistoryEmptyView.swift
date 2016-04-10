//
//  HistoryEmptyView.swift
//  Dependn
//
//  Created by David Miotti on 01/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class HistoryEmptyView: SHCommonInitView {
    
    private var imageView: UIImageView!
    private var textLbl: UILabel!
    
    override func commonInit() {
        super.commonInit()
        
        backgroundColor = UIColor.lightBackgroundColor()
        
        imageView = UIImageView(image: UIImage(named: "tour_specialist"))
        imageView.contentMode = .ScaleAspectFit
        addSubview(imageView)
        
        textLbl = UILabel()
        textLbl.textColor = UIColor.appBlackColor().colorWithAlphaComponent(0.5)
        textLbl.text = L("history.help")
        textLbl.numberOfLines = 0
        textLbl.textAlignment = .Center
        addSubview(textLbl)
        
        imageView.snp_makeConstraints {
            if DeviceType.IS_IPHONE_4_OR_LESS || DeviceType.IS_IPHONE_5 {
                $0.top.greaterThanOrEqualTo(self).offset(20).priorityLow()
            } else {
                $0.top.greaterThanOrEqualTo(self).offset(50)
            }
            
            $0.left.equalTo(self)
            $0.right.equalTo(self)
            $0.bottom.lessThanOrEqualTo(textLbl.snp_top).offset(-10)
        }
        
        textLbl.snp_makeConstraints {
            $0.left.equalTo(self).offset(50)
            $0.right.equalTo(self).offset(-50)
            if DeviceType.IS_IPHONE_4_OR_LESS {
                $0.bottom.equalTo(self).offset(-100)
            } else {
                $0.bottom.equalTo(self).offset(-130)
            }
        }
    }

}
