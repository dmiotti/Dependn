//
//  SettingsViewController.swift
//  Dependn
//
//  Created by David Miotti on 05/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

enum SettingsRowType: Int {
    case ManageAddictions
    
    static let count: Int = {
        var max: Int = 0
        while let _ = SettingsRowType(rawValue: max) { max += 1 }
        return max
    }()
}

final class SettingsViewController: UIViewController {
    
    private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L("settings.title")

        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.registerClass(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        configureLayoutConstraints()
    }
    
    private func configureLayoutConstraints() {
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }

}

extension SettingsViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingsRowType.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SettingsTableViewCell.reuseIdentifier, forIndexPath: indexPath)
        let rowType = SettingsRowType(rawValue: indexPath.row)!
        switch rowType {
        case .ManageAddictions:
            cell.textLabel?.text = L("settings.manage_addictions")
        }
        return cell
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let rowType = SettingsRowType(rawValue: indexPath.row)!
        switch rowType {
        case .ManageAddictions:
            showManageAddictions()
        }
    }
    
    private func showManageAddictions() {
        let controller = AddictionListViewController()
        navigationController?.pushViewController(controller, animated: true)
    }
}
