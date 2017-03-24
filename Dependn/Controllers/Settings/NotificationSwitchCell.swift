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
    func switchCell(_ switchCell: NotificationSwitchCell, didChangeValue on: Bool)
}

final class NotificationSwitchCell: SHCommonInitTableViewCell {
    static let reuseIdentifier = "NotificationSwitchCell"

    fileprivate(set) var textLbl = UILabel()
    fileprivate(set) var switcher = UISwitch()

    weak var delegate: NotificationSwitchCellDelegate?

    override func commonInit() {
        super.commonInit()

        textLbl.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(textLbl)

        textLbl.snp.makeConstraints {
            $0.edges.equalTo(contentView).inset(UIEdgeInsets(top: 0, left: 15, bottom: 0, right: -15))
        }

        switcher.addTarget(self, action: #selector(NotificationSwitchCell.switchValueChanged(_:)), for: .valueChanged)
        accessoryView = switcher
    }

    func switchValueChanged(_ sender: UISwitch) {
        delegate?.switchCell(self, didChangeValue: sender.isOn)
    }
}
