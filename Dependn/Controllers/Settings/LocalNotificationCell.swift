//
//  LocalNotificationCell.swift
//  Dependn
//
//  Created by David Miotti on 30/06/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class LocalNotificationCell: SHCommonInitTableViewCell {

    static let reuseIdentifier = "LocalNotificationCell"

    let dateLbl     = UILabel()
    let titleLbl    = UILabel()
    let bodyLbl     = UILabel()

    override func commonInit() {
        super.commonInit()

        dateLbl.textColor = UIColor.appBlackColor()
        dateLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightThin)

        titleLbl.textColor = UIColor.appBlackColor()
        titleLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightBold)
        titleLbl.numberOfLines = 0

        bodyLbl.textColor = UIColor.appBlackColor()
        bodyLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        bodyLbl.numberOfLines = 0

        contentView.addSubview(dateLbl)
        contentView.addSubview(titleLbl)
        contentView.addSubview(bodyLbl)

        configureLayoutConstraints()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        dateLbl.text = nil
        titleLbl.text = nil
        bodyLbl.text = nil
    }

    private func configureLayoutConstraints() {
        dateLbl.snp_makeConstraints {
            $0.top.equalTo(contentView).offset(5)
            $0.left.equalTo(contentView).offset(25)
        }
        titleLbl.snp_makeConstraints {
            $0.top.equalTo(dateLbl.snp_bottom).offset(5)
            $0.left.equalTo(dateLbl)
        }
        bodyLbl.snp_makeConstraints {
            $0.top.equalTo(titleLbl.snp_bottom).offset(2)
            $0.left.equalTo(dateLbl)
            $0.bottom.lessThanOrEqualTo(contentView)
        }
    }
}
