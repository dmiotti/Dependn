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
    let name: String
    let color: String
    let addiction: Addiction?
    
    init(addiction: Addiction) {
        self.name = addiction.name
        self.color = addiction.color
        self.addiction = addiction
    }
    
    init(name: String, color: String) {
        self.name = name
        self.color = color
        self.addiction = nil
    }
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

enum DependencyChooserStyle {
    case onboarding
    case fromSettings
    case fromAddRecord
}

final class DependencyChooserViewController: SHNoBackButtonTitleViewController {
    
    var style: DependencyChooserStyle = .onboarding {
        didSet {
            if isViewLoaded {
                configureInterfaceBasedOnStyle()
            }
        }
    }
    
    fileprivate var cancelBtn: UIBarButtonItem!
    fileprivate var doneBtn: UIBarButtonItem!
    
    fileprivate var headerView: UIView!
    fileprivate var searchBar: UISearchBar!
    fileprivate var tableView: UITableView!
    
    fileprivate var proposedAddictions = [SuggestedAddiction]()
    fileprivate var selectedAddictions = [SuggestedAddiction]()
    
    fileprivate var isSearching: Bool {
        return searchedResult.count > 0
    }
    fileprivate var searchedResult = [SuggestedAddiction]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView = UIView()
        view.addSubview(headerView)
        tableView = UITableView(frame: .zero, style: .grouped)
        view.addSubview(tableView)
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        
        configureHeaderView()
        configureTableView()
        configureSearchBar()
        
        tableView.tableHeaderView = searchBar
        
        registerNotificationObservers()
        
        fillWithData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureInterfaceBasedOnStyle()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Create suggested addictions
    
    fileprivate func fillWithData() {
        var suggestions = [
            SuggestedAddiction(name: L("suggested.addictions.tobacco"), color: "#27A9F1"),
            SuggestedAddiction(name: L("suggested.addictions.alcohol"), color: "#BD10E0"),
            SuggestedAddiction(name: L("suggested.addictions.cannabis"), color: "#2DD7AA"),
            SuggestedAddiction(name: L("suggested.addictions.antidepressant"), color: "#16a085"),
            SuggestedAddiction(name: L("suggested.addictions.tranquilizer"), color: "#7f8c8d"),
            SuggestedAddiction(name: L("suggested.addictions.videogames"), color: "#e67e22"),
            SuggestedAddiction(name: L("suggested.addictions.screentime"), color: "#c0392b"),
            SuggestedAddiction(name: L("suggested.addictions.gambling"), color: "#f1c40f"),
            SuggestedAddiction(name: L("suggested.addictions.sex"), color: "#1abc9c"),
            SuggestedAddiction(name: L("suggested.addictions.food"), color: "#2980b9"),
            SuggestedAddiction(name: L("suggested.addictions.heroin"), color: "#8B572A"),
            SuggestedAddiction(name: L("suggested.addictions.mdma"), color: "#BD10E0"),
            SuggestedAddiction(name: L("suggested.addictions.ecigarette"), color: "#e74c3c"),
            SuggestedAddiction(name: L("suggested.addictions.sport"), color: "#2c3e50"),
            SuggestedAddiction(name: L("suggested.addictions.work"), color: "#52B3D9")
        ]
        
        if let currentAddictions = try? Addiction.getAllAddictions(inContext: CoreDataStack.shared.managedObjectContext) {
            let names = suggestions.map({ $0.name })
            let missingAddictions = currentAddictions.filter { names.contains($0.name) }
            suggestions.append(contentsOf: missingAddictions.map(SuggestedAddiction.init))
        }
        
        proposedAddictions = suggestions
    }
    
    // MARK: - Button Events
    
