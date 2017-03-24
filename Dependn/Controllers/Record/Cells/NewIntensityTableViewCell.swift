//
//  NewIntensityTableViewCell.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

protocol NewIntensityTableViewCellDelegate {
    func intensityCell(_ cell: NewIntensityTableViewCell, didChangeIntensity intensity: Float)
}

final class NewIntensityTableViewCell: SHCommonInitTableViewCell {
    
    var delegate: NewIntensityTableViewCellDelegate?
    
    static let reuseIdentifier = "NewIntensityTableViewCell"
    
    fileprivate var intensityView: IntensityGradientView!
    fileprivate var intensityLbl: UILabel!
    
    fileprivate var slide: UISlider!
    
    override func commonInit() {
        super.commonInit()
        
        selectionStyle = .none
        
        contentView.backgroundColor = UIColor.white
        
        intensityView = IntensityGradientView()
        contentView.addSubview(intensityView)
        
        intensityLbl = UILabel()
        intensityLbl.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        intensityLbl.textColor = UIColor.appBlackColor()
        intensityLbl.text = L("intensity.low")
        contentView.addSubview(intensityLbl)
        
        slide = UISlider()
        slide.addTarget(self, action: #selector(NewIntensityTableViewCell.slideValueChanged(_:)), for: .valueChanged)
        slide.tintColor = UIColor.appIntensityLowColor()
        contentView.addSubview(slide)
        
        updateIntensityWithProgress(0.3)
        
        configureLayoutConstraints()
    }
    
    fileprivate func configureLayoutConstraints() {
        intensityView.snp.makeConstraints {
            $0.left.equalTo(contentView).offset(16)
            $0.top.equalTo(contentView).offset(20)
            $0.width.height.equalTo(28)
        }
        
        intensityLbl.snp.makeConstraints {
            $0.left.equalTo(intensityView.snp.right).offset(10)
            $0.right.equalTo(contentView).offset(-16)
            $0.centerY.equalTo(intensityView)
        }
        
        slide.snp.makeConstraints {
            $0.left.equalTo(contentView).offset(16)
            $0.right.equalTo(contentView).offset(-16)
            $0.bottom.equalTo(contentView).offset(-13)
        }
    }
    
    func slideValueChanged(_ sender: UISlider) {
        let progress = sender.value
        updateIntensityWithProgress(progress)
        delegate?.intensityCell(self, didChangeIntensity: progress)
    }
    
    func updateIntensityWithProgress(_ progress: Float) {
        intensityView.progress = progress
        
        let level = IntensityLevel.levelWithProgress(progress)
        switch level {
        case .low:      intensityLbl.text = L("intensity.low")
        case .medium:   intensityLbl.text = L("intensity.medium")
        case .high:     intensityLbl.text = L("intensity.high")
        }
        
        slide.tintColor = UIColor.appIntensityLowColor()
            .blend(with: UIColor.appIntensityHighColor(), alpha: progress)
        
        slide.value = progress
    }

}
