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

enum AddRecordSectionType: Int {
    case Addiction, DateAndPlace, Intensity, Optionals
    
    static let count: Int = {
        var max: Int = 0
        while let _ = AddRecordSectionType(rawValue: max) { max += 1 }
        return max
    }()
}

enum DateAndPlaceRowType: Int {
    case Date, Place
}

enum OptionalsRowType: Int {
    case Feeling, Comment
}

enum AddRecordTextEditionType: Int {
    case Place, Feeling, Comment, None
}

extension UIViewController {
    func updateTitle(title: String) {
        let titleLbl = UILabel()
        titleLbl.attributedText = NSAttributedString(string: title.uppercaseString,
            attributes: StyleSheet.kernedAttributes)
        titleLbl.sizeToFit()
        navigationItem.titleView = titleLbl
    }
}

// MARK: - UIViewController
final class AddRecordViewController: UIViewController {
    
    /// User selected fields
    private var tableView: UITableView!
    
    private var cancelBtn: UIBarButtonItem!
    private var doneBtn: UIBarButtonItem!
    
    private var dateFormatter: NSDateFormatter!
    
    private let locationManager = CLLocationManager()
    private var userLocation: CLLocation?
    
    private var editingStep = AddRecordTextEditionType.None
    
    var record: Record?
    
    // MARK: - Editing Record properties
    
    private var chosenDate = NSDate()
    private var chosenAddiction: Addiction!
    private var chosenPlace: String?
    private var chosenIntensity: Float = 3
    private var chosenFeeling: String?
    private var chosenComment: String?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = .None
        
        let screenTitle = record != nil ? L("new_record.modify_title") : L("new_record.title")
        updateTitle(screenTitle)
        
        locationManager.delegate = self
        
        dateFormatter = NSDateFormatter(dateFormat: "EEEE d MMMM, yyyy | HH:mm")
        
        view.backgroundColor = UIColor.lightBackgroundColor()
        
        cancelBtn = UIBarButtonItem(title: L("new_record.cancel"), style: .Plain, target: self, action: "cancelBtnClicked:")
        navigationItem.leftBarButtonItem = cancelBtn

        let doneText = record != nil ? L("new_record.modify") : L("new_record.add_btn")
        doneBtn = UIBarButtonItem(title: doneText, style: .Plain, target: self, action: "addBtnClicked:")
        navigationItem.rightBarButtonItem = doneBtn
        
        chosenAddiction = try! Addiction.getAllAddictions(inContext: CoreDataStack.shared.managedObjectContext).first
        
        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.appSeparatorColor()
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.registerClass(AddictionTableViewCell.self,    forCellReuseIdentifier: AddictionTableViewCell.reuseIdentifier)
        tableView.registerClass(NewDateTableViewCell.self,      forCellReuseIdentifier: NewDateTableViewCell.reuseIdentifier)
        tableView.registerClass(NewPlaceTableViewCell.self,     forCellReuseIdentifier: NewPlaceTableViewCell.reuseIdentifier)
        tableView.registerClass(NewIntensityTableViewCell.self, forCellReuseIdentifier: NewIntensityTableViewCell.reuseIdentifier)
        tableView.registerClass(NewTextTableViewCell.self,      forCellReuseIdentifier: NewTextTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
        
        configureLayoutConstraints()
        
        registerNotificationObservers()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        if Defaults[.useLocation] {
            launchLocationManager()
        }
        
        if let record = record {
            fillWithRecord(record)
        }
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
        chosenFeeling   = record.before
        chosenComment   = record.comment
    }
    
