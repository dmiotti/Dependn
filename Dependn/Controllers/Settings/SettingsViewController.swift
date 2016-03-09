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
import PKHUD

enum SettingsSectionType: Int {
    case General
    case ImportExport

    static let count: Int = {
        var max: Int = 0
        while let _ = SettingsSectionType(rawValue: max) { max += 1 }
        return max
    }()
}

enum GeneralRowType: Int {
    case ManageAddictions
    case UsePasscode
    case MemorisePlaces
    case Version

    static let count: Int = {
        var max: Int = 0
        while let _ = GeneralRowType(rawValue: max) { max += 1 }
        return max
    }()
}

enum ImportExportRowType: Int {
    case Export
    case Import

    static let count: Int = {
        var max: Int = 0
        while let _ = ImportExportRowType(rawValue: max) { max += 1 }
        return max
    }()
}

final class SettingsViewController: UIViewController {
    
    private var tableView: UITableView!
    private var passcodeSwitch: UISwitch!
    private var memorizePlacesSwitch: UISwitch!
    
    private var pinNavigationController: UINavigationController?
    
    private let authContext = LAContext()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = .None
        
        updateTitle(L("settings.title"))

        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.registerClass(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        passcodeSwitch = UISwitch()
        passcodeSwitch.on = Defaults[.usePasscode]
        passcodeSwitch.addTarget(self, action: "passcodeSwitchValueChanged:", forControlEvents: .ValueChanged)
        
        memorizePlacesSwitch = UISwitch()
        memorizePlacesSwitch.on = Defaults[.useLocation]
        memorizePlacesSwitch.addTarget(self, action: "memorizePlacesSwitchValueChanged:", forControlEvents: .ValueChanged)
        
        configureLayoutConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Passcode
    
    func passcodeSwitchValueChanged(sender: UISwitch) {
        let reason = sender.on ? L("passcode.reason") : L("passcode.unset")
        if let policy = supportedOwnerAuthentications().first {
            authContext.evaluatePolicy(policy,
                localizedReason: reason) { (success, error) in
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
    
    func memorizePlacesSwitchValueChanged(sender: UISwitch) {
        Defaults[.useLocation] = sender.on
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

    // MARK: - Layout
    
    private func configureLayoutConstraints() {
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }

    // MARK: - Import/Export

    private let queue = NSOperationQueue()
    private func launchExport() {
        HUD.show(.Progress)
        let exportOp = ExportOperation()
        exportOp.completionBlock = {
            dispatch_async(dispatch_get_main_queue()) {
                HUD.hide(animated: true) { finished in
                    if let err = exportOp.error {
                        HUD.flash(HUDContentType.Label(err.localizedDescription))
                    } else if let path = exportOp.exportedPath {
                        let items = [ "export.csv", NSURL(fileURLWithPath: path) ]
                        let share = UIActivityViewController(activityItems: items, applicationActivities: nil)
                        self.presentViewController(share, animated: true, completion: nil)
                    }
                }
            }
        }
        queue.addOperation(exportOp)
    }

    private func launchImport() {
        let importOp = ImportOperation(controller: self)
        importOp.completionBlock = {
            dispatch_async(dispatch_get_main_queue()) {
                if let err = importOp.error {
                    if err.code != kImportOperationUserCancelledCode {
                        UIAlertController.presentError(err, inController: self)
                    }
                } else {
                    HUD.flash(.Success)
                }
            }
        }
        queue.addOperation(importOp)
    }

}

extension SettingsViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return SettingsSectionType.count
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let type = SettingsSectionType(rawValue: section)!
        switch type {
        case .General:       return GeneralRowType.count
        case .ImportExport:  return ImportExportRowType.count
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SettingsTableViewCell.reuseIdentifier, forIndexPath: indexPath)
        cell.accessoryView = nil
        cell.accessoryType = .None
        cell.textLabel?.text = nil
        cell.textLabel?.textColor = UIColor.appBlackColor()

        let type = SettingsSectionType(rawValue: indexPath.section)!
        switch type {
        case .General:
            let rowType = GeneralRowType(rawValue: indexPath.row)!
            switch rowType {
            case .ManageAddictions:
                cell.textLabel?.text = L("settings.manage_addictions")
                cell.accessoryType = .DisclosureIndicator
            case .UsePasscode:
                cell.textLabel?.text = L("settings.use_passcode")
                passcodeSwitch.setOn(Defaults[.usePasscode], animated: true)
                passcodeSwitch.enabled = supportedOwnerAuthentications().count > 0
                cell.accessoryView = passcodeSwitch
            case .MemorisePlaces:
                cell.textLabel?.text = L("settings.memorise_places")
                memorizePlacesSwitch.setOn(Defaults[.useLocation], animated: true)
                cell.accessoryView = memorizePlacesSwitch
            case .Version:
                cell.textLabel?.text = L("settings.version")
                let lbl = UILabel()
                lbl.textColor = UIColor.appBlackColor()
                lbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
                lbl.text = appVersion()
                lbl.sizeToFit()
                cell.accessoryView = lbl
                
            }
        case .ImportExport:
            let rowType = ImportExportRowType(rawValue: indexPath.row)!
            switch rowType {
            case .Import:
                cell.textLabel?.textAlignment = .Center
                cell.textLabel?.text = L("settings.action.import")
            case .Export:
                cell.textLabel?.textAlignment = .Center
                cell.textLabel?.text = L("settings.action.export")
            }
        }

        return cell
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let sectionType = SettingsSectionType(rawValue: indexPath.section)!
        switch sectionType {
            case .General:
                let rowType = GeneralRowType(rawValue: indexPath.row)!
                switch rowType {
                case .ManageAddictions:
                    showManageAddictions()
                case .UsePasscode:
                    break
                case .MemorisePlaces:
                    break
                case .Version:
                    break
                }
            case .ImportExport:
                let rowType = ImportExportRowType(rawValue: indexPath.row)!
                switch rowType {
                case .Import:
                    launchImport()
                case .Export:
                    launchExport()
                }
        }
    }
    
    private func showManageAddictions() {
        let controller = AddictionListViewController()
        navigationController?.pushViewController(controller, animated: true)
    }
}
