//
//  AddRecordTextViewController.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

protocol AddRecordTextViewControllerDelegate {
    func addRecordTextViewController(controller: AddRecordTextViewController, didEnterText text: String?)
}

private let kAddRecordTextViewPlaceholderColor = UIColor.appBlackColor().colorWithAlphaComponent(0.22)
private let kAddRecordTextViewInsets = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)

final class AddRecordTextViewController: UIViewController {
    
    var delegate: AddRecordTextViewControllerDelegate?
    
    private var doneBtn: UIBarButtonItem!
    private var textView: UITextView!
    
    var originalText: String?
    var placeholder: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()

        doneBtn = UIBarButtonItem(title: L("new_record.add_text"), style: .Done, target: self, action: #selector(AddRecordTextViewController.doneBtnClicked(_:)))
        doneBtn.setTitleTextAttributes([
            NSFontAttributeName: UIFont.systemFontOfSize(15, weight: UIFontWeightSemibold),
            NSForegroundColorAttributeName: UIColor.appBlueColor(),
            NSKernAttributeName: -0.36
            ], forState: .Normal)
        navigationItem.rightBarButtonItem = doneBtn
        
        textView = UITextView()
        textView.text = originalText
        textView.textColor = UIColor.appBlackColor()
        textView.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        textView.delegate = self
        textView.textContainerInset = kAddRecordTextViewInsets
        view.addSubview(textView)
        
        if originalText == nil {
            addPlaceholderToTextView()
        }
        
        configureLayoutConstraints()
        
        registerNotificationObservers()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        textView.becomeFirstResponder()
    }
    
    private func configureLayoutConstraints() {
        textView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    private func registerNotificationObservers() {
        let ns = NSNotificationCenter.defaultCenter()
        ns.addObserver(self, selector: #selector(AddRecordTextViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        ns.addObserver(self, selector: #selector(AddRecordTextViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let scrollViewRect = view.convertRect(textView.frame, fromView: textView.superview)
        if let rectValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let kbRect = view.convertRect(rectValue.CGRectValue(), fromView: nil)
            
            let hiddenScrollViewRect = CGRectIntersection(scrollViewRect, kbRect)
            if !CGRectIsNull(hiddenScrollViewRect) {
                var contentInsets = textView.textContainerInset
                contentInsets.bottom = hiddenScrollViewRect.size.height + kAddRecordTextViewInsets.bottom
                textView.textContainerInset = contentInsets
                
                var scrollInsets = textView.scrollIndicatorInsets
                scrollInsets.top = 64
                scrollInsets.bottom = hiddenScrollViewRect.size.height
                textView.scrollIndicatorInsets = scrollInsets
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        textView.textContainerInset = kAddRecordTextViewInsets
        textView.scrollIndicatorInsets = UIEdgeInsetsZero
    }
    
    func doneBtnClicked(sender: UIBarButtonItem) {
        var text: String? = textView.text
        if text == placeholder {
            text = nil
        }
        delegate?.addRecordTextViewController(self, didEnterText: text)
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    private func addPlaceholderToTextView() {
        textView.text = placeholder
        textView.textColor = kAddRecordTextViewPlaceholderColor
        textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
    }
    
}

extension AddRecordTextViewController: UITextViewDelegate {
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        // Combine the textView text and the replacement text to
        // create the updated text string
        let currentText:NSString = textView.text
        let updatedText = currentText.stringByReplacingCharactersInRange(range, withString:text)
        
        // If updated text view will be empty, add the placeholder
        // and set the cursor to the beginning of the text view
        if updatedText.isEmpty {
            addPlaceholderToTextView()
            return false
        }
        // Else if the text view's placeholder is showing and the
        // length of the replacement string is greater than 0, clear
        // the text view and set its color to black to prepare for
        // the user's entry
        else if textView.textColor == kAddRecordTextViewPlaceholderColor {
            textView.text = nil
            textView.textColor = UIColor.appBlackColor()
        }
        
        return true
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        if view.window != nil {
            if textView.textColor == kAddRecordTextViewPlaceholderColor {
                textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
            }
        }
    }
}
