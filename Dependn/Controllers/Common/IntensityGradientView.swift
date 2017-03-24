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
    case low, medium, high
    
    static func levelWithProgress(_ progress: Float) -> IntensityLevel {
        if progress <= 0.3 {
            return .low
        }
        if progress <= 0.7 {
            return .medium
        }
        return .high
    }
}

final class IntensityGradientView: SHCommonInitView {
    
    fileprivate var gradientLayer: CAGradientLayer!
    fileprivate var intensityValueLbl: UILabel!
    
    override func commonInit() {
        super.commonInit()
        
        clipsToBounds = true
        
        backgroundColor = "FDE16A".UIColor
        
        gradientLayer = CAGradientLayer()
        gradientLayer.transform = CATransform3DMakeRotation(CGFloat(Double.pi), 0, 0, 1)
        gradientLayer.colors = [
            "F76589".UIColor.withAlphaComponent(0.7).cgColor,
            UIColor(white: 1, alpha: 0).cgColor
        ]
        layer.addSublayer(gradientLayer)
        
        intensityValueLbl = UILabel()
        intensityValueLbl.textColor = UIColor.white
        intensityValueLbl.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightMedium)
        intensityValueLbl.textAlignment = .center
        addSubview(intensityValueLbl)

        intensityValueLbl.snp.makeConstraints {
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
    
    fileprivate func animateProgression(_ progress: Float) {
        let endLocations = [ progress, 1 ]

        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = gradientLayer.locations
        anim.toValue = endLocations
        anim.duration = 0.35
        gradientLayer.locations = endLocations as [NSNumber]?
        gradientLayer.colors = [
            "F76589".UIColor.withAlphaComponent(CGFloat(progress)).cgColor,
            UIColor(white: 1, alpha: 0).cgColor
        ]

        gradientLayer.add(anim, forKey: anim.keyPath)
        
        layoutIfNeeded()
    }
    
}
