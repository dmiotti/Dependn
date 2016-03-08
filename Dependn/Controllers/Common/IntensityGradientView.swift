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
        
        layoutIfNeeded()
    }
    
}
