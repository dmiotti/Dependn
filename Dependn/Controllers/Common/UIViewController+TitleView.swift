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
    func updateTitle(_ title: String, blueBackground: Bool = true) {
        let titleLbl = UILabel()
        titleLbl.adjustsFontSizeToFitWidth = true
        titleLbl.attributedText = NSAttributedString(string: title.uppercased(),
            attributes: [
                NSFontAttributeName: UIFont.systemFont(ofSize: 13, weight: UIFontWeightSemibold),
                NSForegroundColorAttributeName: blueBackground ? UIColor.white : UIColor.appBlackColor(),
                NSKernAttributeName: 1.53
            ])
        titleLbl.sizeToFit()
        navigationItem.titleView = titleLbl
    }
    
    func setupBackBarButtonItem() {
        let bbi = UIBarButtonItem(title: L("navigation.back"), style: .plain, target: nil, action: nil)
        bbi.setTitleTextAttributes([
            NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightRegular),
            NSForegroundColorAttributeName: UIColor.appBlueColor(),
            NSKernAttributeName: -0.36
            ], for: .normal)
        navigationItem.backBarButtonItem = bbi
    }
}
