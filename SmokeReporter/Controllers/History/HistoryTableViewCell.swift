//
//  HistoryTableViewCell.swift
//  SmokeReporter
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class HistoryTableViewCell: SHCommonInitTableViewCell {
    
    static let reuseIdentifier = "HistoryTableViewCell"
    
    var imgView: UIImageView!
    var dateLbl: UILabel!
    var intensityLbl: UILabel!
    
    override func commonInit() {
        super.commonInit()
        
        accessoryType = .DisclosureIndicator
        
        imgView = UIImageView()
        imgView.contentMode = .ScaleAspectFit
        contentView.addSubview(imgView)
        
        dateLbl = UILabel()
        dateLbl.numberOfLines = 0
        contentView.addSubview(dateLbl)
        
        intensityLbl = UILabel()
        intensityLbl.textAlignment = .Right
        contentView.addSubview(intensityLbl)
        
        configureLayoutConstraints()
    }
    
    private func configureLayoutConstraints() {
        imgView.snp_makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.left.equalTo(contentView).offset(20)
            $0.width.height.equalTo(30)
        }
        
        intensityLbl.snp_makeConstraints {
            $0.right.equalTo(contentView).offset(-20)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
        }
        
        dateLbl.snp_makeConstraints {
            $0.left.equalTo(imgView.snp_right).offset(10)
            $0.top.equalTo(contentView)
            $0.bottom.equalTo(contentView)
            $0.right.equalTo(intensityLbl.snp_left).offset(-10)
        }
    }

}
