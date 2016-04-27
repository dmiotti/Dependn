//
//  SearchAdditionViewController.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import CoreData
import SwiftHelpers

protocol SearchAdditionViewControllerDelegate {
    func searchController(searchController: SearchAdditionViewController, didSelectAddiction addiction: Addiction)
}

final class SearchAdditionViewController: UIViewController {
    
    private var searchResults = [Addiction]()
    
    var delegate: SearchAdditionViewControllerDelegate?
    var selectedAddiction: Addiction? {
        didSet {
            if let addiction = selectedAddiction {
                delegate?.searchController(self, didSelectAddiction: addiction)
            }
        }
    }
    
    private let managedObjectContext = CoreDataStack.shared.managedObjectContext
    
    private var searchBar: UISearchBar!
    
    private var fetchedResultsController: NSFetchedResultsController?
    
    private var tableView: UITableView!
    
    var useBlueNavigationBar: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = .None
        
        updateTitle(L("addiction_list.title"), blueBackground: useBlueNavigationBar)
        
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 44))
        configureSearchBar()
      
        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.registerClass(NewAddictionTableViewCell.self, forCellReuseIdentifier: NewAddictionTableViewCell.reuseIdentifier)
        tableView.registerClass(AddictionTableViewCell.self, forCellReuseIdentifier: AddictionTableViewCell.reuseIdentifier)
        tableView.tableHeaderView = searchBar
        view.addSubview(tableView)
        
        configureLayoutConstraints()
        
        performSearch(nil)
        
        registerNotificationObservers()
    }
    
    private func configureSearchBar() {
        searchBar.placeholder = L("search.placeholder")
        searchBar.autoresizingMask = .FlexibleWidth
        searchBar.delegate = self
        
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, UIColor.clearColor().CGColor)
        CGContextFillRect(context, rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        searchBar.backgroundImage = image
        
        searchBar.tintColor = UIColor.appBlueColor()
        searchBar.searchBarStyle = .Minimal
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func configureLayoutConstraints() {
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    private func performSearch(searchText: String?) {
        do {
            let req = Addiction.entityFetchRequest()
            req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
            if let searchText = searchText {
                req.predicate = NSPredicate(format: "name contains[cd] %@", searchText)
            }
            fetchedResultsController = NSFetchedResultsController(fetchRequest: req, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController!.delegate = self
            try fetchedResultsController!.performFetch()
            tableView.reloadData()
        } catch let err as NSError {
            print("Error while search place with \(searchText): \(err)")
        }
    }
    
    private func registerNotificationObservers() {
        let ns = NSNotificationCenter.defaultCenter()
        ns.addObserver(self, selector: #selector(SearchAdditionViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        ns.addObserver(self, selector: #selector(SearchAdditionViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let scrollViewRect = view.convertRect(tableView.frame, fromView: tableView.superview)
        if let rectValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let kbRect = view.convertRect(rectValue.CGRectValue(), fromView: nil)
            
            let hiddenScrollViewRect = CGRectIntersection(scrollViewRect, kbRect)
            if !CGRectIsNull(hiddenScrollViewRect) {
                var contentInsets = tableView.contentInset
                contentInsets.bottom = hiddenScrollViewRect.size.height
                tableView.contentInset = contentInsets
                tableView.scrollIndicatorInsets = contentInsets
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        var contentInsets = tableView.contentInset
        contentInsets.bottom = 0
        tableView.contentInset = contentInsets
        tableView.scrollIndicatorInsets = contentInsets
    }

}

// MARK: - UITableViewDataSource
extension SearchAdditionViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (fetchedResultsController?.sections?.count ?? 0) + 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < fetchedResultsController?.sections?.count {
            return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
        }
        return 1
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section < fetchedResultsController?.sections?.count {
            let cell = tableView.dequeueReusableCellWithIdentifier(AddictionTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! AddictionTableViewCell
            if let addiction = fetchedResultsController?.objectAtIndexPath(indexPath) as? Addiction {
                cell.addiction = addiction
                cell.choosen = addiction == selectedAddiction
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(NewAddictionTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! NewAddictionTableViewCell
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension SearchAdditionViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 55
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section < fetchedResultsController?.sections?.count {
            if let addiction = fetchedResultsController?.objectAtIndexPath(indexPath) as? Addiction {
                selectedAddiction = addiction
                tableView.reloadData()
                delegate?.searchController(self, didSelectAddiction: addiction)
                navigationController?.popViewControllerAnimated(true)
            }
        } else {
            addNewAddiction()
        }
    }
    private func addNewAddiction() {
        let alert = UIAlertController(title: L("addiction_list.new.title"), message: L("addiction_list.new.message"), preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: L("addiction_list.new.cancel"), style: .Cancel, handler: nil)
        let addAction = UIAlertAction(title: L("addiction_list.new.add"), style: .Default) { action in
            if let name = alert.textFields?.first?.text {
                do {
                    let addiction = try Addiction.findOrInsertNewAddiction(name,
                        inContext: self.managedObjectContext)
                    self.searchBar.text = nil
                    self.selectedAddiction = addiction
                } catch let err as NSError {
                    UIAlertController.presentAlertWithTitle(err.localizedDescription,
                        message: err.localizedRecoverySuggestion, inController: self)
                }
            } else {
                UIAlertController.presentAlertWithTitle(L("addiction_list.new.error"),
                    message: L("addiction_list.new.name_missing"), inController: self)
            }
        }
        alert.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = L("addiction_list.new.placeholder")
            textField.autocapitalizationType = .Words
        }
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        presentViewController(alert, animated: true, completion: nil)
    }
}

// MARK: - UISearchBarDelegate
extension SearchAdditionViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        let pattrn: String? = searchText.characters.count > 0 ? searchText : nil
        performSearch(pattrn)
    }
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension SearchAdditionViewController: NSFetchedResultsControllerDelegate {
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
