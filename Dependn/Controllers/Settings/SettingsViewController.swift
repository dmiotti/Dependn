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
import WatchConnectivity
import MessageUI

private let kSettingsAppStoreURL = "https://itunes.apple.com/fr/app/dependn-control-your-addictions/id1093903062?l=en&mt=8"

final class SettingsViewController: UIViewController {
    
    enum SettingsSectionType: Int {
        case General
        case Data
        case IAP
        case Others
        
        static let count: Int = {
            var max: Int = 0
            while let _ = SettingsSectionType(rawValue: max) { max += 1 }
            return max
        }()
    }
    
    enum GeneralRowType: Int {
        case Rate
        case ContactUs
        case Passcode
        case Watch
        
        static let count: Int = {
            var max: Int = 0
            while let _ = GeneralRowType(rawValue: max) { max += 1 }
            return max
        }()
    }
    
    enum DataRowType: Int {
        case Export
        case ManageAddictions
        case MemorisePlaces
        
        static let count: Int = {
            var max: Int = 0
            while let _ = DataRowType(rawValue: max) { max += 1 }
            return max
        }()
    }
    
    enum IAPRowType: Int {
        case Restore
        
        static let count: Int = {
            var max: Int = 0
            while let _ = IAPRowType(rawValue: max) { max += 1 }
            return max
        }()
    }
    
    enum OthersRowType: Int {
        case Share
        case Tour
        case Version
        
        static let count: Int = {
            var max: Int = 0
            while let _ = OthersRowType(rawValue: max) { max += 1 }
            return max
        }()
    }
    
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
        return supportedAuthentications
    }
    
    // MARK: - Layout
    
    private func configureLayoutConstraints() {
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    private func showTour() {
        OnBoardingViewController.showInController(self)
    }
    
    private func restorePurchases() {
        HUD.show(.Progress)
        DependnProducts.store.restorePurchases { succeed, error in
            HUD.hide { finished in
                if succeed {
                    let alert = UIAlertController(title: L("settings.restoreiap.success.title"), message: L("settings.restoreiap.success.description"), preferredStyle: .Alert)
                    let okAction = UIAlertAction(title: L("ok"), style: .Default, handler: nil)
                    alert.addAction(okAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: error?.localizedDescription, message: error?.localizedRecoverySuggestion, preferredStyle: .Alert)
                    let okAction = UIAlertAction(title: L("ok"), style: .Default, handler: nil)
                    alert.addAction(okAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
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
        case .Data:          return DataRowType.count
        case .IAP:           return IAPRowType.count
        case .Others:        return OthersRowType.count
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
            case .Rate:
                cell.textLabel?.text = L("settings.rate_app")
            case .ContactUs:
                cell.textLabel?.text = L("settings.contact_us")
            case .Passcode:
                cell.textLabel?.text = L("settings.use_passcode")
                passcodeSwitch.setOn(Defaults[.usePasscode], animated: true)
                passcodeSwitch.enabled = supportedOwnerAuthentications().count > 0
                cell.accessoryView = passcodeSwitch
            case .Watch:
                cell.textLabel?.text = L("settings.apple_watch.addiction")
                if let addiction = Defaults[.watchAddiction] {
                    cell.accessoryView = buildAccessoryLabel(addiction)
                } else {
                    cell.accessoryView = buildAccessoryLabel(L("settings.no_addiction"))
                }
            }
        case .Data:
            let rowType = DataRowType(rawValue: indexPath.row)!
            switch rowType {
                
            case .Export:
                cell.textLabel?.text = L("settings.action.export")
            case .ManageAddictions:
                cell.textLabel?.text = L("settings.manage_addictions")
                cell.accessoryType = .DisclosureIndicator
            case .MemorisePlaces:
                cell.textLabel?.text = L("settings.memorise_places")
                memorizePlacesSwitch.setOn(Defaults[.useLocation], animated: true)
                cell.accessoryView = memorizePlacesSwitch
            }
        case .IAP:
            let rowType = IAPRowType(rawValue: indexPath.row)!
            switch rowType {
            case .Restore:
                cell.textLabel?.text = L("settings.action.restore_iap")
            }
        case .Others:
            let rowType = OthersRowType(rawValue: indexPath.row)!
            switch rowType {
            case .Share:
                cell.textLabel?.text = L("settings.share")
            case .Tour:
                cell.textLabel?.text = L("settings.show_tour")
                cell.accessoryType = .DisclosureIndicator
            case .Version:
                cell.textLabel?.text = L("settings.version")
                cell.accessoryView = buildAccessoryLabel(appVersion())
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
        case .Data:
            titleLbl.text = L("settings.section.data").uppercaseString
        case .IAP:
            titleLbl.text = L("settings.section.iap").uppercaseString
        case .Others:
            titleLbl.text = L("settings.section.others").uppercaseString
        }
        
        return header
    }
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    private func buildAccessoryLabel(text: String) -> UILabel {
        let lbl = UILabel()
        lbl.textColor = UIColor.appLightTextColor()
        lbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        lbl.text = text
        lbl.sizeToFit()
        return lbl
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
            case .Rate:
                let URL = NSURL(string: kSettingsAppStoreURL)!
                UIApplication.sharedApplication().openURL(URL)
            case .ContactUs:
                contactUs()
            case .Passcode:
                break
            case .Watch:
                showSelectAppleWatchAddiction()
            }
        case .Data:
            let rowType = DataRowType(rawValue: indexPath.row)!
            switch rowType {
            case .Export:
                NSOperationQueue().addOperation(ExportOperation(controller: self))
            case .ManageAddictions:
                showManageAddictions()
            case .MemorisePlaces:
                break
            }
        case .IAP:
            let rowType = IAPRowType(rawValue: indexPath.row)!
            switch rowType {
            case .Restore:
                restorePurchases()
            }
        case .Others:
            let rowType = OthersRowType(rawValue: indexPath.row)!
            switch rowType {
            case .Share:
                break // Show share
            case .Tour:
                showTour()
            case .Version:
                break
            }
        }
    }
    
    private func contactUs() {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients([ "contact@dependn.com "])
        presentViewController(mail, animated: true, completion: nil)
    }
    
    private func showSelectAppleWatchAddiction() {
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            if session.paired {
                let search = SearchAdditionViewController()
                if let
                    name = Defaults[.watchAddiction],
                    addiction = try? Addiction.findByName(name, inContext: CoreDataStack.shared.managedObjectContext) {
                    
                    search.selectedAddiction = addiction
                }
                search.delegate = self
                search.useBlueNavigationBar = true
                navigationController?.pushViewController(search, animated: true)
            } else {
                let alert = UIAlertController(title: L("settings.no_applewatch"), message: L("settings.no_applewatch.message"), preferredStyle: .Alert)
                let okAction = UIAlertAction(title: L("ok"), style: .Default, handler: nil)
                alert.addAction(okAction)
                presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func showManageAddictions() {
        let controller = AddictionListViewController()
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - SearchAdditionViewControllerDelegate
extension SettingsViewController: SearchAdditionViewControllerDelegate {
    func searchController(searchController: SearchAdditionViewController, didSelectAddiction addiction: Addiction) {
        Defaults[.watchAddiction] = addiction.name
        WatchSessionManager.sharedManager.updateApplicationContext()
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension MFMailComposeViewController {
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    public override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return nil
    }
}
