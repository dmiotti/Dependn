//
//  SettingsViewController.swift
//  Dependn
//
//  Created by David Miotti on 05/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import SwiftyUserDefaults
import LocalAuthentication
import CocoaLumberjack

enum SettingsRowType: Int {
    case ManageAddictions
    case UsePasscode
    
    static let count: Int = {
        var max: Int = 0
        while let _ = SettingsRowType(rawValue: max) { max += 1 }
        return max
    }()
}

final class SettingsViewController: UIViewController {
    
    private var tableView: UITableView!
    private var passcodeSwitch: UISwitch!
    
    private var pinNavigationController: UINavigationController?
    
    private let authContext = LAContext()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L("settings.title")

        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.registerClass(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        passcodeSwitch = UISwitch()
        passcodeSwitch.on = Defaults[.usePasscode]
        passcodeSwitch.addTarget(self, action: "passcodeSwitchValueChanged:", forControlEvents: .ValueChanged)
        
        configureLayoutConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    func passcodeSwitchValueChanged(sender: UISwitch) {
        if let policy = supportedOwnerAuthentications().first {
            authContext.evaluatePolicy(policy,
                localizedReason: L("passcode.reason")) { (success, error) in
                    if success {
                        Defaults[.usePasscode] = sender.on
                    } else {
                        DDLogError("\(error)")
                        sender.setOn(!sender.on, animated: true)
                    }
            }
        } else {
            sender.setOn(!sender.on, animated: true)
        }
    }
    
    private func supportedOwnerAuthentications() -> [LAPolicy] {
        var supportedAuthentications = [LAPolicy]()
        var error: NSError?
        if authContext.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            supportedAuthentications.append(.DeviceOwnerAuthenticationWithBiometrics)
        }
        DDLogError("\(error)")
        if authContext.canEvaluatePolicy(.DeviceOwnerAuthentication, error: &error) {
            supportedAuthentications.append(.DeviceOwnerAuthentication)
        }
        DDLogError("\(error)")
        return supportedAuthentications
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
        
        cell.accessoryView = nil
        cell.textLabel?.text = nil
        
        switch rowType {
        case .ManageAddictions:
            cell.textLabel?.text = L("settings.manage_addictions")
        case .UsePasscode:
            cell.textLabel?.text = L("settings.use_passcode")
            passcodeSwitch.setOn(Defaults[.usePasscode], animated: true)
            passcodeSwitch.enabled = supportedOwnerAuthentications().count > 0
            cell.accessoryView = passcodeSwitch
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
        case .UsePasscode:
            break
        }
    }
    
    private func showManageAddictions() {
        let controller = AddictionListViewController()
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension SettingsViewController: PasscodeNavigationDelegate {
    func passcodeDidCancel(passcode: PasscodeNavigationViewController) {
        passcode.dismissViewControllerAnimated(true, completion: nil)
    }
}
