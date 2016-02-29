//
//  RecordDetailViewController.swift
//  Dependn
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreLocation
import MapKit

private let kAddRecordLblPadding: CGFloat = 20
private let kAddRecordValuePadding: CGFloat = 5
private let kAddRecordHorizontalPadding: CGFloat = 15
private let kAddRecordTextViewHeight: CGFloat = 50

final class RecordDetailViewController: UIViewController {
    
    /// View containers
    private var scrollView: UIScrollView!
    private var scrollContentView: UIView!
    
    /// All forms
    private var typeSelector: UISegmentedControl!
    private var intensityLbl: UILabel!
    private var intensitySlider: UISlider!
    private var feelingBeforeLbl: UILabel!
    private var feelingBeforeTextView: UITextView!
    private var feelingAfterLbl: UILabel!
    private var feelingAfterTextView: UITextView!
    private var commentLbl: UILabel!
    private var commentTextView: UITextView!
    private var dateLbl: UILabel!
    private var dateTextField: UITextField!
    private var dateFormatter: NSDateFormatter!
    private var datePicker: UIDatePicker!
    private var mapLbl: UILabel!
    private var mapView: MKMapView!
    private var placeNameField: UITextField!
    private var allowMapBtn: UIButton!
    private var useMyPositionLbl: UILabel!
    private var useMyPositionSwitch: UISwitch!
    
    /// Bar buttons
    private var cancelBtn: UIBarButtonItem!
    private var doneBtn: UIBarButtonItem!
    
    var record: Record?
    
    private var userLocation: MKUserLocation?
    private let locationManager = CLLocationManager()
    private let nearbyQueue = NSOperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter = NSDateFormatter(dateFormat: "EEEE dd MMMM HH:mm")
        
        locationManager.delegate = self
        
        view.backgroundColor = UIColor.lightBackgroundColor()
        
        cancelBtn = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelBtnClicked:")
        navigationItem.leftBarButtonItem = cancelBtn
        
        doneBtn = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneBtnClicked:")
        navigationItem.rightBarButtonItem = doneBtn
        
        scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        scrollContentView = UIView()
        scrollView.addSubview(scrollContentView)
        
        typeSelector = UISegmentedControl(items: [ L("new.cig"), L("new.weed") ])
        typeSelector.selectedSegmentIndex = 0
        scrollContentView.addSubview(typeSelector)
        
        intensityLbl = UILabel()
        configureLbl(intensityLbl, withText: L("new.intensity"))
        scrollContentView.addSubview(intensityLbl)
        
        intensitySlider = UISlider()
        intensitySlider.maximumValue = 10
        intensitySlider.minimumValue = 1
        intensitySlider.addTarget(self, action: "intensitySlideValueChanged:", forControlEvents: .ValueChanged)
        scrollContentView.addSubview(intensitySlider)
        
        feelingBeforeLbl = UILabel()
        configureLbl(feelingBeforeLbl, withText: L("new.feeling_before"))
        
        feelingBeforeTextView = UITextView()
        configureTextView(feelingBeforeTextView)
        
        feelingAfterLbl = UILabel()
        configureLbl(feelingAfterLbl, withText: L("new.feeling_after"))
        
        feelingAfterTextView = UITextView()
        configureTextView(feelingAfterTextView)
        
        commentLbl = UILabel()
        configureLbl(commentLbl, withText: L("new.comment"))
        
        commentTextView = UITextView()
        configureTextView(commentTextView)
        
        dateLbl = UILabel()
        configureLbl(dateLbl, withText: L("new.date"))
        
        dateTextField = UITextField()
        configureDateTextField()
        
        mapLbl = UILabel()
        configureLbl(mapLbl, withText: L("new.place"))
        
        mapView = MKMapView()
        mapView.delegate = self
        mapView.layer.cornerRadius = 3
        mapView.clipsToBounds = true
        mapView.userInteractionEnabled = false
        scrollContentView.addSubview(mapView)
        
