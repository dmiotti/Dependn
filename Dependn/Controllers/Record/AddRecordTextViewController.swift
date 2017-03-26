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
    func addRecordTextViewController(_ controller: AddRecordTextViewController, didEnterText text: String?)
}

private let kAddRecordTextViewPlaceholderColor = UIColor.appBlackColor().withAlphaComponent(0.22)
private let kAddRecordTextViewInsets = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)

final class AddRecordTextViewController: UIViewController {
    
    var delegate: AddRecordTextViewControllerDelegate?
    
    fileprivate var doneBtn: UIBarButtonItem!
    fileprivate var textView: UITextView!
    
    var originalText: String?
    var placeholder: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white

        doneBtn = UIBarButtonItem(title: L("new_record.add_text"), style: .done, target: self, action: #selector(AddRecordTextViewController.doneBtnClicked(_:)))
        doneBtn.setTitleTextAttributes([
            NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightSemibold),
            NSForegroundColorAttributeName: UIColor.appBlueColor(),
            NSKernAttributeName: -0.36
            ], for: UIControlState())
        navigationItem.rightBarButtonItem = doneBtn
        
        textView = UITextView()
        textView.text = originalText
        textView.textColor = UIColor.appBlackColor()
        textView.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
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
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        textView.becomeFirstResponder()
    }
    
    fileprivate func configureLayoutConstraints() {
        textView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    fileprivate func registerNotificationObservers() {
        let ns = NotificationCenter.default
        ns.addObserver(self, selector: #selector(AddRecordTextViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        ns.addObserver(self, selector: #selector(AddRecordTextViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(_ notification: Notification) {
        let scrollViewRect = view.convert(textView.frame, from: textView.superview)
        if let rectValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let kbRect = view.convert(rectValue.cgRectValue, from: nil)
            
            let hiddenScrollViewRect = scrollViewRect.intersection(kbRect)
            if !hiddenScrollViewRect.isNull {
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
    
    func keyboardWillHide(_ notification: Notification) {
        textView.textContainerInset = kAddRecordTextViewInsets
        textView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    func doneBtnClicked(_ sender: UIBarButtonItem) {
        var text: String? = textView.text
        if text == placeholder {
            text = nil
        }
        delegate?.addRecordTextViewController(self, didEnterText: text)
        _ = navigationController?.popToRootViewController(animated: true)
    }
    
    fileprivate func addPlaceholderToTextView() {
        textView.text = placeholder
        textView.textColor = kAddRecordTextViewPlaceholderColor
        textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
    }
    
}

extension AddRecordTextViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Combine the textView text and the replacement text to
        // create the updated text string
        let currentText:NSString = textView.text as NSString
        let updatedText = currentText.replacingCharacters(in: range, with:text)
        
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
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if view.window != nil {
            if textView.textColor == kAddRecordTextViewPlaceholderColor {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }
}
