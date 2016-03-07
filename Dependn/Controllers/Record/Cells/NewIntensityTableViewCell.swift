//
//  NewIntensityTableViewCell.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

enum IntensityLevel {
    case Low, Medium, High
    
    static func levelWithProgress(progress: Float) -> IntensityLevel {
        if progress <= 0.3 {
            return .Low
        }
        if progress <= 0.7 {
            return .Medium
        }
        return .High
    }
}

final class IntensityGradientView: SHCommonInitView {
    
    private var gradientLayer: CAGradientLayer!
    
    override func commonInit() {
        super.commonInit()
        
        clipsToBounds = true
        
        gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.appIntensityHighColor().CGColor,
            UIColor.appIntensityLowColor().CGColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.locations = [ 0, 0.2, 1 ]
        
        layer.addSublayer(gradientLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.height / 2.0
        gradientLayer.frame = bounds
    }
    
    var progress: Float = 0 {
        didSet {
            animateProgression(progress)
        }
    }
    
    private func animateProgression(progress: Float) {
        let endLocations = [ 0, progress, 1 ]
        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = gradientLayer.locations
        anim.toValue = endLocations
        gradientLayer.locations = endLocations
        gradientLayer.addAnimation(anim, forKey: anim.keyPath)
    }
    
}

protocol NewIntensityTableViewCellDelegate {
    func intensityCell(cell: NewIntensityTableViewCell, didChangeIntensity intensity: Float)
}

final class NewIntensityTableViewCell: SHCommonInitTableViewCell {
    
    var delegate: NewIntensityTableViewCellDelegate?
    
    static let reuseIdentifier = "NewIntensityTableViewCell"
    
    private var intensityView: IntensityGradientView!
    private var intensityLbl: UILabel!
    
    private var slide: UISlider!
    
    override func commonInit() {
        super.commonInit()
        
        selectionStyle = .None
        
        contentView.backgroundColor = UIColor.whiteColor()
        
        intensityView = IntensityGradientView()
        contentView.addSubview(intensityView)
        
        intensityLbl = UILabel()
        intensityLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        intensityLbl.textColor = UIColor.appBlackColor()
        intensityLbl.text = L("intensity.low")
        contentView.addSubview(intensityLbl)
        
        slide = UISlider()
        slide.addTarget(self, action: "slideValueChanged:", forControlEvents: .ValueChanged)
        slide.tintColor = UIColor.appIntensityLowColor()
        contentView.addSubview(slide)
        
        updateIntensityWithProgress(0.3)
        
        configureLayoutConstraints()
    }
    
    private func configureLayoutConstraints() {
        intensityView.snp_makeConstraints {
            $0.left.equalTo(contentView).offset(16)
            $0.top.equalTo(contentView).offset(20)
            $0.width.height.equalTo(28)
        }
        
        intensityLbl.snp_makeConstraints {
            $0.left.equalTo(intensityView.snp_right).offset(10)
            $0.right.equalTo(contentView).offset(-16)
            $0.centerY.equalTo(intensityView)
        }
        
        slide.snp_makeConstraints {
            $0.left.equalTo(contentView).offset(16)
            $0.right.equalTo(contentView).offset(-16)
            $0.bottom.equalTo(contentView).offset(-13)
        }
    }
    
    func slideValueChanged(sender: UISlider) {
        let progress = sender.value
        updateIntensityWithProgress(progress)
        delegate?.intensityCell(self, didChangeIntensity: progress)
    }
    
    func updateIntensityWithProgress(progress: Float) {
        intensityView.progress = progress
        
        let level = IntensityLevel.levelWithProgress(progress)
        switch level {
        case .Low:
            intensityLbl.text = L("intensity.low")
        case .Medium:
            intensityLbl.text = L("intensity.medium")
        case .High:
            intensityLbl.text = L("intensity.high")
        }
        
        slide.tintColor = UIColor.appIntensityLowColor().blendWithColor(
            UIColor.appIntensityHighColor(), alpha: progress)
        
        slide.value = progress
    }

}
