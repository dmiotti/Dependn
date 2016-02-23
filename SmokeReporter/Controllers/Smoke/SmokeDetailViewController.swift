//
//  AddSmokeViewController.swift
//  SmokeReporter
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

private let kAddSmokeLblPadding: CGFloat = 20
private let kAddSmokeValuePadding: CGFloat = 5
private let kAddSmokeHorizontalPadding: CGFloat = 15
private let kAddSmokeTextViewHeight: CGFloat = 50

final class SmokeDetailViewController: UIViewController {
    
    /// View containers
    private var scrollView: UIScrollView!
    private var scrollContentView: UIView!
    
    /// All forms
    private var kindSelector: UISegmentedControl!
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
    
    /// Bar buttons
    private var cancelBtn: UIBarButtonItem!
    private var doneBtn: UIBarButtonItem!
    
    var smoke: Smoke?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L("AddConsomation")
        
        dateFormatter = NSDateFormatter(dateFormat: "EEEE dd MMMM HH:mm")

        view.backgroundColor = UIColor.whiteColor()
        
        cancelBtn = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelBtnClicked:")
        navigationItem.leftBarButtonItem = cancelBtn
        
        doneBtn = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneBtnClicked:")
        navigationItem.rightBarButtonItem = doneBtn
        
        scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        scrollContentView = UIView()
        scrollView.addSubview(scrollContentView)

        kindSelector = UISegmentedControl(items: [ L("Cigarette"), L("Joint") ])
        kindSelector.selectedSegmentIndex = 0
        scrollContentView.addSubview(kindSelector)
        
        intensityLbl = UILabel()
        configureLbl(intensityLbl, withText: L("Intensity"))
        scrollContentView.addSubview(intensityLbl)
        
        intensitySlider = UISlider()
        intensitySlider.maximumValue = 10
        intensitySlider.minimumValue = 1
        intensitySlider.addTarget(self, action: "intensitySlideValueChanged:", forControlEvents: .ValueChanged)
        scrollContentView.addSubview(intensitySlider)
        
        feelingBeforeLbl = UILabel()
        configureLbl(feelingBeforeLbl, withText: L("FeelingBefore"))
        scrollContentView.addSubview(feelingBeforeLbl)
        
        feelingBeforeTextView = UITextView()
        configureTextView(feelingBeforeTextView)
        scrollContentView.addSubview(feelingBeforeTextView)
        
        feelingAfterLbl = UILabel()
        configureLbl(feelingAfterLbl, withText: L("FeelingAfter"))
        scrollContentView.addSubview(feelingAfterLbl)
        
        feelingAfterTextView = UITextView()
        configureTextView(feelingAfterTextView)
        scrollContentView.addSubview(feelingAfterTextView)
        
        commentLbl = UILabel()
        configureLbl(commentLbl, withText: L("Comment"))
        scrollContentView.addSubview(commentLbl)
        
        commentTextView = UITextView()
        configureTextView(commentTextView)
        scrollContentView.addSubview(commentTextView)
        
        dateLbl = UILabel()
        configureLbl(dateLbl, withText: L("Date"))
        scrollContentView.addSubview(dateLbl)
        
