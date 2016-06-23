//
//  PushPermissionViewController.swift
//  Dependn
//
//  Created by David Miotti on 13/06/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import SwiftyUserDefaults

final class PushPermissionViewController: UIViewController {

    private var contentView: UIView!
    private var imageView: UIImageView!
    private var titleLbl: UILabel!
    private var subTitleLbl: UILabel!

    private var acceptBtn: UIButton!
    private var rejectBtn: UIButton!

    private var animator: PushPermissionAnimator!

    init() {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        modalPresentationStyle = .Custom
        transitioningDelegate = self
        animator = PushPermissionAnimator()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentView = UIView()
        contentView.backgroundColor = UIColor.whiteColor()
        contentView.layer.cornerRadius = 4
        view.addSubview(contentView)
        contentView.snp_makeConstraints {
            $0.centerX.equalTo(view)
            $0.centerY.equalTo(view)

            $0.top.greaterThanOrEqualTo(view)
            $0.right.lessThanOrEqualTo(view).offset(-10)
            $0.left.greaterThanOrEqualTo(view).offset(10)
            $0.bottom.lessThanOrEqualTo(view)
        }

        imageView = UIImageView(image: UIImage(named: "push_image"))
        contentView.addSubview(imageView)
        imageView.snp_makeConstraints {
            $0.top.equalTo(contentView).offset(22)
            $0.right.equalTo(contentView).offset(-6)
            $0.left.greaterThanOrEqualTo(contentView).offset(68)
        }

        titleLbl = UILabel()
        titleLbl.text = L("push.perm.title")
        titleLbl.font = UIFont.systemFontOfSize(18, weight: UIFontWeightRegular)
        titleLbl.textColor = UIColor.appBlackColor()
        titleLbl.textAlignment = .Center
        titleLbl.numberOfLines = 0
        contentView.addSubview(titleLbl)
        titleLbl.snp_makeConstraints {
            $0.top.equalTo(imageView.snp_bottom).offset(28)
            $0.centerX.equalTo(contentView)
            $0.left.greaterThanOrEqualTo(contentView)
            $0.right.lessThanOrEqualTo(contentView)
        }

        subTitleLbl = UILabel()
        let attr = NSMutableAttributedString(string: L("push.perm.subtitle"))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .Center
        paragraph.lineHeightMultiple = 1.35
        attr.addAttributes(
            [
                NSFontAttributeName: UIFont.systemFontOfSize(13, weight: UIFontWeightRegular),
                NSForegroundColorAttributeName: UIColor.appBlackColor().colorWithAlphaComponent(0.5),
                NSParagraphStyleAttributeName: paragraph
            ], range: NSRange(0..<attr.length))
        subTitleLbl.attributedText = attr
        subTitleLbl.numberOfLines = 0
        contentView.addSubview(subTitleLbl)
        subTitleLbl.snp_makeConstraints {
            $0.top.equalTo(titleLbl.snp_bottom).offset(10)
            $0.centerX.equalTo(contentView)
            $0.left.greaterThanOrEqualTo(contentView).offset(30)
            $0.right.lessThanOrEqualTo(contentView).offset(-30)
        }

        acceptBtn = UIButton(type: .System)
        acceptBtn.setAttributedTitle(uppercaseAttributedString(L("push.perm.accept")), forState: .Normal)
        acceptBtn.addTarget(self, action: #selector(PushPermissionViewController.acceptBtnClicked(_:)), forControlEvents: .TouchUpInside)
        acceptBtn.backgroundColor = UIColor.appBlueColor()
        acceptBtn.layer.cornerRadius = 22
        acceptBtn.layer.masksToBounds = true
        acceptBtn.contentEdgeInsets = UIEdgeInsets(top: 14, left: 30, bottom: 14, right: 30)
        contentView.addSubview(acceptBtn)
        acceptBtn.snp_makeConstraints {
            $0.top.equalTo(subTitleLbl.snp_bottom).offset(16)
            $0.centerX.equalTo(contentView)
            $0.height.equalTo(44)
        }

        rejectBtn = UIButton(type: .System)
        rejectBtn.setAttributedTitle(uppercaseAttributedString(L("push.perm.reject"), fgColor: UIColor.blackColor().colorWithAlphaComponent(0.20)), forState: .Normal)
        rejectBtn.addTarget(self, action: #selector(PushPermissionViewController.rejectBtnClicked(_:)), forControlEvents: .TouchUpInside)
        contentView.addSubview(rejectBtn)
        rejectBtn.snp_makeConstraints {
            $0.top.equalTo(acceptBtn.snp_bottom).offset(10)
            $0.centerX.equalTo(contentView)
            $0.bottom.equalTo(contentView).offset(-21)
        }

        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(PushPermissionViewController.userDidAcceptPushNotifications(_:)), name: kUserAcceptPushPermissions, object: nil)
        nc.addObserver(self, selector: #selector(PushPermissionViewController.userDidRejectPushNotifications(_:)), name: kUserRejectPushPermissions, object: nil)
        nc.addObserver(self, selector: #selector(PushPermissionViewController.applicationWillEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }

    private func uppercaseAttributedString(str: String, fgColor: UIColor = UIColor.whiteColor()) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: str)
        attr.addAttributes(
            [
                NSFontAttributeName: UIFont.systemFontOfSize(12, weight: UIFontWeightMedium),
                NSForegroundColorAttributeName: fgColor,
                NSKernAttributeName: 1.2
            ],
            range: NSRange(0..<str.characters.count))
        return attr
    }

    // MARK: - Handle button events

    private var firstAttempt = true

    func acceptBtnClicked(sender: UIButton) {
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }

    static func isPermissionAccepted() -> Bool {
        let app = UIApplication.sharedApplication()
        if let settings = app.currentUserNotificationSettings() {
            return settings.types.contains(.Alert)
        }
        return false
    }

    func rejectBtnClicked(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Notifications

    func applicationWillEnterForeground(notification: NSNotification) {
        // Does permissions has changed ?
        if PushPermissionViewController.isPermissionAccepted() {
            updateNotifiTypesWithType(.Daily, added: true)
            updateNotifiTypesWithType(.Weekly, added: true)
            dismissViewControllerAnimated(true, completion: nil)
        }
    }

    func userDidRejectPushNotifications(notification: NSNotification) {
        if let URL = NSURL(string: UIApplicationOpenSettingsURLString) where firstAttempt {
            UIApplication.sharedApplication().openURL(URL)
            firstAttempt = false
        } else {
            updateNotifiTypesWithType(.Daily, added: false)
            updateNotifiTypesWithType(.Weekly, added: false)
            dismissViewControllerAnimated(true, completion: nil)
        }
    }

    func userDidAcceptPushNotifications(notification: NSNotification) {
        updateNotifiTypesWithType(.Daily, added: true)
        updateNotifiTypesWithType(.Weekly, added: true)
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    /* Update the User Defaults property */
    private func updateNotifiTypesWithType(newType: NotificationTypes, added: Bool) {
        let rawValue = Defaults[.notificationTypes]
        var types = NotificationTypes(rawValue: rawValue)
        if added {
            if !types.contains(newType) {
                types.insert(newType)
            }
        } else {
            if types.contains(newType) {
                types.remove(newType)
            }
        }
        Defaults[.notificationTypes] = types.rawValue
    }
}

extension PushPermissionViewController: UIViewControllerTransitioningDelegate {
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.presenting = true
        return animator
    }
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.presenting = false
        return animator
    }
}
