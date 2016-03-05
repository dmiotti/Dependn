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
    private var statsBtn: UIBarButtonItem!
    private var tableView: UITableView!
    private var addBtn: UIButton!
    
    private var dateFormatter: NSDateFormatter!
    
    private let managedObjectContext = CoreDataStack.shared.managedObjectContext
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let controller = Record.historyFetchedResultsController(inContext: self.managedObjectContext)
        controller.delegate = self
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L("app_name")
        
        dateFormatter = NSDateFormatter(dateFormat: "HH'h'mm")
        
        actionBtn = UIBarButtonItem(image: UIImage(named: "settings_icon"), style: .Plain, target: self, action: "actionBtnClicked:")
        navigationItem.leftBarButtonItem = actionBtn
        
        statsBtn = UIBarButtonItem(image: UIImage(named: "stats_icon"), style: .Plain, target: self, action: "statsBtnClicked:")
        navigationItem.rightBarButtonItem = statsBtn
        
        tableView = UITableView(frame: .zero, style: .Plain)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(HistoryTableViewCell.self,
            forCellReuseIdentifier: HistoryTableViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 120))
        view.addSubview(tableView)
        
        addBtn = UIButton(type: .System)
        addBtn.setImage(UIImage(named: "add")?.imageWithRenderingMode(.AlwaysOriginal), forState: .Normal)
        addBtn.addTarget(self, action: "addBtnClicked:", forControlEvents: .TouchUpInside)
        view.addSubview(addBtn)
        
        configureLayoutConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        launchFetchIfNeeded()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    // MARK: - Data Fetch
    
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
        let alert = UIAlertController(
            title: L("history.action.title"),
            message: L("history.action.message"),
            preferredStyle: .ActionSheet)
        let cancelAction = UIAlertAction(title: L("cancel"), style: .Cancel, handler: nil)
        let exportAction = UIAlertAction(title: L("history.action.export"), style: .Default) { action in
            self.launchExport()
        }
        let importAction = UIAlertAction(title: L("history.action.import"), style: .Default) { action in
            self.launchImport()
        }
        let settingsAction = UIAlertAction(title: L("history.action.settings"), style: .Default) { action in
            let settings = SettingsViewController()
            self.navigationController?.pushViewController(settings, animated: true)
        }
        alert.addAction(exportAction)
        alert.addAction(importAction)
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func addBtnClicked(sender: UIButton) {
        if ensureThereIsAddictions() {
            let nav = UINavigationController(rootViewController: RecordDetailViewController())
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
    
    func statsBtnClicked(sender: UIBarButtonItem) {
        let stats = StatsViewController()
        navigationController?.pushViewController(stats, animated: true)
    }
    
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
                        HUD.flash(HUDContentType.LabeledError(
                            title: err.localizedDescription,
                            subtitle: err.localizedRecoverySuggestion))
                    }
                } else {
                    HUD.flash(.Success)
                }
            }
        }
        queue.addOperation(importOp)
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
        let countLbl = UILabel()
        countLbl.text = fetchedResultsController.sections?[section].name.uppercaseString
        countLbl.font = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
        countLbl.textColor = "7D9BB8".UIColor
        header.addSubview(countLbl)
        if let numberOfObjects = fetchedResultsController.sections?[section].numberOfObjects {
            countLbl.text = "\(numberOfObjects)"
        } else {
            countLbl.text = nil
        }
        date.snp_makeConstraints {
            $0.left.equalTo(header).offset(15)
            $0.right.equalTo(countLbl.snp_left).offset(-15)
            $0.bottom.equalTo(header).offset(-6)
        }
        countLbl.snp_makeConstraints {
            $0.right.equalTo(header).offset(-15)
            $0.bottom.equalTo(header).offset(-6)
        }
        return header
    }
    private func configureCell(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) {
        let record = fetchedResultsController.objectAtIndexPath(indexPath) as! Record
        if let cell = cell as? HistoryTableViewCell {
            let addiction = record.addiction
            cell.dateLbl.attributedText = attributedStringForDate(record.date, addiction: addiction)
            cell.circleTypeView.color = addiction.color.UIColor
            if let first = addiction.name.capitalizedString.characters.first {
                cell.circleTypeView.textLbl.text = "\(first)"
            }
            cell.intensityLbl.text = "\(record.intensity.integerValue)"
        }
    }
    private func attributedStringForDate(date: NSDate, addiction: Addiction) -> NSAttributedString {
        let dateString = dateFormatter.stringFromDate(date)
        let typeString = addiction.name.capitalizedString
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
        
        let recordController = RecordDetailViewController()
        recordController.record = fetchedResultsController.objectAtIndexPath(indexPath) as? Record
        let nav = UINavigationController(rootViewController: recordController)
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
    }
}
