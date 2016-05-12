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
    
    private enum SectionType {
        case General
        case Data
        case IAP
        case Others
    }
    
    private enum RowType {
        case Rate
        case ContactUs
        case Passcode
        case Watch
        
        case Export
        case ManageAddictions
        case MemorisePlaces
        
        case Restore
        
        case Share
        case Tour
        case Version
    }
    
    private struct Section {
        var type: SectionType
        var items: [RowType]
    }
    
    private var tableView: UITableView!
    private var passcodeSwitch: UISwitch!
    private var memorizePlacesSwitch: UISwitch!
    
    private var sections = [Section]()
    
    private var pinNavigationController: UINavigationController?
    
    private let authContext = LAContext()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sections = [
            Section(type: .General, items: [ .ContactUs, .Passcode, .Watch, .Version ]),
            Section(type: .Data, items: [ .Export, .ManageAddictions, .MemorisePlaces ]),
            Section(type: .IAP, items: [ .Restore ]),
            Section(type: .Others, items: [ .Rate, .Share, .Tour ])
        ]
        
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
        return sections.count
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SettingsTableViewCell.reuseIdentifier, forIndexPath: indexPath)
        
        cell.accessoryView = nil
        cell.accessoryType = .None
        cell.textLabel?.text = nil
        cell.textLabel?.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        cell.textLabel?.textColor = UIColor.appBlackColor()
        
        let row = sections[indexPath.section].items[indexPath.row]
        switch row {
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
            
        case .Export:
            cell.textLabel?.text = L("settings.action.export")
        case .ManageAddictions:
            cell.textLabel?.text = L("settings.manage_addictions")
            cell.accessoryType = .DisclosureIndicator
        case .MemorisePlaces:
            cell.textLabel?.text = L("settings.memorise_places")
            memorizePlacesSwitch.setOn(Defaults[.useLocation], animated: true)
            cell.accessoryView = memorizePlacesSwitch
            
        case .Restore:
            cell.textLabel?.text = L("settings.action.restore_iap")
            
        case .Share:
            cell.textLabel?.text = L("settings.share")
        case .Tour:
            cell.textLabel?.text = L("settings.show_tour")
            cell.accessoryType = .DisclosureIndicator
        case .Version:
            cell.textLabel?.text = L("settings.version")
            cell.accessoryView = buildAccessoryLabel(appVersion())
        }
        
        return cell
    }
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = TableHeaderView()
        
        let type = sections[section].type
        switch type {
        case .General:
            header.title = L("settings.section.general").uppercaseString
        case .Data:
            header.title = L("settings.section.data").uppercaseString
        case .IAP:
            header.title = L("settings.section.iap").uppercaseString
        case .Others:
            header.title = L("settings.section.others").uppercaseString
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
        
        let row = sections[indexPath.section].items[indexPath.row]
        switch row {
        case .Rate:
            let URL = NSURL(string: kSettingsAppStoreURL)!
            UIApplication.sharedApplication().openURL(URL)
        case .ContactUs:
            contactUs()
        case .Passcode:
            break
        case .Watch:
            showSelectAppleWatchAddiction()
            
        case .Export:
            NSOperationQueue().addOperation(ExportOperation(controller: self))
        case .ManageAddictions:
            showManageAddictions()
        case .MemorisePlaces:
            break
            
        case .Restore:
            restorePurchases()
            
        case .Share:
            shareApp()
        case .Tour:
            showTour()
        case .Version:
            break
        }
    }
    
    private func shareApp() {
        let shareText = L("settings.share_text")
        let shareURL = NSURL(string: kSettingsAppStoreURL)!
        let activityController = UIActivityViewController(activityItems: [shareText, shareURL], applicationActivities: nil)
        activityController.setValue(L("settings.share.object"), forKey: "subject")
        activityController.completionWithItemsHandler = { activityType, completed, items, error in
            if let type = activityType where completed {
                Analytics.instance.shareApp(type)
            }
        }
        presentViewController(activityController, animated: true, completion: nil)
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

extension MFMessageComposeViewController {
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    public override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return nil
    }
}
