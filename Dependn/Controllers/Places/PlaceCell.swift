//
//  PlaceCell.swift
//  Dependn
//
//  Created by David Miotti on 23/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class PlaceCell: SHCommonInitTableViewCell {
    
    static let reuseIdentifier = "PlaceCell"
    
    private(set) var placeLbl: UILabel!

    override func commonInit() {
        super.commonInit()
        
        placeLbl = UILabel()
        placeLbl.textColor = UIColor.appBlackColor()
        placeLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        contentView.addSubview(placeLbl)
        placeLbl.snp_makeConstraints {
            $0.edges.equalTo(contentView).offset(
                UIEdgeInsets(top: 0, left: 30, bottom: 0, right: -30))
        }
    }

}
