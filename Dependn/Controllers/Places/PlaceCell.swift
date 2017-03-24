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
    
    fileprivate(set) var placeLbl: UILabel!

    override func commonInit() {
        super.commonInit()
        
        placeLbl = UILabel()
        placeLbl.textColor = UIColor.appBlackColor()
        placeLbl.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        contentView.addSubview(placeLbl)
        placeLbl.snp.makeConstraints {
            $0.edges.equalTo(contentView).inset(UIEdgeInsets(top: 0, left: 30, bottom: 0, right: -30))
        }
    }

}
