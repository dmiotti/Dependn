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

final class AddictionListViewController: SHNoBackButtonTitleViewController {
    
    fileprivate var tableView: UITableView!
    fileprivate var addBtn: UIBarButtonItem!
    fileprivate var editBtn: UIBarButtonItem!
    
    fileprivate let managedObjectContext = CoreDataStack.shared.managedObjectContext
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Addiction> = { () -> NSFetchedResultsController<Addiction> in
        let req = NSFetchRequest<Addiction>(entityName: Addiction.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        let controller = NSFetchedResultsController<Addiction>(fetchRequest: req, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = []
        
        updateTitle(L("addiction_list.title"))
        
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.rowHeight = 55
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AddictionTableViewCell.self, forCellReuseIdentifier: AddictionTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
        
        addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(AddictionListViewController.addBtnClicked(_:)))
        navigationItem.rightBarButtonItem = addBtn
        
        registerNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        launchFetchIfNeeded()
    }
    
    // MARK: - Data Fetch
    
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
    
    func addBtnClicked(_ sender: UIBarButtonItem) {
        let chooser = DependencyChooserViewController()
        chooser.style = .fromSettings
        navigationController?.pushViewController(chooser, animated: true)
    }
    
    // MARK: - Add/Delete from CoreData
    
    fileprivate func deleteAddiction(_ addiction: Addiction) {
        let title = String(format: L("addiction_list.delete.title"), addiction.name.capitalized)
        let reason = String(format: L("addiction_list.delete.message"), addiction.name.capitalized)
        let alert = UIAlertController(title: title, message: reason, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: L("addiction_list.delete.cancel"), style: .default, handler: nil)
        let okAction = UIAlertAction(title: L("addiction_list.delete.confirm"), style: .default) { action in
            do {
                try Addiction.deleteAddiction(addiction, inContext: self.managedObjectContext)
            } catch let err as NSError {
                UIAlertController.present(error: err, in: self)
            }
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Keyboard Notifications
    
    fileprivate func registerNotificationObservers() {
        let ns = NotificationCenter.default
        ns.addObserver(self, selector: #selector(AddictionListViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        ns.addObserver(self, selector: #selector(AddictionListViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(_ notification: Notification) {
        let scrollViewRect = view.convert(tableView.frame, from: tableView.superview)
        if let rectValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let kbRect = view.convert(rectValue.cgRectValue, from: nil)
            
            let hiddenScrollViewRect = scrollViewRect.intersection(kbRect)
            if !hiddenScrollViewRect.isNull {
                var contentInsets = tableView.contentInset
                contentInsets.bottom = hiddenScrollViewRect.size.height
                tableView.contentInset = contentInsets
                tableView.scrollIndicatorInsets = contentInsets
            }
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        var contentInsets = tableView.contentInset
        contentInsets.bottom = 0
        tableView.contentInset = contentInsets
        tableView.scrollIndicatorInsets = contentInsets
    }
    
}

// MARK: - UITableViewDataSource
extension AddictionListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AddictionTableViewCell.reuseIdentifier, for: indexPath) as! AddictionTableViewCell
        cell.addiction = fetchedResultsController.object(at: indexPath)
        return cell
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let addiction = fetchedResultsController.object(at: indexPath)
            self.deleteAddiction(addiction)
        }
    }
}

// MARK: - UITableViewDelegate
extension AddictionListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        updateNameOfAddictionAtIndexPath(indexPath)
    }
    fileprivate func updateNameOfAddictionAtIndexPath(_ indexPath: IndexPath) {
        let addiction = fetchedResultsController.object(at: indexPath)
        let alert = UIAlertController(title: L("addiction_list.modify.title"), message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: L("cancel"), style: .cancel, handler: nil)
        let addAction = UIAlertAction(title: L("addiction_list.modify"), style: .default) { action in
            if let name = alert.textFields?.first?.text {
                addiction.name = name
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            } else {
                UIAlertController.presentAlert(title: L("addiction_list.new.error"), message: L("addiction_list.new.name_missing"), in: self)
            }
        }
        alert.addTextField { textField in
            textField.placeholder = L("addiction_list.modify.placeholder")
            textField.text = addiction.name.capitalized
        }
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension AddictionListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
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
        tableView.endUpdates()
    }
}
