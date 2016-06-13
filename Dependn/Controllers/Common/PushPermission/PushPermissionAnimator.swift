//
//  PushPermissionAnimator.swift
//  Dependn
//
//  Created by David Miotti on 14/06/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit

final class PushPermissionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    var presenting: Bool = true

    private var dimmingView = UIView()

    override init() {
        dimmingView.backgroundColor = UIColor.appBlueColor().colorWithAlphaComponent(0.84)
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.35
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if let
            from = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            to = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
            containerView = transitionContext.containerView() {

            if presenting {
                from.view.userInteractionEnabled = false

                dimmingView.alpha = 0
                containerView.addSubview(dimmingView)
                dimmingView.snp_makeConstraints {
                    $0.edges.equalTo(containerView)
                }

                containerView.addSubview(to.view)
                to.view.snp_makeConstraints {
                    $0.edges.equalTo(containerView)
                }

                to.view.transform = CGAffineTransformMakeTranslation(0, to.view.frame.size.height)
                to.view.alpha = 0

                UIView.animateWithDuration(
                    transitionDuration(transitionContext),
                    delay: 0,
                    usingSpringWithDamping: 1,
                    initialSpringVelocity: 1,
                    options: UIViewAnimationOptions(),
                    animations: {
                        self.dimmingView.alpha = 1
                        from.view.tintAdjustmentMode = .Dimmed
                        to.view.transform = CGAffineTransformIdentity
                        to.view.alpha = 1
                    }, completion: { (finished) in
                        transitionContext.completeTransition(true)
                })

            } else {
                to.view.userInteractionEnabled = true

                UIView.animateWithDuration(
                    transitionDuration(transitionContext),
                    delay: 0,
                    usingSpringWithDamping: 1,
                    initialSpringVelocity: 1,
                    options: UIViewAnimationOptions(),
                    animations: {
                        self.dimmingView.alpha = 0
                        to.view.tintAdjustmentMode = .Automatic
                        from.view.transform = CGAffineTransformMakeTranslation(0, to.view.frame.size.height)
                        from.view.alpha = 0
                    }, completion: { (finished) in
                        self.dimmingView.removeFromSuperview()
                        transitionContext.completeTransition(true)
                })
            }
        }
    }
}