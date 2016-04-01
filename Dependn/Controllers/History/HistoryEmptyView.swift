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
        imageView.contentMode = .Center
        addSubview(imageView)
        
        textLbl = UILabel()
        textLbl.textColor = UIColor.appBlackColor().colorWithAlphaComponent(0.5)
        textLbl.text = L("history.help")
        textLbl.numberOfLines = 0
        textLbl.textAlignment = .Center
        addSubview(textLbl)
        
        imageView.snp_makeConstraints {
            $0.top.equalTo(self).offset(51)
            $0.left.equalTo(self)
            $0.right.equalTo(self)
            $0.height.equalTo(self.snp_width).multipliedBy(0.93)
        }
        
        textLbl.snp_makeConstraints {
            $0.top.equalTo(imageView.snp_bottom).offset(10)
            $0.left.equalTo(self).offset(50)
            $0.right.equalTo(self).offset(-50)
            $0.bottom.lessThanOrEqualTo(self)
        }
    }

}