        dateTextField = UITextField()
        dateTextField.textAlignment = .Center
        dateTextField.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle1)
        
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .DateAndTime
        dateTextField.inputView = datePicker
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 44))
        toolbar.tintColor = UIColor.grayColor()
        let dateDoneItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "datePickerDidSelectDate:")
        let dateSpaceItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        toolbar.items = [ dateSpaceItem, dateDoneItem ]
        dateTextField.inputAccessoryView = toolbar
        
        scrollContentView.addSubview(dateTextField)
        
        configureLayoutConstraints()
        
        registerNotificationObservers()
        
        prefillWithSmokeIfNeeded()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Prefill
    
    private func prefillWithSmokeIfNeeded() {
        if let smoke = smoke {
            if smoke.normalizedKind == .Joint {
                kindSelector.selectedSegmentIndex = 1
            }
            intensitySlider.value = smoke.intensity.floatValue
            intensitySlider.tintColor = StyleSheet.colorForIntensity(intensitySlider.value)
            feelingBeforeTextView.text = smoke.feelingBefore
            feelingAfterTextView.text = smoke.feelingAfter
            commentTextView.text = smoke.comment
            datePicker.date = smoke.date
            configureDateBtnWithDate(smoke.date)
        } else {
            datePicker.date = NSDate()
            configureDateBtnWithDate(NSDate())
        }
    }
    
    private func configureDateBtnWithDate(date: NSDate) {
        dateTextField.text = dateFormatter.stringFromDate(date).capitalizedString
    }
    
    // MARK: - Bar Buttons
    
    func doneBtnClicked(sender: UIBarButtonItem) {
        let k: SmokeKind = kindSelector.selectedSegmentIndex == 0 ? .Cigarette : .Joint
        if let smoke = smoke {
            smoke.normalizedKind = k
            smoke.intensity = intensitySlider.value
            smoke.feelingBefore = feelingBeforeTextView.text
            smoke.feelingAfter = feelingAfterTextView.text
            smoke.comment = commentTextView.text
            smoke.date = datePicker.date
        } else {
            Smoke.insertNewSmoke(k,
                intensity: intensitySlider.value,
                feelingBefore: feelingBeforeTextView.text,
                feelingAfter: feelingAfterTextView.text,
                comment: commentTextView.text,
                date: datePicker.date)
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
    
    // MARK: - Intensity Slider
    
    func intensitySlideValueChanged(slider: UISlider) {
        slider.tintColor = StyleSheet.colorForIntensity(slider.value)
    }
    
    // MARK: - Keyboard Notifications
    
    private func registerNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
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
    
    // MARK: - Configure Layout Constraints
    
    private func configureLayoutConstraints() {
        scrollView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
        
        scrollContentView.snp_makeConstraints {
            $0.edges.equalTo(scrollView)
            $0.width.equalTo(view)
        }
        
        kindSelector.snp_makeConstraints {
            $0.top.equalTo(scrollContentView).offset(kAddSmokeLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddSmokeHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddSmokeHorizontalPadding)
        }
        
        intensityLbl.snp_makeConstraints {
            $0.top.equalTo(kindSelector.snp_bottom).offset(kAddSmokeLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddSmokeHorizontalPadding)
        }
        
        intensitySlider.snp_makeConstraints {
            $0.top.equalTo(intensityLbl.snp_bottom).offset(kAddSmokeValuePadding)
            $0.left.equalTo(scrollContentView).offset(kAddSmokeHorizontalPadding * 2.0)
            $0.right.equalTo(scrollContentView).offset(-kAddSmokeHorizontalPadding * 2.0)
        }
        
        feelingBeforeLbl.snp_makeConstraints {
            $0.top.equalTo(intensitySlider.snp_bottom).offset(kAddSmokeLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddSmokeHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddSmokeHorizontalPadding)
        }
        
        feelingBeforeTextView.snp_makeConstraints {
            $0.top.equalTo(feelingBeforeLbl.snp_bottom).offset(kAddSmokeValuePadding)
            $0.left.equalTo(scrollContentView).offset(kAddSmokeHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddSmokeHorizontalPadding)
            $0.height.equalTo(kAddSmokeTextViewHeight)
        }
        
        feelingAfterLbl.snp_makeConstraints {
            $0.top.equalTo(feelingBeforeTextView.snp_bottom).offset(kAddSmokeLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddSmokeHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddSmokeHorizontalPadding)
        }
        
        feelingAfterTextView.snp_makeConstraints {
            $0.top.equalTo(feelingAfterLbl.snp_bottom).offset(kAddSmokeValuePadding)
            $0.left.equalTo(scrollContentView).offset(kAddSmokeHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddSmokeHorizontalPadding)
            $0.height.equalTo(kAddSmokeTextViewHeight)
        }
        
        commentLbl.snp_makeConstraints {
            $0.top.equalTo(feelingAfterTextView.snp_bottom).offset(kAddSmokeLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddSmokeHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddSmokeHorizontalPadding)
        }
        
        commentTextView.snp_makeConstraints {
            $0.top.equalTo(commentLbl.snp_bottom).offset(kAddSmokeValuePadding)
            $0.left.equalTo(scrollContentView).offset(kAddSmokeHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddSmokeHorizontalPadding)
            $0.height.equalTo(kAddSmokeTextViewHeight)
        }
        
        dateLbl.snp_makeConstraints {
            $0.top.equalTo(commentTextView.snp_bottom).offset(kAddSmokeLblPadding)
            $0.left.equalTo(scrollContentView).offset(kAddSmokeHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddSmokeHorizontalPadding)
        }
        
        dateTextField.snp_makeConstraints {
            $0.top.equalTo(dateLbl.snp_bottom).offset(kAddSmokeValuePadding)
            $0.left.equalTo(scrollContentView).offset(kAddSmokeHorizontalPadding)
            $0.right.equalTo(scrollContentView).offset(-kAddSmokeHorizontalPadding)
            $0.height.equalTo(kAddSmokeTextViewHeight)
            
            $0.bottom.equalTo(scrollContentView).offset(-kAddSmokeLblPadding)
        }
    }
    
    // MARK: - Private Helpers
    
    private func configureTextView(textView: UITextView) {
        textView.layer.borderColor = UIColor.lightGrayColor().CGColor
        textView.layer.borderWidth = 1
        textView.textContainerInset = UIEdgeInsetsZero
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        textView.delegate = self
    }
    
    private func configureLbl(label: UILabel, withText text: String) {
        label.text = text
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle2)
    }

}

extension SmokeDetailViewController: UITextViewDelegate {
    func textViewDidBeginEditing(textView: UITextView) {
        var rect = scrollView.convertRect(textView.frame, fromView: scrollContentView)
        rect.origin.y += kAddSmokeLblPadding
        scrollView.scrollRectToVisible(rect, animated: true)
    }
}
