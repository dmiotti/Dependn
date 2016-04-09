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
    case ShowTour

    static let count: Int = {
        var max: Int = 0
        while let _ = GeneralRowType(rawValue: max) { max += 1 }
        return max
    }()
}

enum ImportExportRowType: Int {
    case Export

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
        
        view.backgroundColor = UIColor.lightBackgroundColor()
        
        updateTitle(L("settings.title"))

        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.registerClass(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.reuseIdentifier)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 55
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        view.addSubview(tableView)
        
        passcodeSwitch = UISwitch()
        passcodeSwitch.on = Defaults[.usePasscode]
        passcodeSwitch.addTarget(self, action: #selector(SettingsViewController.passcodeSwitchValueChanged(_:)), forControlEvents: .ValueChanged)
        
        memorizePlacesSwitch = UISwitch()
        memorizePlacesSwitch.on = Defaults[.useLocation]
        memorizePlacesSwitch.addTarget(self, action: #selector(SettingsViewController.memorizePlacesSwitchValueChanged(_:)), forControlEvents: .ValueChanged)
        
        configureLayoutConstraints()
        
        setupBackBarButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Passcode
    
    func passcodeSwitchValueChanged(sender: UISwitch) {
        if sender.on {
            if supportedOwnerAuthentications().count > 0 {
                Defaults[.usePasscode] = true
            } else {
                sender.setOn(false, animated: true)
            }
        } else {
            Defaults[.usePasscode] = false
            sender.setOn(false, animated: true)
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
        let path = self.exportPath()
        let exportOp = XLSExportOperation(path: path)
        exportOp.completionBlock = {
            dispatch_async(dispatch_get_main_queue()) {
                HUD.hide(animated: true) { finished in
                    if let err = exportOp.error {
                        HUD.flash(HUDContentType.Label(err.localizedDescription))
                    } else {
                        let URL = NSURL(fileURLWithPath: path)
                        let controller = UIDocumentInteractionController(URL: URL)
                        controller.delegate = self
                        controller.presentPreviewAnimated(true)
                    }
                }
            }
        }
        queue.addOperation(exportOp)
    }
    
    private func exportPath() -> String {
        let dateFormatter = NSDateFormatter(dateFormat: "dd'_'MM'_'yyyy'_'HH'_'mm")
        let filename = "export_\(dateFormatter.stringFromDate(NSDate()))"
        return applicationCachesDirectory
            .URLByAppendingPathComponent(filename)
            .URLByAppendingPathExtension("xlsx").path!
    }
    
    private lazy var applicationCachesDirectory: NSURL = {
        let urls = NSFileManager.defaultManager()
            .URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    private func launchImport() {
        let importOp = ImportOperation(controller: self)
        importOp.completionBlock = {
            dispatch_async(dispatch_get_main_queue()) {
                if let err = importOp.error {
                    if err.code != kImportOperationUserCancelledCode {
                        UIAlertController.presentAlertWithTitle(nil, message: err.localizedRecoverySuggestion, inController: self)
                    }
                } else {
                    HUD.flash(.Success)
                }
            }
        }
        queue.addOperation(importOp)
    }
    
    private func showTour() {
        OnBoardingViewController.showInController(self)
    }

}

// MARK: - UITableViewDataSource
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
        cell.textLabel?.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
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
            case .ShowTour:
                cell.textLabel?.text = L("settings.show_tour")
                cell.accessoryType = .DisclosureIndicator
            }
        case .ImportExport:
            let rowType = ImportExportRowType(rawValue: indexPath.row)!
            switch rowType {
            case .Export:
                cell.textLabel?.textAlignment = .Center
                cell.textLabel?.text = L("settings.action.export")
            }
        }

        return cell
    }
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 40))
        
        let titleLbl = UILabel()
        titleLbl.font = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
        titleLbl.textColor = UIColor.appDarkBlueColor()
        header.addSubview(titleLbl)
        
        titleLbl.snp_makeConstraints {
            $0.left.equalTo(header).offset(15)
            $0.bottom.equalTo(header).offset(-5)
        }
        
        let type = SettingsSectionType(rawValue: section)!
        switch type {
        case .General:
            titleLbl.text = L("settings.section.general").uppercaseString
        case .ImportExport:
            titleLbl.text = L("settings.section.informations").uppercaseString
        }
        
        return header
    }
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let type = SettingsSectionType(rawValue: section)!
        switch type {
        case .General:
            return 40
        case .ImportExport:
            return 40
        }
    }
}

// MARK: - UITableViewDelegate
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
                case .ShowTour:
                    showTour()
                    break
                }
            case .ImportExport:
                let rowType = ImportExportRowType(rawValue: indexPath.row)!
                switch rowType {
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

// MARK: - UIDocumentInteractionControllerDelegate
extension SettingsViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return tabBarController ?? self
    }
}
