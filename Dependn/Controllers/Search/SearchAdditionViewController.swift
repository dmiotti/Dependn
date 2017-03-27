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
    func searchController(_ searchController: SearchAdditionViewController, didSelectAddiction addiction: Addiction)
}

final class SearchAdditionViewController: SHNoBackButtonTitleViewController {
    
    fileprivate var searchResults = [Addiction]()
    
    var delegate: SearchAdditionViewControllerDelegate?
    var selectedAddiction: Addiction? {
        didSet {
            if let addiction = selectedAddiction {
                delegate?.searchController(self, didSelectAddiction: addiction)
            }
        }
    }
    
    fileprivate let managedObjectContext = CoreDataStack.shared.managedObjectContext
    
    fileprivate var searchBar: UISearchBar!
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Addiction> = {
        let req = Addiction.entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        let ctx = CoreDataStack.shared.managedObjectContext
        let controller = NSFetchedResultsController<Addiction>(fetchRequest: req, managedObjectContext: ctx, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        return controller
    }()
    
    fileprivate var tableView: UITableView!
    
    var useBlueNavigationBar: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = []
        
        updateTitle(L("addiction_list.title"), blueBackground: useBlueNavigationBar)
        
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 44))
        configureSearchBar()
      
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.register(NewAddictionTableViewCell.self, forCellReuseIdentifier: NewAddictionTableViewCell.reuseIdentifier)
        tableView.register(AddictionTableViewCell.self, forCellReuseIdentifier: AddictionTableViewCell.reuseIdentifier)
        tableView.tableHeaderView = searchBar
        view.addSubview(tableView)
        
        configureLayoutConstraints()
        
        performSearch(nil)
        
        registerNotificationObservers()
    }
    
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func configureLayoutConstraints() {
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    fileprivate func performSearch(_ searchText: String?) {
        do {
            let req = Addiction.entityFetchRequest()
            req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
            if let searchText = searchText {
                let predicate = NSPredicate(format: "name contains[cd] %@", searchText)
                fetchedResultsController.fetchRequest.predicate = predicate
            } else {
                fetchedResultsController.fetchRequest.predicate = nil
            }
            try fetchedResultsController.performFetch()
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        } catch let err as NSError {
            print("Error while search place with \(String(describing: searchText)): \(err)")
        }
    }
    
    fileprivate func registerNotificationObservers() {
        let ns = NotificationCenter.default
        ns.addObserver(self, selector: #selector(SearchAdditionViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        ns.addObserver(self, selector: #selector(SearchAdditionViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
extension SearchAdditionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return (fetchedResultsController.sections?.count ?? 0) + 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < fetchedResultsController.sections?.count {
            return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        }
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < fetchedResultsController.sections?.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: AddictionTableViewCell.reuseIdentifier, for: indexPath) as! AddictionTableViewCell
            let addiction = fetchedResultsController.object(at: indexPath)
            cell.addiction = addiction
            cell.choosen = addiction == selectedAddiction
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: NewAddictionTableViewCell.reuseIdentifier, for: indexPath) as! NewAddictionTableViewCell
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension SearchAdditionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section < fetchedResultsController.sections?.count {
            let addiction = fetchedResultsController.object(at: indexPath)
            selectedAddiction = addiction
            tableView.reloadData()
            delegate?.searchController(self, didSelectAddiction: addiction)
            _ = navigationController?.popViewController(animated: true)
        } else {
            addNewAddiction()
        }
    }
    fileprivate func addNewAddiction() {
        let chooser = DependencyChooserViewController()
        chooser.style = .fromAddRecord
        navigationController?.pushViewController(chooser, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension SearchAdditionViewController: UISearchBarDelegate {
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

// MARK: - NSFetchedResultsControllerDelegate
extension SearchAdditionViewController: NSFetchedResultsControllerDelegate {
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
