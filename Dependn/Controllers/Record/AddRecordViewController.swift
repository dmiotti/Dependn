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
    
    private enum SectionType {
        case Addiction
        case DateAndPlace
        case Intensity
        case Optionals
    }
    
    private enum RowType {
        case Addiction
        case Date
        case Place
        case Intensity
        case Feelings
        case Comments
    }
    
    private struct Section {
        var type: SectionType
        var items: [RowType]
    }
    
    /// Title segmented control
    private var segmentedControl: UISegmentedControl!
    
    /// User selected fields
    private var tableView: UITableView!
    
    private var cancelBtn: UIBarButtonItem!
    private var doneBtn: UIBarButtonItem!
    
    private let locationManager = CLLocationManager()
    private var userLocation: CLLocation?
    
    private var editingStep: RowType?
    
    var record: Record?
    
    private var sections = [Section]()
    
    // MARK: - Editing Record properties
    
    private var chosenDate = NSDate()
    private var chosenAddiction: Addiction!
    private var chosenPlace: Place?
    private var chosenIntensity: Float = 3
    private var chosenFeeling: String?
    private var chosenComment: String?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sections = [
            Section(type: .Addiction, items: [ .Addiction ]),
            Section(type: .DateAndPlace, items: [ .Date, .Place ]),
            Section(type: .Intensity, items: [ .Intensity ]),
            Section(type: .Optionals, items: [ .Feelings, .Comments ])
        ]
        
        edgesForExtendedLayout = .None
        
        segmentedControl = UISegmentedControl(items: [ L("new_record.conso"), L("new_record.desire") ])
        segmentedControl.setWidth(76, forSegmentAtIndex: 0)
        segmentedControl.setWidth(76, forSegmentAtIndex: 1)
        segmentedControl.selectedSegmentIndex = 0
        navigationItem.titleView = segmentedControl
        
        locationManager.delegate = self
        
        view.backgroundColor = UIColor.lightBackgroundColor()
        
        navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        navigationController?.navigationBar.tintColor = UIColor.appBlueColor()
        
        cancelBtn = UIBarButtonItem(title: L("new_record.cancel"), style: .Plain, target: self, action: #selector(AddRecordViewController.cancelBtnClicked(_:)))
        cancelBtn.setTitleTextAttributes(StyleSheet.cancelBtnAttrs, forState: .Normal)
        navigationItem.leftBarButtonItem = cancelBtn
        
        let doneText = record != nil ? L("new_record.modify") : L("new_record.add_btn")
        doneBtn = UIBarButtonItem(title: doneText, style: .Done, target: self, action: #selector(AddRecordViewController.addBtnClicked(_:)))
        doneBtn.setTitleTextAttributes(StyleSheet.doneBtnAttrs, forState: .Normal)
        navigationItem.rightBarButtonItem = doneBtn
        
        chosenAddiction = try! Addiction.getAllAddictionsOrderedByCount(inContext: CoreDataStack.shared.managedObjectContext).first
        
        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.registerClass(AddictionTableViewCell.self,    forCellReuseIdentifier: AddictionTableViewCell.reuseIdentifier)
        tableView.registerClass(NewDateTableViewCell.self,      forCellReuseIdentifier: NewDateTableViewCell.reuseIdentifier)
        tableView.registerClass(NewPlaceTableViewCell.self,     forCellReuseIdentifier: NewPlaceTableViewCell.reuseIdentifier)
        tableView.registerClass(NewIntensityTableViewCell.self, forCellReuseIdentifier: NewIntensityTableViewCell.reuseIdentifier)
        tableView.registerClass(NewTextTableViewCell.self,      forCellReuseIdentifier: NewTextTableViewCell.reuseIdentifier)
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
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func fillWithRecord(record: Record) {
        chosenAddiction = record.addiction
        chosenIntensity = record.intensity.floatValue
        chosenDate      = record.date
        chosenPlace     = record.place
        chosenFeeling   = record.feeling
        chosenComment   = record.comment
        segmentedControl.selectedSegmentIndex = record.desire.boolValue ? 1 : 0
    }
    
    private func configureLayoutConstraints() {
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    // MARK: - Keyboard
    
    private func registerNotificationObservers() {
        let ns = NSNotificationCenter.defaultCenter()
        ns.addObserver(self, selector: #selector(AddRecordViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        ns.addObserver(self, selector: #selector(AddRecordViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
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
    
    // MARK: - UIBarButtonItems
    
    func addBtnClicked(sender: UIBarButtonItem) {
        if let record = record {
            
            record.addiction = chosenAddiction
            record.intensity = chosenIntensity
            record.feeling   = chosenFeeling
            record.comment   = chosenComment
            record.date      = chosenDate
            record.place     = chosenPlace
            record.desire    = segmentedControl.selectedSegmentIndex == 1
            
        } else {
            
            let isDesire = segmentedControl.selectedSegmentIndex == 1
            
            Record.insertNewRecord(chosenAddiction,
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
            
            tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }

        PushSchedulerOperation.schedule()
        
        dismissViewControllerAnimated(true, completion: { finished in
            WatchSessionManager.sharedManager.updateApplicationContext()
        })
    }
    
    func cancelBtnClicked(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - UITableViewDataSource
extension AddRecordViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let row = sections[indexPath.section].items[indexPath.row]
        switch row {
        case .Addiction:
            let cell = tableView.dequeueReusableCellWithIdentifier(
                AddictionTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! AddictionTableViewCell
            cell.addiction = chosenAddiction
            cell.accessoryType = .DisclosureIndicator
            return cell
        case .Date:
            let cell = tableView.dequeueReusableCellWithIdentifier(NewDateTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! NewDateTableViewCell
            cell.date = chosenDate
            cell.delegate = self
            return cell
        case .Place:
            let cell = tableView.dequeueReusableCellWithIdentifier(NewPlaceTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! NewPlaceTableViewCell
            cell.chosenPlaceLbl.text = chosenPlace?.name.firstLetterCapitalization
            return cell
        case .Intensity:
            let cell = tableView.dequeueReusableCellWithIdentifier(NewIntensityTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! NewIntensityTableViewCell
            cell.delegate = self
            cell.updateIntensityWithProgress(chosenIntensity / 10.0)
            return cell
        case .Feelings:
            let cell = tableView.dequeueReusableCellWithIdentifier(NewTextTableViewCell.reuseIdentifier, forIndexPath:
                indexPath) as! NewTextTableViewCell
            cell.descLbl.text = L("new_record.feeling")
            cell.contentLbl.text = chosenFeeling
            return cell
        case .Comments:
            let cell = tableView.dequeueReusableCellWithIdentifier(NewTextTableViewCell.reuseIdentifier, forIndexPath:
                indexPath) as! NewTextTableViewCell
            cell.descLbl.text = L("new_record.comment")
            cell.contentLbl.text = chosenComment
            return cell
        }
    }
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let type = sections[section].type
        switch type {
        case .Addiction:
            return 20
        case .DateAndPlace:
            return 20
        case .Intensity:
            return 40
        case .Optionals:
            return 40
        }
    }
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = TableHeaderView()
        
        let type = sections[section].type
        switch type {
        case .Intensity:
            header.title = L("new_record.intensity").uppercaseString
        case .Optionals:
            header.title = L("new_record.optional").uppercaseString
        case .Addiction:
            break
        case .DateAndPlace:
            break
        }
        
        return header
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = sections[indexPath.section].type
        if row == .Intensity {
            return 105.0
        }
        return 55.0
    }
}

// MARK: - UITableViewDelegate
extension AddRecordViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let row = sections[indexPath.section].items[indexPath.row]
        switch row {
        case .Addiction:
            let controller = SearchAdditionViewController()
            controller.selectedAddiction = chosenAddiction
            controller.delegate = self
            navigationController?.pushViewController(controller, animated: true)
        case .Date:
            break
        case .Place:
            showPlaces()
        case .Intensity:
            break
        case .Feelings:
            editingStep = .Feelings
            showTextRecord()
        case .Comments:
            editingStep = .Comments
            showTextRecord()
        }
    }
    private func showPlaces() {
        let places = PlacesViewController()
        places.delegate = self
        places.selectedPlace = chosenPlace
        navigationController?.pushViewController(places, animated: true)
    }
    private func showTextRecord() {
        let controller = AddRecordTextViewController()
        controller.delegate = self
        switch editingStep! {
        case .Feelings:
            controller.updateTitle(L("new_record.feeling_subtitle"), blueBackground: false)
            controller.originalText = chosenFeeling
            if !Defaults[.hasSeenEmotionPlaceholder] {
                controller.placeholder = L("new_record.feeling_placeholder")
                Defaults[.hasSeenEmotionPlaceholder] = true
            }
        case .Comments:
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
    func searchController(searchController: SearchAdditionViewController, didSelectAddiction addiction: Addiction) {
        chosenAddiction = addiction
        tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
    }
}

// MARK - AddRecordTextViewControllerDelegate
extension AddRecordViewController: AddRecordTextViewControllerDelegate {
    func addRecordTextViewController(controller: AddRecordTextViewController, didEnterText text: String?) {
        switch editingStep! {
        case .Feelings:
            chosenFeeling = text
        case .Comments:
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
    private func launchLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.stopUpdatingLocation()
        locationManager.startUpdatingLocation()
    }
    private func stopLocationManager() {
        locationManager.stopUpdatingLocation()
    }
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if record != nil || !Defaults[.useLocation] {
            return
        }
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            launchLocationManager()
        } else {
            stopLocationManager()
        }
    }
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        if record != nil || !Defaults[.useLocation] {
            return
        }
        
        userLocation = newLocation
        
        DDLogInfo("Location found \(newLocation)")
        
        if let location = userLocation
            where (chosenPlace == nil || chosenPlace?.name.characters.count == 0) {
            let op = NearestPlaceOperation(location: location, distance: 80)
            op.completionBlock = {
                dispatch_async(dispatch_get_main_queue()) {
                    if let placeId = op.place?.objectID {
                        let moc = CoreDataStack.shared.managedObjectContext
                        let place = moc.objectWithID(placeId) as! Place
                        self.chosenPlace = place
                        self.reloadRows([.Place])
                    }
                }
            }
            let queue = NSOperationQueue()
            queue.addOperation(op)
        }
    }
    
    private func indexPathForRowType(rowType: RowType) -> NSIndexPath? {
        for (sectionIndex, section) in sections.enumerate() {
            for (itemIndex, row) in section.items.enumerate() {
                if row == rowType {
                    return NSIndexPath(forRow: itemIndex, inSection: sectionIndex)
                }
            }
        }
        return nil
    }
    
    private func reloadRows(rows: [RowType]) {
        var indexPaths = [NSIndexPath]()
        for rowType in rows {
            if let indexPath = self.indexPathForRowType(rowType) {
                indexPaths.append(indexPath)
            }
        }
        tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    }
}

// MARK: - NewIntensityTableViewCellDelegate
extension AddRecordViewController: NewIntensityTableViewCellDelegate {
    func intensityCell(cell: NewIntensityTableViewCell, didChangeIntensity intensity: Float) {
        chosenIntensity = intensity * 10.0
    }
}

// MARK: - NewDateTableViewCellDelegate
extension AddRecordViewController: NewDateTableViewCellDelegate {
    func dateTableViewCell(cell: NewDateTableViewCell, didSelectDate date: NSDate) {
        chosenDate = date
        reloadRows([.Date])
    }
}

// MARK: - PlacesViewControllerDelegate
extension AddRecordViewController: PlacesViewControllerDelegate {
    func placeController(controller: PlacesViewController, didChoosePlace place: Place?) {
        if let place = place {
            chosenPlace = place
            reloadRows([.Place])
            navigationController?.popViewControllerAnimated(true)
        }
    }
}