        allowMapBtn = UIButton(type: .System)
        allowMapBtn.setTitle(L("new.allow_map"), forState: .Normal)
        allowMapBtn.setTitleColor(UIColor.appBlackColor(), forState: .Normal)
        allowMapBtn.contentEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        allowMapBtn.titleLabel?.lineBreakMode = .ByWordWrapping
        allowMapBtn.titleLabel?.font = UIFont.systemFontOfSize(20, weight: UIFontWeightThin)
        allowMapBtn.addTarget(self, action: "allowUsingMapBtnClicked:", forControlEvents: .TouchUpInside)
        allowMapBtn.backgroundColor = UIColor.lightBackgroundColor()
        scrollContentView.addSubview(allowMapBtn)
        
        placeNameField = UITextField()
        placeNameField.placeholder = L("new.place_placeholder")
        placeNameField.returnKeyType = .Done
        placeNameField.delegate = self
        scrollContentView.addSubview(placeNameField)
        
        useMyPositionLbl = UILabel()
        useMyPositionLbl.text = L("new.use_my_position")
        useMyPositionLbl.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        scrollContentView.addSubview(useMyPositionLbl)
        
        useMyPositionSwitch = UISwitch()
        useMyPositionSwitch.addTarget(self, action: "switchValueChanged:", forControlEvents: .ValueChanged)
        scrollContentView.addSubview(useMyPositionSwitch)
        
        configureLayoutConstraints()
        
        registerNotificationObservers()
        
        fillWithRecordIfNeeded()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Auto fill with the given record
    
