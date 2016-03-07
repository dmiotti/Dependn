//
//  StyleSheet.swift
//  Dependn
//
//  Created by David Miotti on 22/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

class StyleSheet {
    class func customizeAppearance(window: UIWindow?) {
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        let attr = [
            NSFontAttributeName: UIFont.systemFontOfSize(13, weight: UIFontWeightSemibold),
            NSForegroundColorAttributeName: UIColor.whiteColor()
        ]
        UINavigationBar.appearance().titleTextAttributes = attr
        
        UINavigationBar.appearance().barTintColor = UIColor.appBlueColor()
        
        UIBarButtonItem.appearance().tintColor = UIColor.whiteColor()
        UIBarButtonItem.appearance().setTitleTextAttributes(attr, forState: .Normal)
        
        UIBarButtonItem.appearanceWhenContainedInInstancesOfClasses([UIToolbar.self]).tintColor = UIColor.appBlueColor()
        
        UIBarButtonItem.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).setTitleTextAttributes([
            NSForegroundColorAttributeName: UIColor.appBlueColor(),
            NSFontAttributeName: UIFont.systemFontOfSize(14, weight: UIFontWeightRegular)
            ], forState: .Normal)
        UIBarButtonItem.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).tintColor = UIColor.appBlueColor()
        
        window?.tintColor = UIColor.appBlueColor()
    }
}

extension UIColor {
    
    class func appBlueColor()           -> UIColor { return "28AFFA".UIColor }
    class func appBlackColor()          -> UIColor { return "030303".UIColor }
    class func appLightTextColor()      -> UIColor { return "A2B8CC".UIColor }
    class func appCigaretteColor()      -> UIColor { return "28AFFA".UIColor }
    class func appWeedColor()           -> UIColor { return "2DD7AA".UIColor }
    class func lightBackgroundColor()   -> UIColor { return "F5FAFF".UIColor }
    
    class func appIntensityLowColor()   -> UIColor { return "FDDC6A".UIColor }
    class func appIntensityHighColor()  -> UIColor { return "F76D5F".UIColor }

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

