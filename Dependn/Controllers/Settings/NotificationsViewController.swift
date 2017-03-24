//
//  NotificationsViewController.swift
//  Dependn
//
//  Created by David Miotti on 12/06/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import SwiftyUserDefaults

final class NotificationsViewController: UIViewController {

    fileprivate enum RowType {
        case daily
        case weekly
    }

    fileprivate var rows: [RowType]!

    fileprivate var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        updateTitle(L("settings.notifications"))

        edgesForExtendedLayout = UIRectEdge()

        view.backgroundColor = UIColor.lightBackgroundColor()

        rows = [ .daily, .weekly ]

        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NotificationSwitchCell.self, forCellReuseIdentifier: NotificationSwitchCell.reuseIdentifier)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 55
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        view.addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
    }
}

extension NotificationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationSwitchCell.reuseIdentifier, for: indexPath) as! NotificationSwitchCell
        cell.delegate = self

        let rawType = Defaults[.notificationTypes]
        let type = NotificationTypes(rawValue: rawType)

        switch rows[indexPath.row] {
        case .daily:
            cell.textLbl.text = L("notifications.daily")
            cell.switcher.isOn = type.contains(.daily)
        case .weekly:
            cell.textLbl.text = L("notifications.weekly")
            cell.switcher.isOn = type.contains(.weekly)
        }
        return cell
    }
}

extension NotificationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension NotificationsViewController: NotificationSwitchCellDelegate {
    func switchCell(_ switchCell: NotificationSwitchCell, didChangeValue on: Bool) {
        if on && !PushPermissionViewController.isPermissionAccepted() {
            let push = PushPermissionViewController()
            present(push, animated: true, completion: nil)
        }

        if let indexPath = tableView.indexPath(for: switchCell) {
            switch rows[indexPath.row] {
            case .daily:    updateNotifiTypesWithType(.daily,   added: on)
            case .weekly:   updateNotifiTypesWithType(.weekly, 	added: on)
            }
        }
    }

    /* Update the User Defaults property */
    fileprivate func updateNotifiTypesWithType(_ newType: NotificationTypes, added: Bool) {
        let rawValue = Defaults[.notificationTypes]
        var types = NotificationTypes(rawValue: rawValue)
        if added {
            if !types.contains(newType) {
                types.insert(newType)
            }
        } else {
            if types.contains(newType) {
                types.remove(newType)
            }
        }
        Defaults[.notificationTypes] = types.rawValue
    }
}