    private func fillWithRecordIfNeeded() {
        if let record = record {
            if record.recordType == .Weed {
                typeSelector.selectedSegmentIndex = 1
            }
            intensitySlider.value = record.intensity.floatValue
            feelingBeforeTextView.text = record.before
            feelingAfterTextView.text = record.after
            commentTextView.text = record.comment
            datePicker.date = record.date
            placeNameField.text = record.place
            allowMapBtn.hidden = true
            if let lat = record.lat?.doubleValue, lon = record.lon?.doubleValue {
                enableMapView(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            } else {
                disableMapView(false)
            }
            configureDateBtnWithDate(record.date)
        } else {
            datePicker.date = NSDate()
            configureDateBtnWithDate(NSDate())
            
            if CLLocationManager.authorizationStatus() != .NotDetermined {
                enableMapView(nil)
                locationManager.requestWhenInUseAuthorization()
            } else {
                disableMapView(true)
            }
        }
    }
    
    private func configureDateBtnWithDate(date: NSDate) {
        dateTextField.text = dateFormatter.stringFromDate(date).capitalizedString
    }
    
    // MARK: - Bar Buttons
    
    func doneBtnClicked(sender: UIBarButtonItem) {
        let type: RecordType = typeSelector.selectedSegmentIndex == 0 ? .Cig : .Weed
        if let record = record {
            record.recordType = type
            record.intensity = intensitySlider.value
            record.before = feelingBeforeTextView.text
            record.after = feelingAfterTextView.text
            record.comment = commentTextView.text
            record.date = datePicker.date
            record.place = placeNameField.text
        } else {
            Record.insertNewRecord(type,
                intensity: intensitySlider.value,
                before: feelingBeforeTextView.text,
                after: feelingAfterTextView.text,
                comment: commentTextView.text,
                place: placeNameField.text,
                latitude: userLocation?.coordinate.latitude,
                longitude: userLocation?.coordinate.longitude,
                date: datePicker.date,
                inContext: CoreDataStack.shared.managedObjectContext)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func cancelBtnClicked(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func datePickerDidSelectDate(sender: UIBarButtonItem) {
        dateTextField.resignFirstResponder()
        configureDateBtnWithDate(datePicker.date)
    }
    
    func switchValueChanged(sender: UISwitch) {
        if !sender.on {
            userLocation = nil
        } else {
            
        }
    }
    
    // MARK: - Intensity Slider
    
    func intensitySlideValueChanged(slider: UISlider) {
        slider.tintColor = UIColor.colorForIntensity(slider.value)
    }
    
    // MARK: - Keyboard Notifications
    
    private func registerNotificationObservers() {
        let ns = NSNotificationCenter.defaultCenter()
        ns.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        ns.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let scrollViewRect = view.convertRect(scrollView.frame, fromView: scrollView.superview)
        if let rectValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let kbRect = view.convertRect(rectValue.CGRectValue(), fromView: nil)
            
            let hiddenScrollViewRect = CGRectIntersection(scrollViewRect, kbRect)
            if !CGRectIsNull(hiddenScrollViewRect) {
                var contentInsets = scrollView.contentInset
                contentInsets.bottom = hiddenScrollViewRect.size.height
                scrollView.contentInset = contentInsets
                scrollView.scrollIndicatorInsets = contentInsets
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        var contentInsets = scrollView.contentInset
        contentInsets.bottom = 0
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    func allowUsingMapBtnClicked(sender: UIButton) {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Private Helpers
    
    private func configureTextView(textView: UITextView) {
        textView.layer.borderColor = UIColor.lightGrayColor().CGColor
        textView.layer.borderWidth = 1
        textView.textContainerInset = UIEdgeInsetsZero
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        textView.delegate = self
        scrollContentView.addSubview(textView)
    }
    
    private func configureLbl(label: UILabel, withText text: String) {
        label.text = text
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle2)
        scrollContentView.addSubview(label)
    }
    
    private func configureDateTextField() {
        dateTextField.textAlignment = .Center
        dateTextField.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle1)
        dateTextField.adjustsFontSizeToFitWidth = true
        
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .DateAndTime
        dateTextField.inputView = datePicker
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 44))
        let dateDoneItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "datePickerDidSelectDate:")
        dateDoneItem.setTitleTextAttributes([
            NSForegroundColorAttributeName: UIColor.appBlueColor(),
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
            ], forState: .Normal)
        let dateSpaceItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        toolbar.items = [ dateSpaceItem, dateDoneItem ]
        dateTextField.inputAccessoryView = toolbar
        
        scrollContentView.addSubview(dateTextField)
    }
    
    private func enableMapView(location: CLLocationCoordinate2D?) {
        if allowMapBtn.alpha > 0 {
            UIView.animateWithDuration(0.35, animations: {
                self.allowMapBtn.alpha = 0
                }, completion: { finished in
                    self.allowMapBtn.hidden = true
            })
        }
        if let location = location {
            let coord = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            let region = MKCoordinateRegion(center: coord, span: span)
            mapView.setRegion(region, animated: true)
            
            let ann = MKPointAnnotation()
            ann.coordinate = coord
            mapView.addAnnotation(ann)
            
            useMyPositionSwitch.enabled = false
            useMyPositionSwitch.on = false
        } else {
            mapView.showsUserLocation = true
            mapView.setUserTrackingMode(.Follow, animated: true)
            
            useMyPositionSwitch.enabled = true
            useMyPositionSwitch.on = true
        }
        mapLbl.hidden = false
        mapView.hidden = false
    }
    
    private func disableMapView(canAccept: Bool) {
        if canAccept {
            useMyPositionSwitch.enabled = true
            useMyPositionSwitch.on = false
            allowMapBtn.alpha = 1
        } else {
            useMyPositionSwitch.enabled = false
            useMyPositionSwitch.on = false
            mapLbl.hidden = true
            mapView.hidden = true
        }
    }
}

// MARK: - MKMapViewDelegate
extension RecordDetailViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        self.userLocation = userLocation
        
        if let location = userLocation.location
            where (placeNameField.text == nil || placeNameField.text?.characters.count == 0) {
                let op = NearestPlaceOperation(location: location, distance: 80)
                op.completionBlock = {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.placeNameField.text = op.place
                    }
                }
                nearbyQueue.addOperation(op)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension RecordDetailViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if record != nil { return }
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            enableMapView(nil)
        } else {
            disableMapView(true)
        }
    }
}

