//
//  NotificationSwitchCell.swift
//  Dependn
//
//  Created by David Miotti on 12/06/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

protocol NotificationSwitchCellDelegate: class {
    func switchCell(switchCell: NotificationSwitchCell, didChangeValue on: Bool)
}

final class NotificationSwitchCell: SHCommonInitTableViewCell {
    static let reuseIdentifier = "NotificationSwitchCell"

    private(set) var textLbl = UILabel()
    private(set) var switcher = UISwitch()

    weak var delegate: NotificationSwitchCellDelegate?

    override func commonInit() {
        super.commonInit()

        textLbl.font = UIFont.systemFontOfSize(16)
        contentView.addSubview(textLbl)

        textLbl.snp_makeConstraints {
            $0.edges.equalTo(contentView).offset(
                UIEdgeInsets(top: 0, left: 15, bottom: 0, right: -15))
        }

        switcher.addTarget(self, action: #selector(NotificationSwitchCell.switchValueChanged(_:)), forControlEvents: .ValueChanged)
        accessoryView = switcher
    }

    func switchValueChanged(sender: UISwitch) {
        delegate?.switchCell(self, didChangeValue: sender.on)
    }
}
