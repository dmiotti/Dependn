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

    fileprivate var contentView: UIView!
    fileprivate var imageView: UIImageView!
    fileprivate var titleLbl: UILabel!
    fileprivate var subTitleLbl: UILabel!

    fileprivate var acceptBtn: UIButton!
    fileprivate var rejectBtn: UIButton!

    fileprivate var animator: PushPermissionAnimator!

    init() {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    fileprivate func commonInit() {
        modalPresentationStyle = .custom
        transitioningDelegate = self
        animator = PushPermissionAnimator()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentView = UIView()
        contentView.backgroundColor = UIColor.white
        contentView.layer.cornerRadius = 4
        view.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.centerX.equalTo(view)
            $0.centerY.equalTo(view)

            $0.top.greaterThanOrEqualTo(view)
            $0.right.lessThanOrEqualTo(view).offset(-10)
            $0.left.greaterThanOrEqualTo(view).offset(10)
            $0.bottom.lessThanOrEqualTo(view)
        }

        imageView = UIImageView(image: UIImage(named: "push_image"))
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.top.equalTo(contentView).offset(22)
            $0.right.equalTo(contentView).offset(-6)
            $0.left.greaterThanOrEqualTo(contentView).offset(68)
        }

        titleLbl = UILabel()
        titleLbl.text = L("push.perm.title")
        titleLbl.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightRegular)
        titleLbl.textColor = UIColor.appBlackColor()
        titleLbl.textAlignment = .center
        titleLbl.numberOfLines = 0
        contentView.addSubview(titleLbl)
        titleLbl.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(28)
            $0.centerX.equalTo(contentView)
            $0.left.greaterThanOrEqualTo(contentView)
            $0.right.lessThanOrEqualTo(contentView)
        }

        subTitleLbl = UILabel()
        let attr = NSMutableAttributedString(string: L("push.perm.subtitle"))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineHeightMultiple = 1.35
        attr.addAttributes(
            [
                NSFontAttributeName: UIFont.systemFont(ofSize: 13, weight: UIFontWeightRegular),
                NSForegroundColorAttributeName: UIColor.appBlackColor().withAlphaComponent(0.5),
                NSParagraphStyleAttributeName: paragraph
            ], range: NSRange(0..<attr.length))
        subTitleLbl.attributedText = attr
        subTitleLbl.numberOfLines = 0
        contentView.addSubview(subTitleLbl)
        subTitleLbl.snp.makeConstraints {
            $0.top.equalTo(titleLbl.snp.bottom).offset(10)
            $0.centerX.equalTo(contentView)
            $0.left.greaterThanOrEqualTo(contentView).offset(30)
            $0.right.lessThanOrEqualTo(contentView).offset(-30)
        }

        acceptBtn = UIButton(type: .system)
        acceptBtn.setAttributedTitle(uppercaseAttributedString(L("push.perm.accept")), for: .normal)
        acceptBtn.addTarget(self, action: #selector(PushPermissionViewController.acceptBtnClicked(_:)), for: .touchUpInside)
        acceptBtn.backgroundColor = UIColor.appBlueColor()
        acceptBtn.layer.cornerRadius = 22
        acceptBtn.layer.masksToBounds = true
        acceptBtn.contentEdgeInsets = UIEdgeInsets(top: 14, left: 30, bottom: 14, right: 30)
        contentView.addSubview(acceptBtn)
        acceptBtn.snp.makeConstraints {
            $0.top.equalTo(subTitleLbl.snp.bottom).offset(16)
            $0.centerX.equalTo(contentView)
            $0.height.equalTo(44)
        }

        rejectBtn = UIButton(type: .system)
        rejectBtn.setAttributedTitle(uppercaseAttributedString(L("push.perm.reject"), fgColor: UIColor.black.withAlphaComponent(0.20)), for: .normal)
        rejectBtn.addTarget(self, action: #selector(PushPermissionViewController.rejectBtnClicked(_:)), for: .touchUpInside)
        contentView.addSubview(rejectBtn)
        rejectBtn.snp.makeConstraints {
            $0.top.equalTo(acceptBtn.snp.bottom).offset(10)
            $0.centerX.equalTo(contentView)
            $0.bottom.equalTo(contentView).offset(-21)
        }

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(PushPermissionViewController.userDidAcceptPushNotifications(_:)), name: NSNotification.Name(rawValue: kUserAcceptPushPermissions), object: nil)
        nc.addObserver(self, selector: #selector(PushPermissionViewController.userDidRejectPushNotifications(_:)), name: NSNotification.Name(rawValue: kUserRejectPushPermissions), object: nil)
        nc.addObserver(self, selector: #selector(PushPermissionViewController.applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }

    fileprivate func uppercaseAttributedString(_ str: String, fgColor: UIColor = UIColor.white) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: str)
        attr.addAttributes(
            [
                NSFontAttributeName: UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium),
                NSForegroundColorAttributeName: fgColor,
                NSKernAttributeName: 1.2
            ],
            range: NSRange(0..<str.characters.count))
        return attr
    }

    // MARK: - Handle button events

    fileprivate var firstAttempt = true

    func acceptBtnClicked(_ sender: UIButton) {
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
    }

    static func isPermissionAccepted() -> Bool {
        let app = UIApplication.shared
        if let settings = app.currentUserNotificationSettings {
            return settings.types.contains(.alert)
        }
        return false
    }

    func rejectBtnClicked(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Notifications

    func applicationWillEnterForeground(_ notification: Notification) {
        // Does permissions has changed ?
        if PushPermissionViewController.isPermissionAccepted() {
            updateNotifiTypesWithType(.daily, added: true)
            updateNotifiTypesWithType(.weekly, added: true)
            dismiss(animated: true, completion: nil)
        }
    }

    func userDidRejectPushNotifications(_ notification: Notification) {
        if let url = URL(string: UIApplicationOpenSettingsURLString), firstAttempt {
            UIApplication.shared.open(url, options: [:])
            firstAttempt = false
        } else {
            updateNotifiTypesWithType(.daily, added: false)
            updateNotifiTypesWithType(.weekly, added: false)
            dismiss(animated: true, completion: nil)
        }
    }

    func userDidAcceptPushNotifications(_ notification: Notification) {
        updateNotifiTypesWithType(.daily, added: true)
        updateNotifiTypesWithType(.weekly, added: true)
        dismiss(animated: true, completion: nil)
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /* Update the User Defaults property */
    fileprivate func updateNotifiTypesWithType(_ newType: NotificationTypes, added: Bool) {
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
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.presenting = true
        return animator
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.presenting = false
        return animator
    }
}
