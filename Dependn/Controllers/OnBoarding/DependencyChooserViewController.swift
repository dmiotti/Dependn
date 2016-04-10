//
//  DependencyChooserViewController.swift
//  Dependn
//
//  Created by David Miotti on 03/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

struct SuggestedAddiction {
    var name: String
    var color: String
}
extension SuggestedAddiction: Comparable {}
func ==(lhs: SuggestedAddiction, rhs: SuggestedAddiction) -> Bool {
    return lhs.name == rhs.name
}
func >(lhs: SuggestedAddiction, rhs: SuggestedAddiction) -> Bool {
    return lhs.name > rhs.name
}
func <(lhs: SuggestedAddiction, rhs: SuggestedAddiction) -> Bool {
    return lhs.name < rhs.name
}

final class DependencyChooserViewController: UIViewController {
    
    private var cancelBtn: UIBarButtonItem!
    private var doneBtn: UIBarButtonItem!
    
    private var headerView: UIView!
    private var searchBar: UISearchBar!
    private var tableView: UITableView!
    
    private var proposedAddictions = [SuggestedAddiction]()
    private var selectedAddictions = [SuggestedAddiction]()
    private var searchResult = [SuggestedAddiction]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        navigationController?.navigationBar.tintColor = UIColor.appBlueColor()
        
        updateTitle(L("onboarding.addiction.title"), blueBackground: false)

        configureBarButtons()
        
        headerView = UIView()
        view.addSubview(headerView)
        tableView = UITableView(frame: .zero, style: .Grouped)
        view.addSubview(tableView)
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        
        configureHeaderView()
        configureTableView()
        configureSearchBar()
        
        tableView.tableHeaderView = searchBar
        
        registerNotificationObservers()
        
        fillWithData()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Create suggested addictions
    
    private func fillWithData() {
        proposedAddictions.appendContentsOf([
            SuggestedAddiction(name: L("suggested.addictions.tobacco"),     color: "#27A9F1"),
            SuggestedAddiction(name: L("suggested.addictions.alcohol"),     color: "#BD10E0"),
            SuggestedAddiction(name: L("suggested.addictions.cannabis"),    color: "#2DD7AA"),
            SuggestedAddiction(name: L("suggested.addictions.antidepressant"), color: "#16a085"),
            SuggestedAddiction(name: L("suggested.addictions.tranquilizer"), color: "#7f8c8d"),
            SuggestedAddiction(name: L("suggested.addictions.videogames"),  color: "#e67e22"),
            SuggestedAddiction(name: L("suggested.addictions.screentime"),  color: "#c0392b"),
            SuggestedAddiction(name: L("suggested.addictions.gambling"),    color: "#f1c40f"),
            SuggestedAddiction(name: L("suggested.addictions.sex"),         color: "#1abc9c"),
            SuggestedAddiction(name: L("suggested.addictions.food"),        color: "#2980b9"),
            SuggestedAddiction(name: L("suggested.addictions.heroin"),      color: "#8B572A"),
            SuggestedAddiction(name: L("suggested.addictions.mdma"),        color: "#BD10E0"),
            SuggestedAddiction(name: L("suggested.addictions.ecigarette"),  color: "#e74c3c"),
            SuggestedAddiction(name: L("suggested.addictions.sport"),       color: "#2c3e50")
        ])
    }
    
    // MARK: - Button Events
    
