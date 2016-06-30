//
//  LocalNotificationsViewController.swift
//  Dependn
//
//  Created by David Miotti on 30/06/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

final class LocalNotificationsViewController: UIViewController {

    private var tableView: UITableView!
    private var localNotifications = [UILocalNotification]()
    private let dateFormatter = NSDateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()

        updateTitle(L("settings.debug_local_notifications"))

        dateFormatter.dateStyle = .FullStyle

        localNotifications = UIApplication.sharedApplication().scheduledLocalNotifications ?? []
        localNotifications.sortInPlace { a, b in
            if let aDate = a.fireDate, bDate = b.fireDate {
                return bDate > aDate
            }
            return false
        }

        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.registerClass(LocalNotificationCell.self, forCellReuseIdentifier: LocalNotificationCell.reuseIdentifier)
        tableView.contentInset = UIEdgeInsets(top: -10, left: 0, bottom: 0, right: 0)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 75
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        view.addSubview(tableView)
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }
}

extension LocalNotificationsViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return localNotifications.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(LocalNotificationCell.reuseIdentifier, forIndexPath: indexPath) as! LocalNotificationCell
        cell.prepareForReuse()
        let n = localNotifications[indexPath.row]
        cell.titleLbl.text = n.alertTitle
        cell.bodyLbl.text = n.alertBody
        if let date = n.fireDate {
            cell.dateLbl.text = dateFormatter.stringFromDate(date)
        }
        return cell
    }
}

extension LocalNotificationsViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
