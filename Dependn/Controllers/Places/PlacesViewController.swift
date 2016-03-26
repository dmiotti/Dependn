//
//  PlacesViewController.swift
//  Dependn
//
//  Created by David Miotti on 22/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import CoreData
import SwiftHelpers
import CocoaLumberjack

protocol PlacesViewControllerDelegate {
    func placeController(controller: PlacesViewController, didChoosePlace place: Place?)
}

final class PlacesViewController: UIViewController {
    
    var delegate: PlacesViewControllerDelegate?
    
    private var tableView: UITableView!
    private var addBbi: UIBarButtonItem!
    
    private var searchBar: UISearchBar!
    
    private var fetchedResultsController: NSFetchedResultsController?
    private let managedObjectContext = CoreDataStack.shared.managedObjectContext
    
    var selectedPlace: Place?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = .None
        
        updateTitle(L("places.title"), blueBackground: false)
        
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 44))
        configureSearchBar()

        tableView = UITableView(frame: .zero, style: .Plain)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.rowHeight = 55
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(PlaceCell.self, forCellReuseIdentifier: PlaceCell.reuseIdentifier)
        tableView.tableHeaderView = searchBar
        view.addSubview(tableView)
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }

        addBbi = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(PlacesViewController.addBtnClicked(_:)))
        addBbi.tintColor = UIColor.appBlueColor()
        navigationItem.rightBarButtonItem = addBbi
        
        performSearch(nil)
        
        registerNotificationObservers()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func addBtnClicked(sender: UIButton) {
        let alert = UIAlertController(title: L("places.new.title"), message: L("places.new.message"), preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: L("places.new.cancel"), style: .Cancel, handler: nil)
        let addAction = UIAlertAction(title: L("places.new.add"), style: .Default) { action in
            if let name = alert.textFields?.first?.text {
                self.addPlace(name)
            } else {
                UIAlertController.presentAlertWithTitle(
                    L("places.new.error"), message: L("places.new.name_missing"), inController: self)
            }
        }
        alert.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = L("places.new.placeholder")
            textField.autocapitalizationType = .Sentences
        }
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Configure SearchBar
    
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
    
    private func performSearch(searchText: String?) {
        do {
            let req = Place.entityFetchRequest()
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
    
    // MARK: - Add/Delete from CoreData
    
    private func addPlace(name: String) {
        let place = Place.insertPlace(name, inContext: CoreDataStack.shared.managedObjectContext)
        self.delegate?.placeController(self, didChoosePlace: place)
    }
    
    private func deletePlace(place: Place) {
        let title = String(format: L("places.delete.title"), place.name.capitalizedString)
        let reason = String(format: L("places.delete.message"), place.name.capitalizedString)
        let alert = UIAlertController(title: title, message: reason, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: L("places.delete.cancel"), style: .Default, handler: nil)
        let okAction = UIAlertAction(title: L("places.delete.confirm"), style: .Default) { action in
            Place.deletePlace(place, inContext: CoreDataStack.shared.managedObjectContext)
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Keyboard Notifications
    
    private func registerNotificationObservers() {
        let ns = NSNotificationCenter.defaultCenter()
        ns.addObserver(self, selector: #selector(PlacesViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        ns.addObserver(self, selector: #selector(PlacesViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
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

// MARK: - UITableViewDelegate
extension PlacesViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let place = fetchedResultsController?.objectAtIndexPath(indexPath) as? Place
        delegate?.placeController(self, didChoosePlace: place)
    }
}

// MARK: - UITableViewDataSource
extension PlacesViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PlaceCell.reuseIdentifier, forIndexPath: indexPath) as! PlaceCell
        if let place = fetchedResultsController?.objectAtIndexPath(indexPath) as? Place {
            cell.placeLbl.text = place.name.firstLetterCapitalization
            cell.accessoryType = selectedPlace == place ? .Checkmark : .None
        }
        return cell
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if let place = fetchedResultsController?.objectAtIndexPath(indexPath) as? Place {
                self.deletePlace(place)
            }
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension PlacesViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
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
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}

// MARK: - UISearchBarDelegate
extension PlacesViewController: UISearchBarDelegate {
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