    func doneBtnClicked(_ sender: UIBarButtonItem) {
        let context = CoreDataStack.shared.managedObjectContext
        
        do {
            var newAddictions = [Addiction]()
            for add in selectedAddictions {
                let addiction = try Addiction.findOrInsertNewAddiction(add.name, inContext: context)
                addiction.color = add.color
                newAddictions.append(addiction)
            }
            
            /// Track selected addictions
            Analytics.instance.trackSelectAddictions(newAddictions)
        } catch let err as NSError {
            print("Error while inserting new addiction: \(err)")
        }
        
        switch style {
        case .onboarding:
            dismiss(animated: true, completion: nil)
        default:
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    func cancelBtnClicked(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Configure UI Elements
    
    fileprivate func configureInterfaceBasedOnStyle() {
        switch style {
        case .onboarding:
            navigationController?.setNavigationBarHidden(false, animated: true)
            navigationController?.navigationBar.barTintColor = UIColor.white
            navigationController?.navigationBar.tintColor = UIColor.appBlueColor()
            
            updateTitle(L("onboarding.addiction.title"), blueBackground: false)
            
            cancelBtn = UIBarButtonItem(title: L("onboarding.addiction.cancel"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(DependencyChooserViewController.cancelBtnClicked(_:)))
            cancelBtn.setTitleTextAttributes(StyleSheet.cancelBtnAttrs, for: UIControlState())
            navigationItem.leftBarButtonItem = cancelBtn
            
            doneBtn = UIBarButtonItem(title: L("onboarding.addiction.done"),
                                      style: .done,
                                      target: self,
                                      action: #selector(DependencyChooserViewController.doneBtnClicked(_:)))
            doneBtn.setTitleTextAttributes(StyleSheet.doneBtnAttrs, for: UIControlState())
            navigationItem.rightBarButtonItem = doneBtn
        case .fromSettings:
            updateTitle(L("onboarding.addiction.title"), blueBackground: true)
            
            doneBtn = UIBarButtonItem(title: L("onboarding.addiction.done"),
                                      style: .done,
                                      target: self,
                                      action: #selector(DependencyChooserViewController.doneBtnClicked(_:)))
            doneBtn.setTitleTextAttributes([
                NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightSemibold),
                NSForegroundColorAttributeName: UIColor.white,
                NSKernAttributeName: -0.36
                ], for: UIControlState())
            navigationItem.rightBarButtonItem = doneBtn
        case .fromAddRecord:
            updateTitle(L("onboarding.addiction.title"), blueBackground: false)
            
            doneBtn = UIBarButtonItem(title: L("onboarding.addiction.done"),
                                      style: .done,
                                      target: self,
                                      action: #selector(DependencyChooserViewController.doneBtnClicked(_:)))
            doneBtn.setTitleTextAttributes(StyleSheet.doneBtnAttrs, for: UIControlState())
            navigationItem.rightBarButtonItem = doneBtn
        }
    }
    
    fileprivate func configureSearchBar() {
        searchBar.placeholder = L("search.placeholder")
        searchBar.autoresizingMask = .flexibleWidth
        searchBar.delegate = self
        searchBar.tintColor = UIColor.appBlueColor()
        searchBar.searchBarStyle = .minimal
        
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        searchBar.backgroundImage = image
    }
    
    fileprivate func configureHeaderView() {
        headerView.backgroundColor = UIColor.appBlueColor()
        
        let headerLbl = UILabel()
        headerLbl.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        headerLbl.text = L("onboarding.select_dependencies")
        headerLbl.numberOfLines = 0
        headerLbl.adjustsFontSizeToFitWidth = true
        headerLbl.textColor = UIColor.white
        headerView.addSubview(headerLbl)
        
        headerLbl.snp.makeConstraints {
            $0.edges.equalTo(headerView).inset(UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        }
        
        headerView.snp.makeConstraints {
            $0.top.equalTo(view)
            $0.left.equalTo(view)
            $0.right.equalTo(view)
            $0.height.equalTo(78)
        }
    }
    
    fileprivate func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.register(NewAddictionTableViewCell.self, forCellReuseIdentifier: NewAddictionTableViewCell.reuseIdentifier)
        tableView.register(DependencyChooserCell.self, forCellReuseIdentifier: DependencyChooserCell.reuseIdentifier)
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.left.equalTo(view)
            $0.right.equalTo(view)
            $0.bottom.equalTo(view)
        }
    }
    
    // MARK: - Notifications
    
    fileprivate func registerNotificationObservers() {
        let ns = NotificationCenter.default
        ns.addObserver(self, selector: #selector(DependencyChooserViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        ns.addObserver(self, selector: #selector(DependencyChooserViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
    
    // MARK: - Add new Addiction
    
    fileprivate func addNewAddiction() {
        let alert = UIAlertController(title: L("addiction_list.new.title"), message: L("addiction_list.new.message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: L("addiction_list.new.cancel"), style: .cancel, handler: nil)
        let addAction = UIAlertAction(title: L("addiction_list.new.add"), style: .default) { action in
            if let name = alert.textFields?.first?.text {
                self.addAddiction(name: name)
            } else {
                UIAlertController.presentAlert(title: L("addiction_list.new.error"), message: L("addiction_list.new.name_missing"), in: self)
            }
        }
        alert.addTextField { textField in
            textField.placeholder = L("addiction_list.new.placeholder")
            textField.autocapitalizationType = .words
        }
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func addAddiction(name: String) {
        do {
            let ctx = CoreDataStack.shared.managedObjectContext
            let addiction = try Addiction.findOrInsertNewAddiction(name, inContext: ctx)
            Analytics.instance.trackAddAddiction(addiction)
            let suggestedAddiction = SuggestedAddiction(addiction: addiction)
            self.proposedAddictions.append(suggestedAddiction)
            self.selectedAddictions.append(suggestedAddiction)
            self.tableView.beginUpdates()
            let indexPath = IndexPath(row: self.proposedAddictions.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            self.tableView.endUpdates()
        } catch let err as NSError {
            UIAlertController.present(error: err, in: self)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}

// MARK: - UITableViewDataSource
extension DependencyChooserViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if isSearching {
                return searchedResult.count
            }
            return proposedAddictions.count
        }
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: DependencyChooserCell.reuseIdentifier, for: indexPath) as! DependencyChooserCell
            let addiction: SuggestedAddiction
            if isSearching {
                addiction = searchedResult[indexPath.row]
            } else {
                addiction = proposedAddictions[indexPath.row]
            }
            cell.addiction = addiction
            cell.choosen = selectedAddictions.contains(addiction)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: NewAddictionTableViewCell.reuseIdentifier, for: indexPath) as! NewAddictionTableViewCell
            return cell
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 {
            return 50.0
        }
        return 0
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

// MARK: - UITableViewDelegate
extension DependencyChooserViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let addiction: SuggestedAddiction
            if isSearching {
                addiction = searchedResult[indexPath.row]
            } else {
                addiction = proposedAddictions[indexPath.row]
            }
            if let idx = selectedAddictions.index(of: addiction) {
                selectedAddictions.remove(at: idx)
            } else {
                selectedAddictions.append(addiction)
            }
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        } else {
            addNewAddiction()
        }
    }
}

// MARK: - UISearchBarDelegate
extension DependencyChooserViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchedResult = proposedAddictions.filter {
            $0.name.contains(searchText)
        }
        self.tableView.reloadData()
    }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        searchedResult = []
    }
}
