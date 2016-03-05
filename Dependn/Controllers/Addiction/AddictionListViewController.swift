//
//  AddictionListViewController.swift
//  Dependn
//
//  Created by David Miotti on 05/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData
import CocoaLumberjack

final class AddictionListViewController: UIViewController {
    
    private var tableView: UITableView!
    private var addBtn: UIBarButtonItem!
    private var editBtn: UIBarButtonItem!
    
    private let managedObjectContext = CoreDataStack.shared.managedObjectContext
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let req = Addiction.entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        let controller = NSFetchedResultsController(fetchRequest: req, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L("addiction_list.title")
        
        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(AddictionTableViewCell.self, forCellReuseIdentifier: AddictionTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
        
        addBtn = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addBtnClicked:")
        navigationItem.rightBarButtonItem = addBtn
        
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
            DDLogError("Error while perfoming fetch: \(err)")
            fetchExecuted = false
        }
    }
    
    func addBtnClicked(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: L("addiction_list.new.title"), message: L("addiction_list.new.message"), preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: L("addiction_list.new.cancel"), style: .Cancel, handler: nil)
        let addAction = UIAlertAction(title: L("addiction_list.new.add"), style: .Default) { action in
            if let name = alert.textFields?.first?.text {
                self.addAddictionWithName(name)
            } else {
                UIAlertController.presentAlertWithTitle(L("addiction_list.new.error"),
                    message: L("addiction_list.new.name_missing"), inController: self)
            }
        }
        alert.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = L("addiction_list.new.placeholder")
        }
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func addAddictionWithName(name: String) {
        do {
            try Addiction.findOrInsertNewAddiction(name,
                inContext: managedObjectContext)
        } catch let err as NSError {
            UIAlertController.presentAlertWithTitle(err.localizedDescription,
                message: err.localizedRecoverySuggestion, inController: self)
        }
    }
    
    private func configureLayoutConstraints() {
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
}

// MARK: - UITableViewDataSource
extension AddictionListViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(AddictionTableViewCell.reuseIdentifier, forIndexPath: indexPath)
        let addiction = fetchedResultsController.objectAtIndexPath(indexPath) as! Addiction
        cell.textLabel?.text = addiction.name.capitalizedString
        return cell
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let addiction = fetchedResultsController.objectAtIndexPath(indexPath) as! Addiction
            self.deleteAddiction(addiction)
        }
    }
    private func deleteAddiction(addiction: Addiction) {
        let title = String(format: L("addiction_list.delete.title"), addiction.name)
        let alert = UIAlertController(title: title, message: L("addiction_list.delete.message"), preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: L("addiction_list.delete.cancel"), style: .Default, handler: nil)
        let okAction = UIAlertAction(title: L("addiction_list.delete.confirm"), style: .Default) { action in
            do {
                try Addiction.deleteAddiction(addiction, inContext: self.managedObjectContext)
            } catch let err as NSError {
                UIAlertController.presentError(err, inController: self)
            }
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate
extension AddictionListViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension AddictionListViewController: NSFetchedResultsControllerDelegate {
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
