//
//  IntensityGradientView.swift
//  Dependn
//
//  Created by David Miotti on 08/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
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
    private var intensityValueLbl: UILabel!
    
    override func commonInit() {
        super.commonInit()
        
        clipsToBounds = true
        
        backgroundColor = "FDE16A".UIColor
        
        gradientLayer = CAGradientLayer()
        gradientLayer.transform = CATransform3DMakeRotation(CGFloat(M_PI), 0, 0, 1)
        gradientLayer.colors = [
            "F76589".UIColor.colorWithAlphaComponent(0.7).CGColor,
            UIColor(white: 1, alpha: 0).CGColor
        ]
        layer.addSublayer(gradientLayer)
        
        intensityValueLbl = UILabel()
        intensityValueLbl.textColor = UIColor.whiteColor()
        intensityValueLbl.font = UIFont.systemFontOfSize(15, weight: UIFontWeightMedium)
        intensityValueLbl.textAlignment = .Center
        addSubview(intensityValueLbl)

        intensityValueLbl.snp_makeConstraints {
            $0.edges.equalTo(self)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.height / 2.0
        gradientLayer.frame = bounds
    }
    
    var progress: Float = 0 {
        didSet {
            animateProgression(progress)
            let rounded = Int(round(progress * 10))
            intensityValueLbl.text = "\(rounded)"
        }
    }
    
    private func animateProgression(progress: Float) {
        let endLocations = [ progress, 1 ]

        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = gradientLayer.locations
        anim.toValue = endLocations
        anim.duration = 0.35
        gradientLayer.locations = endLocations
        gradientLayer.colors = [
            "F76589".UIColor.colorWithAlphaComponent(CGFloat(progress)).CGColor,
            UIColor(white: 1, alpha: 0).CGColor
        ]

        gradientLayer.addAnimation(anim, forKey: anim.keyPath)
        
        layoutIfNeeded()
    }
    
}
