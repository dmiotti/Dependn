//
//  AddRecordViewController.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SnapKit
import SwiftHelpers
import CoreLocation
import SwiftyUserDefaults
import CocoaLumberjack

// MARK: - UIViewController
final class AddRecordViewController: SHNoBackButtonTitleViewController {
    
    fileprivate enum SectionType {
        case addiction
        case dateAndPlace
        case intensity
        case optionals
    }
    
    fileprivate enum RowType {
        case addiction
        case date
        case place
        case intensity
        case feelings
        case comments
    }
    
    fileprivate struct Section {
        var type: SectionType
        var items: [RowType]
    }
    
    /// Title segmented control
    fileprivate var segmentedControl: UISegmentedControl!
    
    /// User selected fields
    fileprivate var tableView: UITableView!
    
    fileprivate var cancelBtn: UIBarButtonItem!
    fileprivate var doneBtn: UIBarButtonItem!
    
    fileprivate let locationManager = CLLocationManager()
    fileprivate var userLocation: CLLocation?
    
    fileprivate var editingStep: RowType?
    
    var record: Record?
    
    fileprivate var sections = [Section]()
    
    // MARK: - Editing Record properties
    
    fileprivate var chosenDate = Date()
    fileprivate var chosenAddiction: Addiction!
    fileprivate var chosenPlace: Place?
    fileprivate var chosenIntensity: Float = 3
    fileprivate var chosenFeeling: String?
    fileprivate var chosenComment: String?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sections = [
            Section(type: .addiction, items: [ .addiction ]),
            Section(type: .dateAndPlace, items: [ .date, .place ]),
            Section(type: .intensity, items: [ .intensity ]),
            Section(type: .optionals, items: [ .feelings, .comments ])
        ]
        
        edgesForExtendedLayout = []
        
        segmentedControl = UISegmentedControl(items: [ L("new_record.conso"), L("new_record.desire") ])
        segmentedControl.setWidth(76, forSegmentAt: 0)
        segmentedControl.setWidth(76, forSegmentAt: 1)
        segmentedControl.selectedSegmentIndex = 0
        navigationItem.titleView = segmentedControl
        
        locationManager.delegate = self
        
        view.backgroundColor = UIColor.lightBackgroundColor()
        
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.tintColor = UIColor.appBlueColor()
        