    func doneBtnClicked(sender: UIBarButtonItem) {
        let context = CoreDataStack.shared.managedObjectContext
        
        for add in selectedAddictions {
            do {
                let addiction = try Addiction.findOrInsertNewAddiction(add.name, inContext: context)
                addiction.color = add.color
            } catch let err as NSError {
                print("Error while inserting new addiction: \(err)")
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func cancelBtnClicked(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Configure UI Elements
    
    private func configureBarButtons() {
        cancelBtn = UIBarButtonItem(title: L("onboarding.addiction.cancel"), style: .Plain, target: self, action: #selector(DependencyChooserViewController.cancelBtnClicked(_:)))
        cancelBtn.setTitleTextAttributes(StyleSheet.cancelBtnAttrs, forState: .Normal)
        navigationItem.leftBarButtonItem = cancelBtn
        
        doneBtn = UIBarButtonItem(title: L("onboarding.addiction.done"), style: .Done, target: self, action: #selector(DependencyChooserViewController.doneBtnClicked(_:)))
        doneBtn.setTitleTextAttributes(StyleSheet.doneBtnAttrs, forState: .Normal)
        navigationItem.rightBarButtonItem = doneBtn
    }
    
    private func configureSearchBar() {
        searchBar.placeholder = L("search.placeholder")
        searchBar.autoresizingMask = .FlexibleWidth
        searchBar.delegate = self
        searchBar.tintColor = UIColor.appBlueColor()
        searchBar.searchBarStyle = .Minimal
        
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, UIColor.clearColor().CGColor)
        CGContextFillRect(context, rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        searchBar.backgroundImage = image
    }
    
    private func configureHeaderView() {
        headerView.backgroundColor = UIColor.appBlueColor()
        
        let headerLbl = UILabel()
        headerLbl.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        headerLbl.text = L("onboarding.select_dependencies")
        headerLbl.numberOfLines = 0
        headerLbl.adjustsFontSizeToFitWidth = true
        headerLbl.textColor = UIColor.whiteColor()
        headerView.addSubview(headerLbl)
        
        headerLbl.snp_makeConstraints {
            $0.edges.equalTo(headerView).offset(
                UIEdgeInsets(top: 20, left: 20,
                    bottom: -20, right: -20))
        }
        
        headerView.snp_makeConstraints {
            $0.top.equalTo(view)
            $0.left.equalTo(view)
            $0.right.equalTo(view)
            $0.height.equalTo(78)
        }
    }
    
    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.registerClass(NewAddictionTableViewCell.self, forCellReuseIdentifier: NewAddictionTableViewCell.reuseIdentifier)
        tableView.registerClass(DependencyChooserCell.self, forCellReuseIdentifier: DependencyChooserCell.reuseIdentifier)
        view.addSubview(tableView)
        
        tableView.snp_makeConstraints {
            $0.top.equalTo(headerView.snp_bottom)
            $0.left.equalTo(view)
            $0.right.equalTo(view)
            $0.bottom.equalTo(view)
        }
    }
    
    // MARK: - Notifications
    
    private func registerNotificationObservers() {
        let ns = NSNotificationCenter.defaultCenter()
        ns.addObserver(self, selector: #selector(DependencyChooserViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        ns.addObserver(self, selector: #selector(DependencyChooserViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
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
    
    // MARK: - Add new Addiction
    
    private func addNewAddiction() {
        let alert = UIAlertController(title: L("addiction_list.new.title"), message: L("addiction_list.new.message"), preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: L("addiction_list.new.cancel"), style: .Cancel, handler: nil)
        let addAction = UIAlertAction(title: L("addiction_list.new.add"), style: .Default) { action in
            if let name = alert.textFields?.first?.text {
                let addiction = SuggestedAddiction(name: name, color: UIColor.randomFlatColor().hexValue())
                self.proposedAddictions.append(addiction)
                self.selectedAddictions.append(addiction)
                let idxPath = NSIndexPath(forRow: self.proposedAddictions.count - 1, inSection: 0)
                self.tableView.insertRowsAtIndexPaths([idxPath], withRowAnimation: .Automatic)
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

// MARK: - UITableViewDataSource
extension DependencyChooserViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return proposedAddictions.count
        }
        return 1
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(DependencyChooserCell.reuseIdentifier, forIndexPath: indexPath) as! DependencyChooserCell
            let addiction = proposedAddictions[indexPath.row]
            cell.addiction = addiction
            cell.choosen = selectedAddictions.contains(addiction)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(NewAddictionTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! NewAddictionTableViewCell
            return cell
        }
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 55
    }
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 {
            return 50.0
        }
        return 0
    }
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

// MARK: - UITableViewDelegate
extension DependencyChooserViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 0 {
            let addiction = proposedAddictions[indexPath.row]
            if let idx = selectedAddictions.indexOf(addiction) {
                selectedAddictions.removeAtIndex(idx)
            } else {
                selectedAddictions.append(addiction)
            }
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        } else {
            addNewAddiction()
        }
    }
}

// MARK: - UISearchBarDelegate
extension DependencyChooserViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
//        let pattrn: String? = searchText.characters.count > 0 ? searchText : nil
//        performSearch(pattrn)
    }
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
}