    private func configureLayoutConstraints() {
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    // MARK: - Keyboard
    
    private func registerNotificationObservers() {
        let ns = NSNotificationCenter.defaultCenter()
        ns.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        ns.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
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
            record.before    = chosenFeeling
            record.comment   = chosenComment
            record.date      = chosenDate
            record.place     = chosenPlace
        } else {
            Record.insertNewRecord(chosenAddiction,
                intensity: chosenIntensity,
                before: chosenFeeling,
                after: nil,
                comment: chosenComment,
                place: chosenPlace,
                latitude: userLocation?.coordinate.latitude,
                longitude: userLocation?.coordinate.longitude,
                date: chosenDate,
                inContext: CoreDataStack.shared.managedObjectContext)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func cancelBtnClicked(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

// MARK: - UITableViewDataSource
extension AddRecordViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return AddRecordSectionType.count
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let type = AddRecordSectionType(rawValue: section)!
        switch type {
        case .Addiction:    return 1
        case .DateAndPlace: return 2
        case .Intensity:    return 1
        case .Optionals: 	return 2
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = AddRecordSectionType(rawValue: indexPath.section)!
        switch section {
        case .Addiction:
            let cell = tableView.dequeueReusableCellWithIdentifier(
                AddictionTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! AddictionTableViewCell
            cell.addiction = chosenAddiction
            cell.accessoryType = .DisclosureIndicator
            return cell
        case .DateAndPlace:
            let row = DateAndPlaceRowType(rawValue: indexPath.row)!
            switch row {
            case .Date:
                let cell = tableView.dequeueReusableCellWithIdentifier(NewDateTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! NewDateTableViewCell
                cell.chosenDateLbl.text = dateFormatter.stringFromDate(chosenDate).capitalizedString
                cell.delegate = self
                return cell
            case .Place:
                let cell = tableView.dequeueReusableCellWithIdentifier(NewPlaceTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! NewPlaceTableViewCell
                cell.chosenPlaceLbl.text = chosenPlace
                return cell
            }
        case .Intensity:
            let cell = tableView.dequeueReusableCellWithIdentifier(NewIntensityTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! NewIntensityTableViewCell
            cell.delegate = self
            cell.updateIntensityWithProgress(chosenIntensity / 10.0)
            return cell
        case .Optionals:
            let cell = tableView.dequeueReusableCellWithIdentifier(NewTextTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! NewTextTableViewCell
            let row = OptionalsRowType(rawValue: indexPath.row)!
            switch row {
            case .Feeling:
                cell.descLbl.text = L("new_record.feeling")
                cell.contentLbl.text = chosenFeeling
            case .Comment:
                cell.descLbl.text = L("new_record.comment")
                cell.contentLbl.text = chosenComment
            }
            return cell
        }
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let type = AddRecordSectionType(rawValue: section)!
        switch type {
        case .Intensity:
            return L("new_record.intensity")
        case .Optionals:
            return L("new_record.optional")
        case .Addiction:
            break
        case .DateAndPlace:
            break
        }
        return nil
    }
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let type = AddRecordSectionType(rawValue: section)!
        switch type {
        case .Intensity:
            return 40
        case .Optionals:
            return 40
        case .Addiction:
            return 20
        case .DateAndPlace:
            return 20
        }
    }
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 40))
        
        let titleLbl = UILabel()
        titleLbl.font = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
        titleLbl.textColor = UIColor.appDarkBlueColor()
        header.addSubview(titleLbl)
        
        titleLbl.snp_makeConstraints {
            $0.left.equalTo(header).offset(15)
            $0.bottom.equalTo(header).offset(-5)
        }
        
        let type = AddRecordSectionType(rawValue: section)!
        switch type {
        case .Intensity:
            titleLbl.text = L("new_record.intensity").uppercaseString
            break
        case .Optionals:
            titleLbl.text = L("new_record.optional").uppercaseString
            break
        case .Addiction:
            break
        case .DateAndPlace:
            break
        }
        
        return header
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = AddRecordSectionType(rawValue: indexPath.section)!
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
        
        let section = AddRecordSectionType(rawValue: indexPath.section)!
        switch section {
        case .Addiction:
            let controller = SearchAdditionViewController()
            controller.selectedAddiction = chosenAddiction
            controller.delegate = self
            navigationController?.pushViewController(controller, animated: true)
        case .Intensity: break
        case .Optionals:
            switch OptionalsRowType(rawValue: indexPath.row)! {
            case .Feeling:
                editingStep = .Feeling
                showTextRecord()
            case .Comment:
                editingStep = .Comment
                showTextRecord()
            }
        case .DateAndPlace:
            switch DateAndPlaceRowType(rawValue: indexPath.row)! {
            case .Date:
                break
            case .Place:
                editingStep = .Place
                showTextRecord()
                break
            }
            break
        }
    }
    private func showTextRecord() {
        let controller = AddRecordTextViewController()
        controller.delegate = self
        switch editingStep {
        case .Place:
            controller.updateTitle(L("new_record.place"))
            controller.originalText = chosenPlace
            controller.placeholder = L("new_record.place_placeholder")
        case .Feeling:
            controller.updateTitle(L("new_record.feeling"))
            controller.originalText = chosenFeeling
            controller.placeholder = L("new_record.feeling_placeholder")
        case .Comment:
            controller.updateTitle(L("new_record.comment"))
            controller.originalText = chosenComment
            controller.placeholder = L("new_record.comment_placeholder")
        case .None: break
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
        switch editingStep {
        case .Place:
            chosenPlace = text
        case .Feeling:
            chosenFeeling = text
        case .Comment:
            chosenComment = text
        case .None: break
        }
        editingStep = .None
        
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
        if !Defaults[.useLocation] {
            return
        }

        userLocation = newLocation
        
        DDLogInfo("Location found \(newLocation)")
        
        if let location = userLocation
            where (chosenPlace == nil || chosenPlace?.characters.count == 0) {
                let op = NearestPlaceOperation(location: location, distance: 80)
                op.completionBlock = {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.chosenPlace = op.place
                        self.tableView.reloadRowsAtIndexPaths([
                            NSIndexPath(forRow: DateAndPlaceRowType.Place.rawValue,
                                inSection: AddRecordSectionType.DateAndPlace.rawValue)
                            ], withRowAnimation: .Automatic)
                    }
                }
                let queue = NSOperationQueue()
                queue.addOperation(op)
        }
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
        tableView.reloadRowsAtIndexPaths([
            NSIndexPath(
                forRow: DateAndPlaceRowType.Date.rawValue,
                inSection: AddRecordSectionType.DateAndPlace.rawValue)],
            withRowAnimation: .Automatic)
    }
}