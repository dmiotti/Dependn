//
//  ViewController.swift
//  SmokeReporter
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SnapKit
import CoreData
import SwiftHelpers
import PKHUD
import CocoaLumberjackSwift

final class HistoryViewController: UIViewController {
    
    private var actionBtn: UIBarButtonItem!
    private var statsBtn: UIBarButtonItem!
    private var tableView: UITableView!
    private var addBtn: UIButton!
    
    private var dateFormatter: NSDateFormatter!
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let controller = Smoke.historyFetchedResultsController()
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
        let cancelAction = UIAlertAction(
            title: L("cancel"), style: .Cancel,
            handler: nil)
        let exportAction = UIAlertAction(title: L("history.action.export"), style: .Default) { action in
            self.launchExport()
        }
        let importAction = UIAlertAction(title: L("history.action.import"), style: .Default) { action in
            self.launchImport()
        }
        alert.addAction(exportAction)
        alert.addAction(importAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func addBtnClicked(sender: UIButton) {
        let nav = UINavigationController(rootViewController: SmokeDetailViewController())
        presentViewController(nav, animated: true, completion: nil)
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
            let smoke = fetchedResultsController.objectAtIndexPath(indexPath) as! Smoke
            Smoke.deleteSmoke(smoke)
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
        let smoke = fetchedResultsController.objectAtIndexPath(indexPath) as! Smoke
        if let cell = cell as? HistoryTableViewCell {
            let type = smoke.smokeType
            cell.dateLbl.attributedText = attributedStringForDate(smoke.date, type: type)
            if type == .Cig {
                cell.circleTypeView.color = UIColor.appCigaretteColor()
                cell.circleTypeView.textLbl.text = "C"
            } else {
                cell.circleTypeView.color = UIColor.appWeedColor()
                cell.circleTypeView.textLbl.text = "W"
            }
            cell.intensityLbl.text = "\(smoke.intensity.integerValue)"
        }
    }
    private func attributedStringForDate(date: NSDate, type: SmokeType) -> NSAttributedString {
        let dateString = dateFormatter.stringFromDate(date)
        let typeString = type == .Cig ? L("history.cig") : L("history.weed")
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
        
        let smoke = SmokeDetailViewController()
        smoke.smoke = fetchedResultsController.objectAtIndexPath(indexPath) as? Smoke
        let nav = UINavigationController(rootViewController: smoke)
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
