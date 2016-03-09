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
    
    override func commonInit() {
        super.commonInit()
        
        clipsToBounds = true
        
        backgroundColor = UIColor.appIntensityLowColor()
        
        gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.appIntensityHighColor().CGColor,
            UIColor(white: 1, alpha: 0).CGColor
        ]
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
        let endLocations = [ progress * 0.7, 1 ]

        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = gradientLayer.locations
        anim.toValue = endLocations
        anim.duration = 0.35
        gradientLayer.locations = endLocations
        gradientLayer.addAnimation(anim, forKey: anim.keyPath)
        
        layoutIfNeeded()
    }
    
}