// MARK: - UITextViewDelegate
extension RecordDetailViewController: UITextViewDelegate {
    func textViewDidBeginEditing(textView: UITextView) {
        var rect = scrollView.convertRect(textView.frame, fromView: scrollContentView)
        rect.origin.y += kAddRecordLblPadding
        scrollView.scrollRectToVisible(rect, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension RecordDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Configure Layout Constraints
extension RecordDetailViewController {
    
    private func configureLayoutConstraints() {
        scrollView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
        
        scrollContentView.snp_makeConstraints {
            $0.edges.equalTo(scrollView)
            $0.width.equalTo(view)
        }
        
        typeSelector.snp_makeConstraints {
            $0.top.equalTo(scrollContentView).offset(kAddRecordLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding)
        }
        
        intensityLbl.snp_makeConstraints {
            $0.top.equalTo(typeSelector.snp_bottom).offset(kAddRecordLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding)
        }
        
        intensitySlider.snp_makeConstraints {
            $0.top.equalTo(intensityLbl.snp_bottom).offset(kAddRecordValuePadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding * 2.0)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding * 2.0)
        }
        
        feelingBeforeLbl.snp_makeConstraints {
            $0.top.equalTo(intensitySlider.snp_bottom).offset(kAddRecordLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding)
        }
        
        feelingBeforeTextView.snp_makeConstraints {
            $0.top.equalTo(feelingBeforeLbl.snp_bottom).offset(kAddRecordValuePadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding)
            $0.height.equalTo(kAddRecordTextViewHeight)
        }
        
        feelingAfterLbl.snp_makeConstraints {
            $0.top.equalTo(feelingBeforeTextView.snp_bottom).offset(kAddRecordLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding)
        }
        
        feelingAfterTextView.snp_makeConstraints {
            $0.top.equalTo(feelingAfterLbl.snp_bottom).offset(kAddRecordValuePadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding)
            $0.height.equalTo(kAddRecordTextViewHeight)
        }
        
        commentLbl.snp_makeConstraints {
            $0.top.equalTo(feelingAfterTextView.snp_bottom).offset(kAddRecordLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding)
        }
        
        commentTextView.snp_makeConstraints {
            $0.top.equalTo(commentLbl.snp_bottom).offset(kAddRecordValuePadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding)
            $0.height.equalTo(kAddRecordTextViewHeight)
        }
        
        dateLbl.snp_makeConstraints {
            $0.top.equalTo(commentTextView.snp_bottom).offset(kAddRecordLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding)
        }
        
        dateTextField.snp_makeConstraints {
            $0.top.equalTo(dateLbl.snp_bottom).offset(kAddRecordValuePadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding*2.0)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding*2.0)
            $0.height.equalTo(kAddRecordTextViewHeight)
        }
        
        mapLbl.snp_makeConstraints {
            $0.top.equalTo(dateTextField.snp_bottom).offset(kAddRecordLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding)
        }
        
        placeNameField.snp_makeConstraints {
            $0.top.equalTo(mapLbl.snp_bottom).offset(kAddRecordLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding)
        }
        
        mapView.snp_makeConstraints {
            $0.top.equalTo(placeNameField.snp_bottom).offset(kAddRecordValuePadding)
            $0.left.equalTo(scrollContentView).offset(kAddRecordHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding)
            $0.height.equalTo(scrollContentView.snp_width).multipliedBy(0.4)
        }
        
        allowMapBtn.snp_makeConstraints {
            $0.edges.equalTo(mapView)
        }
        
        useMyPositionLbl.snp_makeConstraints {
            $0.right.equalTo(useMyPositionSwitch.snp_left).offset(-kAddRecordHorizontalPadding)
            $0.centerY.equalTo(useMyPositionSwitch)
        }
        
        useMyPositionSwitch.snp_makeConstraints {
            $0.right.equalTo(scrollContentView).offset(-kAddRecordHorizontalPadding)
            $0.top.equalTo(mapView.snp_bottom).offset(kAddRecordValuePadding)
            $0.bottom.equalTo(scrollContentView).offset(-kAddRecordLblPadding)
        }
    }
    
}
