//
//  StyleSheet.swift
//  SmokeReporter
//
//  Created by David Miotti on 22/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

class StyleSheet {
    class func constomizeAppearance(window: UIWindow?) {
        UINavigationBar.appearance().tintColor = L("color.navigationbar").UIColor
        let attr = [
            NSFontAttributeName: UIFont.systemFontOfSize(13, weight: UIFontWeightSemibold),
            NSForegroundColorAttributeName: L("color.navigationbar_title").UIColor
        ]
        UINavigationBar.appearance().titleTextAttributes = attr
        
        UINavigationBar.appearance().barTintColor = L("color.navigationbar_bar").UIColor
        
        UIBarButtonItem.appearance().tintColor = L("color.navigationbar_button").UIColor
        UIBarButtonItem.appearance().setTitleTextAttributes(attr, forState: .Normal)
        
        window?.tintColor = L("color.window").UIColor
    }
}

extension UIColor {
    
    class func lightBackgroundColor()   ->  UIColor { return "F5FAFF".UIColor }

    class func lowIntensityColor()      -> UIColor { return  UIColor.emeraldColor()     }
    class func mediumIntensityColor()   -> UIColor { return  UIColor.nephritisColor()   }
    class func highIntensityColor()     -> UIColor { return  UIColor.carrotColor()      }
    class func veryHighIntensityColor() -> UIColor { return  UIColor.pomegranateColor() }
    
    static func colorForIntensity(intensity: Float) -> UIColor {
        if intensity <= 4 {
            return lowIntensityColor()
        } else if intensity <= 6 {
            return mediumIntensityColor()
        } else if intensity <= 8 {
            return highIntensityColor()
        }
        return veryHighIntensityColor()
    }
    
    // green sea
    class func turquoiseColor()    -> UIColor { return UIColor.colorWithHex(0x1abc9c) }
    class func greenSeaColor()     -> UIColor { return UIColor.colorWithHex(0x16a085) }
    // green
    class func emeraldColor()      -> UIColor { return UIColor.colorWithHex(0x2ecc71) }
    class func nephritisColor()    -> UIColor { return UIColor.colorWithHex(0x27ae60) }
    // blue
    class func peterRiverColor()   -> UIColor { return UIColor.colorWithHex(0x3498db) }
    class func belizeHoleColor()   -> UIColor { return UIColor.colorWithHex(0x2980b9) }
    // purple
    class func amethystColor()     -> UIColor { return UIColor.colorWithHex(0x9b59b6) }
    class func wisteriaColor()     -> UIColor { return UIColor.colorWithHex(0x8e44ad) }
    // dark blue
    class func wetAsphaltColor()   -> UIColor { return UIColor.colorWithHex(0x34495e) }
    class func midnightBlueColor() -> UIColor { return UIColor.colorWithHex(0x2c3e50) }
    // yellow
    class func sunFlowerColor()    -> UIColor { return UIColor.colorWithHex(0xf1c40f) }
    class func flatOrangeColor()   -> UIColor { return UIColor.colorWithHex(0xf39c12) }
    // orange
    class func carrotColor()       -> UIColor { return UIColor.colorWithHex(0xe67e22) }
    class func pumkinColor()       -> UIColor { return UIColor.colorWithHex(0xd35400) }
    // red
    class func alizarinColor()     -> UIColor { return UIColor.colorWithHex(0xe74c3c) }
    class func pomegranateColor()  -> UIColor { return UIColor.colorWithHex(0xc0392b) }
    // white
    class func cloudsColor()       -> UIColor { return UIColor.colorWithHex(0xecf0f1) }
    class func silverColor()       -> UIColor { return UIColor.colorWithHex(0xbdc3c7) }
    // gray
    class func asbestosColor()     -> UIColor { return UIColor.colorWithHex(0x7f8c8d) }
    class func concerteColor()     -> UIColor { return UIColor.colorWithHex(0x95a5a6) }
    
    class func colorWithHex(hex: Int, alpha: CGFloat = 1.0) -> UIColor {
        let r = CGFloat((hex & 0xff0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00ff00) >>  8) / 255.0
        let b = CGFloat((hex & 0x0000ff) >>  0) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }
}

