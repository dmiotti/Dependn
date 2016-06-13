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

    private enum RowType {
        case Daily
        case Weekly
    }

    private var rows: [RowType]!

    private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        updateTitle(L("settings.notifications"))

        edgesForExtendedLayout = .None

        view.backgroundColor = UIColor.lightBackgroundColor()

        rows = [ .Daily, .Weekly ]

        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(NotificationSwitchCell.self, forCellReuseIdentifier: NotificationSwitchCell.reuseIdentifier)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 55
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        view.addSubview(tableView)

        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }
}

extension NotificationsViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NotificationSwitchCell.reuseIdentifier, forIndexPath: indexPath) as! NotificationSwitchCell
        cell.delegate = self

        let rawType = Defaults[.notificationTypes]
        let type = NotificationTypes(rawValue: rawType)

        switch rows[indexPath.row] {
        case .Daily:
            cell.textLbl.text = L("notifications.daily")
            cell.switcher.on = type.contains(.Daily)
        case .Weekly:
            cell.textLbl.text = L("notifications.weekly")
            cell.switcher.on = type.contains(.Weekly)
        }
        return cell
    }
}

extension NotificationsViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

extension NotificationsViewController: NotificationSwitchCellDelegate {
    func switchCell(switchCell: NotificationSwitchCell, didChangeValue on: Bool) {
        if on && !PushPermissionViewController.isPermissionAccepted() {
            let push = PushPermissionViewController()
            presentViewController(push, animated: true, completion: nil)
        }

        if let indexPath = tableView.indexPathForCell(switchCell) {
            switch rows[indexPath.row] {
            case .Daily:    updateNotifiTypesWithType(.Daily,   added: on)
            case .Weekly:   updateNotifiTypesWithType(.Weekly, 	added: on)
            }
        }
    }

    /* Update the User Defaults property */
    private func updateNotifiTypesWithType(newType: NotificationTypes, added: Bool) {
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
