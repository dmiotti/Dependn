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

final class HistoryViewController: UIViewController {
    
    private var actionBtn: UIBarButtonItem!
    private var tableView: UITableView!
    private var addBtn: UIButton!
    private var statsView: StatsPanelScroller!
    private var dateFormatter: NSDateFormatter!
    
    private let managedObjectContext = CoreDataStack.shared.managedObjectContext
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let controller = Record.historyFetchedResultsController(inContext: self.managedObjectContext)
        controller.delegate = self
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateTitle(L("app_name"))
        setupBackBarButtonItem()
        
        edgesForExtendedLayout = .None
        
        if let nav = navigationController as? SHStatusBarNavigationController {
            nav.statusBarStyle = .LightContent
        }
        
        dateFormatter = NSDateFormatter(dateFormat: "HH'h'mm")
        
        actionBtn = UIBarButtonItem(image: UIImage(named: "settings_icon"), style: .Plain, target: self, action: #selector(HistoryViewController.actionBtnClicked(_:)))
        navigationItem.leftBarButtonItem = actionBtn
        
        statsView = StatsPanelScroller()
        
        tableView = UITableView(frame: .zero, style: .Plain)
        tableView.contentInset = UIEdgeInsets(top: -10, left: 0, bottom: 0, right: 0)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 55
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.registerClass(HistoryTableViewCell.self,
            forCellReuseIdentifier: HistoryTableViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 120))
        view.addSubview(tableView)
        
        addBtn = UIButton(type: .System)
        addBtn.setImage(UIImage(named: "add")?.imageWithRenderingMode(.AlwaysOriginal), forState: .Normal)
        addBtn.addTarget(self, action: #selector(HistoryViewController.addBtnClicked(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(addBtn)
        
        configureLayoutConstraints()
        
        configureNotificationObservers()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadInterface()
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let alreadyLaunched = userDefaults.boolForKey("alreadyLaunched")
        if !alreadyLaunched {
            userDefaults.setBool(true, forKey: "alreadyLaunched")
            userDefaults.synchronize()
            
            let onBoarding = OnBoardingViewController()
            presentViewController(onBoarding, animated: false, completion: nil)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func configureNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryViewController.coreDataStackDidChange(_:)), name: kCoreDataStackStoreDidChange, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryViewController.applicationWillEnterForground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    private func configureStatsView() {
        let addictions = try! Addiction.getAllAddictionsOrderedByCount(inContext: CoreDataStack.shared.managedObjectContext)
        
        if addictions.count > 0 {
            statsView.frame = CGRectMake(0, 0, view.bounds.size.width, 160)
            tableView.tableHeaderView = statsView
            statsView.addictions = addictions
        } else {
            tableView.tableHeaderView = nil
        }
    }
    
    // MARK: - Data Fetch
    
    private func reloadInterface() {
        launchFetchIfNeeded()
        tableView.reloadData()
        configureStatsView()
    }
    
    // MARK: - Notifications
    
    func applicationWillEnterForground(notification: NSNotification) {
        reloadInterface()
    }
    
    func coreDataStackDidChange(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            self.fetchExecuted = false
            self.reloadInterface()
        }
    }
    
    private var fetchExecuted = false
    private func launchFetchIfNeeded() {
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
    
    private func configureLayoutConstraints() {
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
        
        addBtn.snp_makeConstraints {
            $0.bottom.equalTo(view).offset(-20)
            $0.centerX.equalTo(view)
        }
    }
    
    // MARK: - Add button handler
    
    func actionBtnClicked(sender: UIBarButtonItem) {
        let settings = SettingsViewController()
        self.navigationController?.pushViewController(settings, animated: true)
    }
    
    func addBtnClicked(sender: UIButton) {
        if ensureThereIsAddictions() {
            let nav = SHStatusBarNavigationController(rootViewController: AddRecordViewController())
            nav.statusBarStyle = .Default
            nav.modalPresentationStyle = .FormSheet
            presentViewController(nav, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: L("history.no_addictions.title"), message: L("history.no_addictions.message"), preferredStyle: .Alert)
            let addAction = UIAlertAction(title: L("history.no_addictions.add"), style: .Default) { action in
                let controller = AddictionListViewController()
                self.navigationController?.pushViewController(controller, animated: true)
            }
            let okAction = UIAlertAction(title: L("history.no_addictions.ok"), style: .Cancel, handler: nil)
            alert.addAction(addAction)
            alert.addAction(okAction)
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func ensureThereIsAddictions() -> Bool {
        var hasAddictions = false
        do {
            hasAddictions = try Addiction.getAllAddictions(inContext: managedObjectContext).count > 0
        } catch let err as NSError {
            DDLogError("Error while checking there is at least one addiction: \(err)")
        }
        return hasAddictions
    }
    
}

// MARK: - UITableViewDataSource
extension HistoryViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(HistoryTableViewCell.reuseIdentifier, forIndexPath: indexPath)
        configureCell(cell, forIndexPath: indexPath)
        return cell
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let record = fetchedResultsController.objectAtIndexPath(indexPath) as! Record
            Record.deleteRecord(record, inContext: managedObjectContext)
            configureStatsView()
        }
    }
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = "F5FAFF".UIColor
        
