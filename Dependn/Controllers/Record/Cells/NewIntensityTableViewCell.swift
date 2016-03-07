//
//  NewIntensityTableViewCell.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class NewIntensityTableViewCell: SHCommonInitTableViewCell {
    
    static let reuseIdentifier = "NewIntensityTableViewCell"
    
    private var slide: UISlider!
    
    override func commonInit() {
        super.commonInit()
        
        selectionStyle = .None
        
        contentView.backgroundColor = UIColor.whiteColor()
        
        slide = UISlider()
        contentView.addSubview(slide)
        
        configureLayoutConstraints()
    }
    
    private func configureLayoutConstraints() {
        slide.snp_makeConstraints {
            $0.left.equalTo(contentView).offset(16)
            $0.right.equalTo(contentView).offset(-16)
            $0.bottom.equalTo(contentView).offset(-13)
        }
    }

}
