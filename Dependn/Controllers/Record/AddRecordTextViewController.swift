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

final class AddRecordTextViewController: UIViewController {
    
    var delegate: AddRecordTextViewControllerDelegate?
    
    private var doneBtn: UIBarButtonItem!
    private var textView: UITextView!
    
    var originalText: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()

        doneBtn = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneBtnClicked:")
        navigationItem.rightBarButtonItem = doneBtn
        
        textView = UITextView()
        textView.text = originalText
        textView.textColor = UIColor.appBlackColor()
        textView.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        view.addSubview(textView)
        
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
        ns.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        ns.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let scrollViewRect = view.convertRect(textView.frame, fromView: textView.superview)
        if let rectValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let kbRect = view.convertRect(rectValue.CGRectValue(), fromView: nil)
            
            let hiddenScrollViewRect = CGRectIntersection(scrollViewRect, kbRect)
            if !CGRectIsNull(hiddenScrollViewRect) {
                var contentInsets = textView.textContainerInset
                contentInsets.bottom = hiddenScrollViewRect.size.height
                textView.textContainerInset = contentInsets
                textView.scrollIndicatorInsets = contentInsets
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        var contentInsets = textView.textContainerInset
        contentInsets.bottom = 0
        textView.textContainerInset = contentInsets
        textView.scrollIndicatorInsets = contentInsets
    }
    
    func doneBtnClicked(sender: UIBarButtonItem) {
        delegate?.addRecordTextViewController(self, didEnterText: textView.text)
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
}
