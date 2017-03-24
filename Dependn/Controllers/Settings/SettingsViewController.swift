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

final class SettingsViewController: SHNoBackButtonTitleViewController {
    
    fileprivate enum SectionType {
        case general
        case data
        case iap
        case others
    }
    
    fileprivate enum RowType {
        case rate
        case contactUs
        case passcode
        case watch
        case notifications
        
        case export
        case manageAddictions
        case memorisePlaces
        
        case restore
        
        case share
        case tour
        case version
        case debugNotifications
    }
    
    fileprivate struct Section {
        var type: SectionType
        var items: [RowType]
    }
    
    fileprivate var tableView: UITableView!
    fileprivate var passcodeSwitch: UISwitch!
    fileprivate var memorizePlacesSwitch: UISwitch!
    
    fileprivate var sections = [Section]()
    
    fileprivate var pinNavigationController: UINavigationController?
    
    fileprivate let authContext = LAContext()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        #if DEBUG
        sections = [
            Section(type: .data, items: [ .export, .manageAddictions, .memorisePlaces ]),
            Section(type: .general, items: [ .contactUs, .passcode, .watch, .notifications, .version ]),
            Section(type: .iap, items: [ .restore ]),
            Section(type: .others, items: [ .rate, .share, .tour, .debugNotifications ])
        ]
        #else
        sections = [
            Section(type: .data, items: [ .export, .manageAddictions, .memorisePlaces ]),
            Section(type: .general, items: [ .contactUs, .passcode, .watch, .notifications, .version ]),
            Section(type: .iap, items: [ .restore ]),
            Section(type: .others, items: [ .rate, .share, .tour ])
        ]
        #endif

        edgesForExtendedLayout = .all
        
        view.backgroundColor = UIColor.lightBackgroundColor()
        