        cancelBtn = UIBarButtonItem(title: L("new_record.cancel"), style: .plain, target: self, action: #selector(AddRecordViewController.cancelBtnClicked(_:)))
        cancelBtn.setTitleTextAttributes(StyleSheet.cancelBtnAttrs, for: UIControlState())
        navigationItem.leftBarButtonItem = cancelBtn
        
        let doneText = record != nil ? L("new_record.modify") : L("new_record.add_btn")
        doneBtn = UIBarButtonItem(title: doneText, style: .done, target: self, action: #selector(AddRecordViewController.addBtnClicked(_:)))
        doneBtn.setTitleTextAttributes(StyleSheet.doneBtnAttrs, for: UIControlState())
        navigationItem.rightBarButtonItem = doneBtn
        
        chosenAddiction = try! Addiction.getAllAddictionsOrderedByCount(inContext: CoreDataStack.shared.managedObjectContext).first
        
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.register(AddictionTableViewCell.self,    forCellReuseIdentifier: AddictionTableViewCell.reuseIdentifier)
        tableView.register(NewDateTableViewCell.self,      forCellReuseIdentifier: NewDateTableViewCell.reuseIdentifier)
        tableView.register(NewPlaceTableViewCell.self,     forCellReuseIdentifier: NewPlaceTableViewCell.reuseIdentifier)
        tableView.register(NewIntensityTableViewCell.self, forCellReuseIdentifier: NewIntensityTableViewCell.reuseIdentifier)
        tableView.register(NewTextTableViewCell.self,      forCellReuseIdentifier: NewTextTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
        
        configureLayoutConstraints()
        
        registerNotificationObservers()
        
        if Defaults[.useLocation] {
            launchLocationManager()
        }
        
        if let record = record {
            fillWithRecord(record)
        }
        
        setupBackBarButtonItem()
    }
    
    deinit {
        stopLocationManager()
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func fillWithRecord(_ record: Record) {
        chosenAddiction = record.addiction
        chosenIntensity = record.intensity.floatValue
        chosenDate      = record.date as Date
        chosenPlace     = record.place
        chosenFeeling   = record.feeling
        chosenComment   = record.comment
        segmentedControl.selectedSegmentIndex = record.desire.boolValue ? 1 : 0
    }
    
    fileprivate func configureLayoutConstraints() {
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    // MARK: Notifications
    
    fileprivate func registerNotificationObservers() {
        let ns = NotificationCenter.default
        ns.addObserver(self, selector: #selector(AddRecordViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        ns.addObserver(self, selector: #selector(AddRecordViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        ns.addObserver(self, selector: #selector(AddRecordViewController.coreDataContextDidChanged(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
    }
    
    // MARK: - Keyboard
    
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
    
    // MARK: - CoreData
    
    func coreDataContextDidChanged(_ notification: Notification) {
        print("CoreData did changed: \(notification.userInfo)")
    }
    
    // MARK: UIBarButtonItems
    
    func addBtnClicked(_ sender: UIBarButtonItem) {
        if let record = record {
            
            record.addiction = chosenAddiction
            record.intensity = chosenIntensity.number
            record.feeling   = chosenFeeling
            record.comment   = chosenComment
            record.date      = chosenDate
            record.place     = chosenPlace
            record.desire    = (segmentedControl.selectedSegmentIndex == 1).number
            
        } else {
            
            let isDesire = segmentedControl.selectedSegmentIndex == 1
            
            _ = Record.insertNewRecord(chosenAddiction,
                                       intensity: chosenIntensity,
                                       feeling: chosenFeeling,
                                       comment: chosenComment,
                                       place: chosenPlace,
                                       latitude: userLocation?.coordinate.latitude,
                                       longitude: userLocation?.coordinate.longitude,
                                       desire: isDesire,
                                       date: chosenDate,
                                       inContext: CoreDataStack.shared.managedObjectContext)
            
            Analytics.instance.trackAddNewRecord(
                chosenAddiction.name,
                place: chosenPlace?.name,
                intensity: chosenIntensity,
                conso: !isDesire,
                fromAppleWatch: false)
            
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }

        PushSchedulerOperation.schedule()
        
        dismiss(animated: true, completion: { finished in
            WatchSessionManager.sharedManager.updateApplicationContext()
        })
    }
    
    func cancelBtnClicked(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource
extension AddRecordViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let row = sections[indexPath.section].items[indexPath.row]
        switch row {
        case .addiction:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: AddictionTableViewCell.reuseIdentifier, for: indexPath) as! AddictionTableViewCell
            cell.addiction = chosenAddiction
            cell.accessoryType = .disclosureIndicator
            return cell
        case .date:
            let cell = tableView.dequeueReusableCell(withIdentifier: NewDateTableViewCell.reuseIdentifier, for: indexPath) as! NewDateTableViewCell
            cell.date = chosenDate
            cell.delegate = self
            return cell
        case .place:
            let cell = tableView.dequeueReusableCell(withIdentifier: NewPlaceTableViewCell.reuseIdentifier, for: indexPath) as! NewPlaceTableViewCell
            cell.chosenPlaceLbl.text = chosenPlace?.name.firstLetterCapitalization
            return cell
        case .intensity:
            let cell = tableView.dequeueReusableCell(withIdentifier: NewIntensityTableViewCell.reuseIdentifier, for: indexPath) as! NewIntensityTableViewCell
            cell.delegate = self
            cell.updateIntensityWithProgress(chosenIntensity / 10.0)
            return cell
        case .feelings:
            let cell = tableView.dequeueReusableCell(withIdentifier: NewTextTableViewCell.reuseIdentifier, for:
                indexPath) as! NewTextTableViewCell
            cell.descLbl.text = L("new_record.feeling")
            cell.contentLbl.text = chosenFeeling
            return cell
        case .comments:
            let cell = tableView.dequeueReusableCell(withIdentifier: NewTextTableViewCell.reuseIdentifier, for:
                indexPath) as! NewTextTableViewCell
            cell.descLbl.text = L("new_record.comment")
            cell.contentLbl.text = chosenComment
            return cell
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let type = sections[section].type
        switch type {
        case .addiction:
            return 20
        case .dateAndPlace:
            return 20
        case .intensity:
            return 40
        case .optionals:
            return 40
        }
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = TableHeaderView()
        
        let type = sections[section].type
        switch type {
        case .intensity:
            header.title = L("new_record.intensity").uppercased()
        case .optionals:
            header.title = L("new_record.optional").uppercased()
        case .addiction:
            break
        case .dateAndPlace:
            break
        }
        
        return header
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = sections[indexPath.section].type
        if row == .intensity {
            return 105.0
        }
        return 55.0
    }
}

// MARK: - UITableViewDelegate
extension AddRecordViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = sections[indexPath.section].items[indexPath.row]
        switch row {
        case .addiction:
            let controller = SearchAdditionViewController()
            controller.selectedAddiction = chosenAddiction
            controller.delegate = self
            navigationController?.pushViewController(controller, animated: true)
        case .date:
            break
        case .place:
            showPlaces()
        case .intensity:
            break
        case .feelings:
            editingStep = .feelings
            showTextRecord()
        case .comments:
            editingStep = .comments
            showTextRecord()
        }
    }
    fileprivate func showPlaces() {
        let places = PlacesViewController()
        places.delegate = self
        places.selectedPlace = chosenPlace
        navigationController?.pushViewController(places, animated: true)
    }
    fileprivate func showTextRecord() {
        let controller = AddRecordTextViewController()
        controller.delegate = self
        switch editingStep! {
        case .feelings:
            controller.updateTitle(L("new_record.feeling_subtitle"), blueBackground: false)
            controller.originalText = chosenFeeling
            if !Defaults[.hasSeenEmotionPlaceholder] {
                controller.placeholder = L("new_record.feeling_placeholder")
                Defaults[.hasSeenEmotionPlaceholder] = true
            }
        case .comments:
            controller.updateTitle(L("new_record.comment_subtitle"), blueBackground: false)
            controller.originalText = chosenComment
            controller.placeholder = L("new_record.comment_placeholder")
        default:
            break
        }
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK - SearchAdditionViewControllerDelegate
extension AddRecordViewController: SearchAdditionViewControllerDelegate {
    func searchController(_ searchController: SearchAdditionViewController, didSelectAddiction addiction: Addiction) {
        chosenAddiction = addiction
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }
}

// MARK - AddRecordTextViewControllerDelegate
extension AddRecordViewController: AddRecordTextViewControllerDelegate {
    func addRecordTextViewController(_ controller: AddRecordTextViewController, didEnterText text: String?) {
        switch editingStep! {
        case .feelings:
            chosenFeeling = text
        case .comments:
            chosenComment = text
        default:
            break
        }
        editingStep = nil
        
        tableView.reloadData()
    }
}

// MARK - CLLocationManagerDelegate
extension AddRecordViewController: CLLocationManagerDelegate {
    fileprivate func launchLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.stopUpdatingLocation()
        locationManager.startUpdatingLocation()
    }
    fileprivate func stopLocationManager() {
        locationManager.stopUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if record != nil || !Defaults[.useLocation] {
            return
        }
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            launchLocationManager()
        } else {
            stopLocationManager()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if record != nil || !Defaults[.useLocation] {
            return
        }
        
        guard let newLocation = locations.last else {
            return
        }
        
        userLocation = newLocation
        
        DDLogInfo("Location found \(newLocation)")
        
        if let location = userLocation, (chosenPlace == nil || chosenPlace?.name.characters.count == 0) {
            let op = NearestPlaceOperation(location: location, distance: 80)
            op.completionBlock = {
                DispatchQueue.main.async {
                    if let placeId = op.place?.objectID {
                        let moc = CoreDataStack.shared.managedObjectContext
                        let place = moc.object(with: placeId) as! Place
                        self.chosenPlace = place
                        self.reloadRows([.place])
                    }
                }
            }
            let queue = OperationQueue()
            queue.addOperation(op)
        }
    }
    
    fileprivate func indexPathForRowType(_ rowType: RowType) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            for (itemIndex, row) in section.items.enumerated() {
                if row == rowType {
                    return IndexPath(row: itemIndex, section: sectionIndex)
                }
            }
        }
        return nil
    }
    
    fileprivate func reloadRows(_ rows: [RowType]) {
        var indexPaths = [IndexPath]()
        for rowType in rows {
            if let indexPath = self.indexPathForRowType(rowType) {
                indexPaths.append(indexPath)
            }
        }
        tableView.reloadRows(at: indexPaths, with: .automatic)
    }
}

// MARK: - NewIntensityTableViewCellDelegate
extension AddRecordViewController: NewIntensityTableViewCellDelegate {
    func intensityCell(_ cell: NewIntensityTableViewCell, didChangeIntensity intensity: Float) {
        chosenIntensity = intensity * 10.0
    }
}

// MARK: - NewDateTableViewCellDelegate
extension AddRecordViewController: NewDateTableViewCellDelegate {
    func dateTableViewCell(_ cell: NewDateTableViewCell, didSelectDate date: Date) {
        chosenDate = date
        reloadRows([.date])
    }
}

// MARK: - PlacesViewControllerDelegate
extension AddRecordViewController: PlacesViewControllerDelegate {
    func placeController(_ controller: PlacesViewController, didChoosePlace place: Place?) {
        if let place = place {
            chosenPlace = place
            reloadRows([.place])
            _ = navigationController?.popViewController(animated: true)
        }
    }
}
