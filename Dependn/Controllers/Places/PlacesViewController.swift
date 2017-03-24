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
import PKHUD
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol PlacesViewControllerDelegate {
    func placeController(_ controller: PlacesViewController, didChoosePlace place: Place?)
}

enum PlacesSectionType: Int {
    case recentPlaces
    case places
}

final class PlacesViewController: UIViewController {
    
    var delegate: PlacesViewControllerDelegate?
    
    fileprivate var tableView: UITableView!
    fileprivate var addBbi: UIBarButtonItem!
    
    fileprivate var searchBar: UISearchBar!
    
    fileprivate var suggestedFRC: NSFetchedResultsController<NSFetchRequestResult>?
    fileprivate var recentFRC: NSFetchedResultsController<NSFetchRequestResult>?
    
    fileprivate var sections = [PlacesSectionType]()
    
    fileprivate let managedObjectContext = CoreDataStack.shared.managedObjectContext
    
    var selectedPlace: Place?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = UIRectEdge()
        
        updateTitle(L("places.title"), blueBackground: false)
        
        let containerSearchBar = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 54))
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 44))
        containerSearchBar.addSubview(searchBar)
        searchBar.snp.makeConstraints {
            $0.bottom.equalTo(containerSearchBar)
            $0.left.equalTo(containerSearchBar)
            $0.right.equalTo(containerSearchBar)
            $0.height.equalTo(44)
        }
        configureSearchBar()

        tableView = UITableView(frame: .zero, style: .plain)
        tableView.contentInset = UIEdgeInsets(top: -10, left: 0, bottom: 0, right: 0)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.rowHeight = 55
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PlaceCell.self, forCellReuseIdentifier: PlaceCell.reuseIdentifier)
        tableView.tableHeaderView = containerSearchBar
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }

        addBbi = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(PlacesViewController.addBtnClicked(_:)))
        addBbi.tintColor = UIColor.appBlueColor()
        navigationItem.rightBarButtonItem = addBbi
        
        registerNotificationObservers()
    }

    fileprivate var placesLoaded = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !placesLoaded {
            placesLoaded = true
            preparePlaces()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate func preparePlaces() {
        do {
            let places = try Place.allPlaces(inContext: CoreDataStack.shared.managedObjectContext)
            if places.count == 0 && InitialImportPlacesOperation.shouldImportPlaces() {
                let queue = OperationQueue()
                let op = InitialImportPlacesOperation { op in
                    DispatchQueue.main.async {
                        self.performSearch(nil)
                    }
                }
                queue.addOperation(op)
            } else {
                performSearch(nil)
            }
        } catch let err as NSError {
            print("Error while fetching places: \(err)")
            performSearch(nil)
        }
    }
    
    func addBtnClicked(_ sender: UIButton) {
        let alert = UIAlertController(title: L("places.new.title"), message: L("places.new.message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: L("places.new.cancel"), style: .cancel, handler: nil)
        let addAction = UIAlertAction(title: L("places.new.add"), style: .default) { action in
            if let name = alert.textFields?.first?.text, name.characters.count > 0 {
                self.addPlace(name)
            } else {
                UIAlertController.presentAlert(title: L("places.new.error"), message: L("places.new.name_missing"), in: self)
            }
        }
        alert.addTextField { textField in
            textField.placeholder = L("places.new.placeholder")
            textField.autocapitalizationType = .sentences
        }
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Configure SearchBar
    
    fileprivate func configureSearchBar() {
        searchBar.placeholder = L("search.placeholder")
        searchBar.autoresizingMask = .flexibleWidth
        searchBar.delegate = self
        
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        searchBar.backgroundImage = image
        
        searchBar.tintColor = UIColor.appBlueColor()
        searchBar.searchBarStyle = .minimal
    }
    
    fileprivate func performSearch(_ searchText: String?) {
        do {
            recentFRC = Place.recentPlacesFRC(inContext: managedObjectContext, forSearch: searchText)
            recentFRC?.delegate = self
            
            suggestedFRC = Place.suggestedPlacesFRC(inContext: managedObjectContext, forSearch: searchText)
            suggestedFRC?.delegate = self
            
            try recentFRC?.performFetch()
            try suggestedFRC?.performFetch()
            
            sections.removeAll()
            
            if recentFRC?.fetchedObjects?.count > 0 {
                sections.append(.recentPlaces)
            }
            
            if suggestedFRC?.fetchedObjects?.count > 0 {
                sections.append(.places)
            }
            
            tableView.reloadData()
        } catch let err as NSError {
            print("Error while search place with \(String(describing: searchText)): \(err)")
        }
    }
    
    // MARK: - Add/Delete from CoreData
    
    fileprivate func addPlace(_ name: String) {
        selectedPlace = nil
        
        let place = Place.insertPlace(name, inContext: CoreDataStack.shared.managedObjectContext)
        
        Analytics.instance.trackAddPlace(name)
        
        delegate?.placeController(self, didChoosePlace: place)
    }
    
    fileprivate func deletePlace(_ place: Place) {
        let title = String(format: L("places.delete.title"), place.name.capitalized)
        let reason = String(format: L("places.delete.message"), place.name.capitalized)
        let alert = UIAlertController(title: title, message: reason, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: L("places.delete.cancel"), style: .default, handler: nil)
        let okAction = UIAlertAction(title: L("places.delete.confirm"), style: .default) { action in
            Place.deletePlace(place, inContext: CoreDataStack.shared.managedObjectContext)
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard Notifications
    
    fileprivate func registerNotificationObservers() {
        let ns = NotificationCenter.default
        ns.addObserver(self, selector: #selector(PlacesViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        ns.addObserver(self, selector: #selector(PlacesViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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

// MARK: - UITableViewDelegate
extension PlacesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        delegate?.placeController(self, didChoosePlace: placeAtIndexPath(indexPath))
    }
}

// MARK: - UITableViewDataSource
extension PlacesViewController: UITableViewDataSource {
    fileprivate func placeAtIndexPath(_ indexPath: IndexPath) -> Place {
        let place: Place
        let section = sections[indexPath.section]
        switch section {
        case .recentPlaces:
            place = recentFRC?.fetchedObjects?[indexPath.row] as! Place
        case .places:
            place = suggestedFRC?.fetchedObjects?[indexPath.row] as! Place
        }
        return place
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        switch section {
        case .recentPlaces:
            return recentFRC?.fetchedObjects?.count ?? 0
        case .places:
            return suggestedFRC?.fetchedObjects?.count ?? 0
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaceCell.reuseIdentifier, for: indexPath) as! PlaceCell
        let place = placeAtIndexPath(indexPath)
        cell.placeLbl.text = place.name.firstLetterCapitalization
        cell.accessoryType = selectedPlace == place ? .checkmark : .none
        return cell
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deletePlace(placeAtIndexPath(indexPath))
        }
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard sections.count > 1 else {
            return nil
        }
        
        let header = TableHeaderView()
        
        let type = sections[section]
        switch type {
        case .recentPlaces:
            header.title = L("places.recent_places").uppercased()
        case .places:
            header.title = L("places.suggested_places").uppercased()
        }
        
        return header
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard sections.count > 1 else {
            return 0
        }
        return 40
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension PlacesViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let section = sectionForFRC(controller) else {
            return
        }
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                let translated = IndexPath(row: newIndexPath.row, section: section)
                tableView.insertRows(at: [translated], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath {
                let translated = IndexPath(row: indexPath.row, section: section)
                tableView.deleteRows(at: [translated], with: .automatic)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                let translatedDelete = IndexPath(row: indexPath.row, section: section)
                let translatedNew = IndexPath(row: newIndexPath.row, section: section)
                
                tableView.deleteRows(at: [translatedDelete], with: .automatic)
                tableView.insertRows(at: [translatedNew], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath {
                let translated = IndexPath(row: indexPath.row, section: section)
                tableView.reloadRows(at: [translated], with: .automatic)
            }
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    fileprivate func sectionForFRC(_ controller: NSFetchedResultsController<NSFetchRequestResult>) -> Int? {
        if controller == recentFRC {
            return sections.index(of: .recentPlaces)
        }
        return sections.index(of: .places)
    }
}

// MARK: - UISearchBarDelegate
extension PlacesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let pattrn: String? = searchText.characters.count > 0 ? searchText : nil
        performSearch(pattrn)
    }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
}
