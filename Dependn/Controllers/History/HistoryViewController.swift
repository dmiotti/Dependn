//
//  ViewController.swift
//  Dependn
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SnapKit
import CoreData
import SwiftHelpers
import PKHUD
import CocoaLumberjack
import SwiftyUserDefaults

final class HistoryViewController: UIViewController {

    fileprivate var actionBtn: UIBarButtonItem!
    fileprivate var exportBtn: UIBarButtonItem!
    fileprivate var tableView: UITableView!
    fileprivate var addBtn: UIButton!
    fileprivate var statsView: StatsPanelScroller!
    fileprivate var dateFormatter: DateFormatter!
    fileprivate var emptyView: HistoryEmptyView!

    fileprivate let managedObjectContext = CoreDataStack.shared.managedObjectContext

    fileprivate let readDateFormatter = DateFormatter()

    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Record> = { () -> NSFetchedResultsController<Record> in
        let controller = Record.historyFetchedResultsController(inContext: self.managedObjectContext)
        controller.delegate = self
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateTitle(L("app_name"))
        setupBackBarButtonItem()
        
        readDateFormatter.dateFormat = "EEEE dd MMMM yyyy"
        
        edgesForExtendedLayout = UIRectEdge()
        
        if let nav = navigationController as? SHStatusBarNavigationController {
            nav.statusBarStyle = .lightContent
        }
        
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        
        actionBtn = UIBarButtonItem(image: UIImage(named: "settings_icon"), style: .plain, target: self, action: #selector(HistoryViewController.actionBtnClicked(_:)))
        navigationItem.leftBarButtonItem = actionBtn
        
        exportBtn = UIBarButtonItem(image: UIImage(named: "export"), style: .plain, target: self, action: #selector(HistoryViewController.exportBtnClicked(_:)))
        
        statsView = StatsPanelScroller()
        
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.contentInset = UIEdgeInsets(top: -10, left: 0, bottom: 0, right: 0)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 55
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.register(HistoryTableViewCell.self,
            forCellReuseIdentifier: HistoryTableViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 120))
        view.addSubview(tableView)

        emptyView = HistoryEmptyView()
        emptyView.alpha = 0
        view.addSubview(emptyView)

        addBtn = UIButton(type: .system)
        addBtn.setImage(UIImage(named: "add")?.withRenderingMode(.alwaysOriginal), for: UIControlState())
        addBtn.addTarget(self, action: #selector(HistoryViewController.addBtnClicked(_:)), for: .touchUpInside)
        view.addSubview(addBtn)

        configureLayoutConstraints()

        configureNotificationObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadInterface()
        configureExportBtn()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !Defaults[.alreadyLaunched] {
            Defaults[.alreadyLaunched] = true
            OnBoardingViewController.showInController(self, animated: false)
        } else if !Defaults[.pushAlreadyShown] && !PushPermissionViewController.isPermissionAccepted() {
            Defaults[.pushAlreadyShown] = true
            let perm = PushPermissionViewController()
            present(perm, animated: true, completion: nil)
        }
    }
    
    fileprivate func configureExportBtn() {
        do {
            if try Record.hasAtLeastOneRecord(inContext: managedObjectContext) {
                if navigationItem.rightBarButtonItem == nil {
                    navigationItem.setRightBarButton(exportBtn, animated: true)
                }
            } else {
                navigationItem.setRightBarButton(nil, animated: true)
            }
        } catch let err as NSError {
            UIAlertController.present(error: err, in: self)
            navigationItem.setRightBarButton(nil, animated: true)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func configureNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(HistoryViewController.coreDataStackDidChange(_:)), name: NSNotification.Name(rawValue: kCoreDataStackStoreDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HistoryViewController.applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    fileprivate func configureStatsView() {
        let addictions = try! Addiction.getAllAddictionsOrderedByCount(inContext: CoreDataStack.shared.managedObjectContext)
        
        if addictions.count > 0 {
            statsView.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 160)
            tableView.tableHeaderView = statsView
            statsView.addictions = addictions
        } else {
            tableView.tableHeaderView = nil
        }
    }
    
    // MARK: - Data Fetch
    
    fileprivate func reloadInterface() {
        fetchExecuted = false
        launchFetchIfNeeded()

        tableView.reloadData()

        configureStatsView()
        
        if fetchedResultsController.fetchedObjects?.count == 0 {
            toggleEmptyView(true)
        } else {
            toggleEmptyView(false)
        }
    }
    
    fileprivate func toggleEmptyView(_ show: Bool) {
        UIView.animate(withDuration: 0.35) {
            self.emptyView.alpha = show ? 1 : 0
            self.tableView.alpha = show ? 0 : 1
        }
    }
    
    // MARK: - Notifications
    
    func coreDataStackDidChange(_ notification: Notification) {
        DispatchQueue.main.async(execute: reloadInterface)
    }

    func applicationWillEnterForeground(_ notification: Notification) {
        reloadInterface()
    }
    
    fileprivate var fetchExecuted = false
    fileprivate func launchFetchIfNeeded() {
        if fetchExecuted { return }
        do {
            try fetchedResultsController.performFetch()
            fetchExecuted = true
        } catch let err as NSError {
            DDLogError("Error while perfoming fetch: \(err)")
            fetchExecuted = false
        }
    }

    // MARK: - Configure Layout Constraints
    
    fileprivate func configureLayoutConstraints() {
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
        
        addBtn.snp.makeConstraints {
            $0.bottom.equalTo(view).offset(-20)
            $0.centerX.equalTo(view)
        }
        
        emptyView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    // MARK: - Add button handler
    
    func actionBtnClicked(_ sender: UIBarButtonItem) {
        let settings = SettingsViewController()
        self.navigationController?.pushViewController(settings, animated: true)
    }
    
    func exportBtnClicked(_ sender: UIBarButtonItem) {
        OperationQueue().addOperation(ExportOperation(controller: self))
    }
    
    func addBtnClicked(_ sender: UIButton) {
        DeeplinkManager.invokeAddEntry(inContext: self)
    }
    
}

// MARK: - UITableViewDataSource
extension HistoryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HistoryTableViewCell.reuseIdentifier, for: indexPath)
        configureCell(cell, forIndexPath: indexPath)
        return cell
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let record = fetchedResultsController.object(at: indexPath) 
            Record.deleteRecord(record, inContext: managedObjectContext)
            configureStatsView()
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = TableHeaderView()

        let dateString = fetchedResultsController.sections?[section].name
        
        if let dateString = dateString, let date = readDateFormatter.date(from: dateString) {
            let proximity = SHDateProximityToDate(date)
            switch proximity {
            case .today:
                header.title = L("history.today").uppercased()
                break
            case .yesterday:
                header.title = L("history.yesterday").uppercased()
                break
            default:
                header.title = dateString.uppercased()
            }
        } else {
            header.title = dateString?.uppercased()
        }
        
        return header
    }
    fileprivate func configureCell(_ cell: UITableViewCell, forIndexPath indexPath: IndexPath) {
        let record = fetchedResultsController.object(at: indexPath)
        if let cell = cell as? HistoryTableViewCell {
            let addiction = record.addiction
            cell.dateLbl.attributedText = attributedStringForRecord(record, addiction: addiction)
            cell.circleTypeView.color = addiction.color.UIColor
            if let first = addiction.name.capitalized.characters.first {
                cell.circleTypeView.textLbl.text = "\(first)"
            }
            cell.intensityCircle.progress = record.intensity.floatValue / 10.0
        }
    }
    fileprivate func attributedStringForRecord(_ record: Record, addiction: Addiction) -> NSAttributedString {
        let dateString = dateFormatter.string(from: record.date).replacingOccurrences(of: ":", with: "h")
        let desireType = record.desire.boolValue ? L("history.record.desire") : L("history.record.conso")
        let typeString = "\(desireType) · \(addiction.name)"
        let full = "\(dateString)\n\(typeString)"
        let attr = NSMutableAttributedString(string: full)
        let fullRange = NSRange(location: 0, length: attr.length)
        attr.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular), range: fullRange)
        attr.addAttribute(NSForegroundColorAttributeName, value: UIColor.appBlackColor(), range: fullRange)
        let typeRange = full.rangeString(typeString)
        attr.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular), range: typeRange)
        attr.addAttribute(NSForegroundColorAttributeName, value: UIColor.appLightTextColor(), range: typeRange)
        return NSAttributedString(attributedString: attr)
    }
}

// MARK: - UITableViewDelegate
extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let recordController = AddRecordViewController()
        recordController.record = fetchedResultsController.object(at: indexPath)
        let nav = SHStatusBarNavigationController(rootViewController: recordController)
        nav.statusBarStyle = .default
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true, completion: nil)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension HistoryViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if UIApplication.shared.applicationState == .background {
            return
        }
        tableView.beginUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if UIApplication.shared.applicationState == .background {
            return
        }
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        if UIApplication.shared.applicationState == .background {
            return
        }
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .update:
            tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .move:
            break
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if UIApplication.shared.applicationState == .background {
            tableView.reloadData()
            return
        }
        tableView.endUpdates()
        configureStatsView()
    }
}
