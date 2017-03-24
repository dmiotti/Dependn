//
//  NewAddictionTableViewCell.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class NewAddictionTableViewCell: SHCommonInitTableViewCell {
    
    static let reuseIdentifier = "NewAddictionTableViewCell"
    
    fileprivate var titleLbl: UILabel!
    
    override func commonInit() {
        super.commonInit()
        
        titleLbl = UILabel()
        titleLbl.textAlignment = .center
        titleLbl.textColor = UIColor.appBlueColor()
        titleLbl.text = L("search.add_addiction")
        titleLbl.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        contentView.addSubview(titleLbl)
        
        titleLbl.snp.makeConstraints {
            $0.edges.equalTo(contentView)
        }
    }

}