        let date = UILabel()
        date.text = fetchedResultsController.sections?[section].name.uppercaseString
        date.font = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
        date.textColor = "7D9BB8".UIColor
        header.addSubview(date)
        
        date.snp_makeConstraints {
            $0.left.equalTo(header).offset(15)
            $0.bottom.equalTo(header).offset(-6)
        }
        
        let sepTop = UIView()
        sepTop.backgroundColor = UIColor.appSeparatorColor()
        header.addSubview(sepTop)
        sepTop.snp_makeConstraints {
            $0.top.equalTo(header)
            $0.left.equalTo(header)
            $0.right.equalTo(header)
            $0.height.equalTo(0.5)
        }
        
        let sepBtm = UIView()
        sepBtm.backgroundColor = UIColor.appSeparatorColor()
        header.addSubview(sepBtm)
        sepBtm.snp_makeConstraints {
            $0.bottom.equalTo(header)
            $0.left.equalTo(header)
            $0.right.equalTo(header)
            $0.height.equalTo(0.5)
        }
        
        return header
    }
    private func configureCell(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) {
        let record = fetchedResultsController.objectAtIndexPath(indexPath) as! Record
        if let cell = cell as? HistoryTableViewCell {
            let addiction = record.addiction
            cell.dateLbl.attributedText = attributedStringForRecord(record, addiction: addiction)
            cell.circleTypeView.color = addiction.color.UIColor
            if let first = addiction.name.capitalizedString.characters.first {
                cell.circleTypeView.textLbl.text = "\(first)"
            }
            cell.intensityCircle.progress = record.intensity.floatValue / 10.0
        }
    }
    private func attributedStringForRecord(record: Record, addiction: Addiction) -> NSAttributedString {
        let dateString = dateFormatter.stringFromDate(record.date)
        let desireType = record.desire.boolValue ? L("history.record.desire") : L("history.record.conso")
        let typeString = "\(desireType) · \(addiction.name.capitalizedString)"
        let full = "\(dateString)\n\(typeString)"
        let attr = NSMutableAttributedString(string: full)
        let fullRange = NSRange(location: 0, length: attr.length)
        attr.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(16, weight: UIFontWeightRegular), range: fullRange)
        attr.addAttribute(NSForegroundColorAttributeName, value: UIColor.appBlackColor(), range: fullRange)
        let typeRange = full.rangeString(typeString)
        attr.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(12, weight: UIFontWeightRegular), range: typeRange)
        attr.addAttribute(NSForegroundColorAttributeName, value: UIColor.appLightTextColor(), range: typeRange)
        return NSAttributedString(attributedString: attr)
    }
}

// MARK: - UITableViewDelegate
extension HistoryViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let recordController = AddRecordViewController()
        recordController.record = fetchedResultsController.objectAtIndexPath(indexPath) as? Record
        let nav = SHStatusBarNavigationController(rootViewController: recordController)
        nav.statusBarStyle = .Default
        nav.modalPresentationStyle = .FormSheet
        presentViewController(nav, animated: true, completion: nil)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension HistoryViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
            }
        case .Delete:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        case .Move:
            if let indexPath = indexPath, newIndexPath = newIndexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
            }
        case .Update:
            if let indexPath = indexPath {
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }
    }
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        case .Update:
            tableView.reloadSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        case .Move:
            break
        }
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
        configureStatsView()
    }
}
