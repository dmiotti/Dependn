//
//  StyleSheet.swift
//  SmokeReporter
//
//  Created by David Miotti on 22/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit

final class StyleSheet {
    
    static let lowIntensityColor = UIColor.greenColor()
    static let mediumIntensityColor = UIColor.brownColor()
    static let highIntensityColor = UIColor.orangeColor()
    static let veryHighIntensityColor = UIColor.redColor()
    
    static func colorForIntensity(intensity: Float) -> UIColor {
        if intensity <= 4 {
            return lowIntensityColor
        } else if intensity <= 6 {
            return mediumIntensityColor
        } else if intensity <= 8 {
            return highIntensityColor
        }
        return veryHighIntensityColor
    }

}
