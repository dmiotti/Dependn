//
//  UIViewController+TitleView.swift
//  Dependn
//
//  Created by David Miotti on 10/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import UIKit
import SwiftHelpers

extension UIViewController {
    func updateTitle(title: String, blueBackground: Bool = true) {
        let titleLbl = UILabel()
        titleLbl.attributedText = NSAttributedString(string: title.uppercaseString,
            attributes: [
                NSFontAttributeName: UIFont.systemFontOfSize(13, weight: UIFontWeightSemibold),
                NSForegroundColorAttributeName: blueBackground ? UIColor.whiteColor() : UIColor.appBlackColor(),
                NSKernAttributeName: 1.53
            ])
        titleLbl.sizeToFit()
        navigationItem.titleView = titleLbl
    }
    
    func setupBackBarButtonItem() {
        let bbi = UIBarButtonItem(title: L("navigation.back"), style: .Plain, target: nil, action: nil)
        bbi.setTitleTextAttributes([
            NSFontAttributeName: UIFont.systemFontOfSize(15, weight: UIFontWeightRegular),
            NSForegroundColorAttributeName: UIColor.appBlueColor(),
            NSKernAttributeName: -0.36
            ], forState: .Normal)
        navigationItem.backBarButtonItem = bbi
    }
}
