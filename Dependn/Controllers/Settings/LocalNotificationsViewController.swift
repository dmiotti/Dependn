//
//  LocalNotificationsViewController.swift
//  Dependn
//
//  Created by David Miotti on 30/06/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import UserNotifications
import UserNotificationsUI

final class LocalNotificationsViewController: UIViewController {

    fileprivate var tableView: UITableView!
    fileprivate var localNotifications = [UNNotificationRequest]()
    fileprivate let dateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()

        updateTitle(L("settings.debug_local_notifications"))

        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(LocalNotificationCell.self, forCellReuseIdentifier: LocalNotificationCell.reuseIdentifier)
        tableView.contentInset = UIEdgeInsets(top: -10, left: 0, bottom: 0, right: 0)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 75
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] notifications in
            self?.localNotifications = notifications
            self?.tableView.reloadData()
        }
    }
}

extension LocalNotificationsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return localNotifications.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LocalNotificationCell.reuseIdentifier, for: indexPath) as! LocalNotificationCell
        cell.prepareForReuse()
        configure(cell: cell, at: indexPath)
        return cell
    }
    private func configure(cell: LocalNotificationCell, at indexPath: IndexPath) {
        let request = localNotifications[indexPath.row]
        let content = request.content
        cell.titleLbl.text = content.title
        cell.bodyLbl.text = content.body
        if
            let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger,
            let next = calendarTrigger.nextTriggerDate() {
            cell.dateLbl.text = dateFormatter.string(from: next)
        } else if
            let timeIntervalTrigger = request.trigger as? UNTimeIntervalNotificationTrigger,
            let next = timeIntervalTrigger.nextTriggerDate() {
            cell.dateLbl.text = dateFormatter.string(from: next)
        } else {
            cell.dateLbl.text = "Unknown"
        }
    }
}

extension LocalNotificationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
}
