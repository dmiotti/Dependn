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

final class HistoryViewController: UIViewController {
    
    private var addBtn: UIBarButtonItem!
    private var shareBtn: UIBarButtonItem!
    private var tableView: UITableView!
    
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
        
        addBtn = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addSmokeBtnClicked:")
        navigationItem.rightBarButtonItem = addBtn
        
        shareBtn = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "shareBtnClicked:")
        navigationItem.leftBarButtonItem = shareBtn
        
        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        tableView.registerClass(HistoryTableViewCell.self,
            forCellReuseIdentifier: HistoryTableViewCell.reuseIdentifier)
        
        configureLayoutConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        launchFetchIfNeeded()
    }
    
    // MARK: - Data Fetch
    
    private var fetchExecuted = false
    private func launchFetchIfNeeded() {
        if fetchExecuted { return }
        do {
            try fetchedResultsController.performFetch()
            fetchExecuted = true
        } catch let err as NSError {
            print("Error while perfoming fetch: \(err)")
            fetchExecuted = false
        }
    }

    // MARK: - Configure Layout Constraints
    
    private func configureLayoutConstraints() {
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    // MARK: - Add button handler
    
    func addSmokeBtnClicked(sender: UIBarButtonItem) {
        let nav = UINavigationController(rootViewController: SmokeDetailViewController())
        presentViewController(nav, animated: true, completion: nil)
    }
    
    func shareBtnClicked(sender: UIBarButtonItem) {
        HUD.show(.Progress)
        let queue = NSOperationQueue()
        
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
        
//        /// Import
//        if let csv = NSBundle.mainBundle().pathForResource("a", ofType: "csv") {
//            let importOp = ImportOperation(path: csv)
//            importOp.completionBlock = {
//                dispatch_async(dispatch_get_main_queue()) {
//                    HUD.hide(animated: true) { finished in
//                        if let err = importOp.error {
//                            HUD.flash(HUDContentType.Label(err.localizedDescription))
//                        } else {
//                            HUD.flash(.Success)
//                        }
//                    }
//                }
//            }
//            queue.addOperation(importOp)
//        }
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
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].name ?? nil
    }
    private func configureCell(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) {
        let smoke = fetchedResultsController.objectAtIndexPath(indexPath) as! Smoke
        if let cell = cell as? HistoryTableViewCell {
            cell.dateLbl.text = dateFormatter.stringFromDate(smoke.date)
            if smoke.normalizedKind == .Cigarette {
                cell.imgView.image = UIImage(named: "cigarette")
            } else {
                cell.imgView.image = UIImage(named: "joint")
            }
            cell.intensityLbl.text = "\(smoke.intensity.integerValue)"
        }
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
                tableView.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
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
