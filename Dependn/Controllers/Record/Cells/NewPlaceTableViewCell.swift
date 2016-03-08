//
//  NewPlaceTableViewCell.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class NewPlaceTableViewCell: SHCommonInitTableViewCell {
    
    static let reuseIdentifier = "NewPlaceTableViewCell"
    
    private var placeLbl: UILabel!
    private var placeImgView: UIImageView!
    var chosenPlaceLbl: UILabel!
    
    override func commonInit() {
        super.commonInit()
        
        accessoryType = .DisclosureIndicator
        
        placeImgView = UIImageView(image: UIImage(named: "place_icon"))
        placeImgView.contentMode = .Center
        contentView.addSubview(placeImgView)
        
        placeLbl = UILabel()
        placeLbl.text = L("new_record.place")
        placeLbl.textColor = "A2B8CC".UIColor
        placeLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        contentView.addSubview(placeLbl)
        
        chosenPlaceLbl = UILabel()
        chosenPlaceLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        chosenPlaceLbl.textColor = UIColor.appBlackColor()
        chosenPlaceLbl.textAlignment = .Right
        contentView.addSubview(chosenPlaceLbl)
        
        configureLayoutConstraints()
    }
    
    private func configureLayoutConstraints() {
        placeImgView.snp_makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.left.equalTo(contentView).offset(20)
            $0.width.height.equalTo(30)
        }
        placeLbl.snp_makeConstraints {
            $0.left.equalTo(placeImgView.snp_right).offset(14)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
        }
        chosenPlaceLbl.snp_makeConstraints {
            $0.centerY.equalTo(placeLbl)
            $0.right.equalTo(contentView)
            $0.left.equalTo(placeLbl.snp_right)
        }
    }

}