        updateTitle(L("settings.title"))
        
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.reuseIdentifier)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 55
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        view.addSubview(tableView)
        
        passcodeSwitch = UISwitch()
        passcodeSwitch.isOn = Defaults[.usePasscode]
        passcodeSwitch.addTarget(self, action: #selector(SettingsViewController.passcodeSwitchValueChanged(_:)), for: .valueChanged)

        memorizePlacesSwitch = UISwitch()
        memorizePlacesSwitch.isOn = Defaults[.useLocation]
        memorizePlacesSwitch.addTarget(self, action: #selector(SettingsViewController.memorizePlacesSwitchValueChanged(_:)), for: .valueChanged)
        
        configureLayoutConstraints()
        
        setupBackBarButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Passcode
    
    func passcodeSwitchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
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
    
    func memorizePlacesSwitchValueChanged(_ sender: UISwitch) {
        Defaults[.useLocation] = sender.isOn
    }
    
    fileprivate func supportedOwnerAuthentications() -> [LAPolicy] {
        var supportedAuthentications = [LAPolicy]()
        var error: NSError?
        if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            supportedAuthentications.append(.deviceOwnerAuthenticationWithBiometrics)
        }
        DDLogError(error.debugDescription)
        return supportedAuthentications
    }
    
    // MARK: - Layout
    
    fileprivate func configureLayoutConstraints() {
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    fileprivate func showTour() {
        OnBoardingViewController.showInController(self)
    }
    
    fileprivate func restorePurchases() {
        HUD.show(.progress)
        DependnProducts.store.restorePurchases { succeed, error in
            HUD.hide { finished in
                if succeed {
                    let alert = UIAlertController(title: L("settings.restoreiap.success.title"), message: L("settings.restoreiap.success.description"), preferredStyle: .alert)
                    let okAction = UIAlertAction(title: L("ok"), style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: error?.localizedDescription, message: error?.localizedRecoverySuggestion, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: L("ok"), style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.reuseIdentifier, for: indexPath)
        
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.textLabel?.text = nil
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        cell.textLabel?.textColor = UIColor.appBlackColor()
        
        let row = sections[indexPath.section].items[indexPath.row]
        switch row {
        case .rate:
            cell.textLabel?.text = L("settings.rate_app")
        case .contactUs:
            cell.textLabel?.text = L("settings.contact_us")
        case .passcode:
            cell.textLabel?.text = L("settings.use_passcode")
            passcodeSwitch.setOn(Defaults[.usePasscode], animated: true)
            passcodeSwitch.isEnabled = supportedOwnerAuthentications().count > 0
            cell.accessoryView = passcodeSwitch
        case .watch:
            cell.textLabel?.text = L("settings.apple_watch.addiction")
            if let addiction = Defaults[.watchAddiction] {
                cell.accessoryView = buildAccessoryLabel(addiction)
            } else {
                cell.accessoryView = buildAccessoryLabel(L("settings.no_addiction"))
            }
        case .notifications:
            cell.textLabel?.text = L("settings.notifications")
            cell.accessoryType = .disclosureIndicator

        case .export:
            cell.textLabel?.text = L("settings.action.export")
        case .manageAddictions:
            cell.textLabel?.text = L("settings.manage_addictions")
            cell.accessoryType = .disclosureIndicator
        case .memorisePlaces:
            cell.textLabel?.text = L("settings.memorise_places")
            memorizePlacesSwitch.setOn(Defaults[.useLocation], animated: true)
            cell.accessoryView = memorizePlacesSwitch
            
        case .restore:
            cell.textLabel?.text = L("settings.action.restore_iap")
            
        case .share:
            cell.textLabel?.text = L("settings.share")
        case .tour:
            cell.textLabel?.text = L("settings.show_tour")
            cell.accessoryType = .disclosureIndicator
        case .version:
            cell.textLabel?.text = L("settings.version")
            cell.accessoryView = buildAccessoryLabel(appVersion())
        case .debugNotifications:
            cell.textLabel?.text = L("settings.debug_local_notifications")
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = TableHeaderView()
        
        let type = sections[section].type
        switch type {
        case .general:
            header.title = L("settings.section.general").uppercased()
        case .data:
            header.title = L("settings.section.data").uppercased()
        case .iap:
            header.title = L("settings.section.iap").uppercased()
        case .others:
            header.title = L("settings.section.others").uppercased()
        }
        
        return header
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    fileprivate func buildAccessoryLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.textColor = UIColor.appLightTextColor()
        lbl.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        lbl.text = text
        lbl.sizeToFit()
        return lbl
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = sections[indexPath.section].items[indexPath.row]
        switch row {
        case .rate:
            let url = URL(string: kSettingsAppStoreURL)!
            UIApplication.shared.open(url, options: [:])
        case .contactUs:
            contactUs()
        case .passcode:
            break
        case .watch:
            showSelectAppleWatchAddiction()
        case .notifications:
            manageNotifications()
            
        case .export:
            OperationQueue().addOperation(ExportOperation(controller: self))
        case .manageAddictions:
            showManageAddictions()
        case .memorisePlaces:
            break
            
        case .restore:
            restorePurchases()
            
        case .share:
            shareApp()
        case .tour:
            showTour()
        case .version:
            break
        case .debugNotifications:
            showDebugNotifications()
        }
    }

    fileprivate func showDebugNotifications() {
        let localNotifications = LocalNotificationsViewController()
        navigationController?.pushViewController(localNotifications, animated: true)
    }
    
    fileprivate func shareApp() {
        let shareText = L("settings.share_text")
        let shareURL = URL(string: kSettingsAppStoreURL)!
        let activityController = UIActivityViewController(activityItems: [shareText, shareURL], applicationActivities: nil)
        activityController.setValue(L("settings.share.object"), forKey: "subject")
        activityController.completionWithItemsHandler = { activityType, completed, items, error in
            if let type = activityType, completed {
                Analytics.instance.shareApp(type.rawValue)
            }
        }
        present(activityController, animated: true, completion: nil)
    }

    fileprivate func manageNotifications() {
        let controller = NotificationsViewController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    fileprivate func contactUs() {
        if !MFMailComposeViewController.canSendMail() {
            return
        }
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients([ "contact@dependn.com "])
        present(mail, animated: true, completion: nil)
    }
    
    fileprivate func showSelectAppleWatchAddiction() {
        if WCSession.isSupported() {
            let session = WCSession.default()
            if session.isPaired {
                let search = SearchAdditionViewController()
                if let
                    name = Defaults[.watchAddiction],
                    let addiction = try? Addiction.findByName(name, inContext: CoreDataStack.shared.managedObjectContext) {
                    
                    search.selectedAddiction = addiction
                }
                search.delegate = self
                search.useBlueNavigationBar = true
                navigationController?.pushViewController(search, animated: true)
            } else {
                let alert = UIAlertController(title: L("settings.no_applewatch"), message: L("settings.no_applewatch.message"), preferredStyle: .alert)
                let okAction = UIAlertAction(title: L("ok"), style: .default, handler: nil)
                alert.addAction(okAction)
                present(alert, animated: true, completion: nil)
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
    func searchController(_ searchController: SearchAdditionViewController, didSelectAddiction addiction: Addiction) {
        Defaults[.watchAddiction] = addiction.name
        WatchSessionManager.sharedManager.updateApplicationContext()
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension MFMailComposeViewController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    open override var childViewControllerForStatusBarStyle: UIViewController? {
        return nil
    }
}

extension MFMessageComposeViewController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    open override var childViewControllerForStatusBarStyle: UIViewController? {
        return nil
    }
}
