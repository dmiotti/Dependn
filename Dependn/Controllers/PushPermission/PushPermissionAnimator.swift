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

    fileprivate var dimmingView = UIView()

    override init() {
        dimmingView.backgroundColor = UIColor.appBlueColor().withAlphaComponent(0.84)
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if
            let from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let to = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) {
            
            let containerView = transitionContext.containerView

            if presenting {
                from.view.isUserInteractionEnabled = false

                dimmingView.alpha = 0
                containerView.addSubview(dimmingView)
                dimmingView.snp.makeConstraints {
                    $0.edges.equalTo(containerView)
                }

                containerView.addSubview(to.view)
                to.view.snp.makeConstraints {
                    $0.edges.equalTo(containerView)
                }

                to.view.transform = CGAffineTransform(translationX: 0, y: to.view.frame.size.height)
                to.view.alpha = 0

                UIView.animate(
                    withDuration: transitionDuration(using: transitionContext),
                    delay: 0,
                    usingSpringWithDamping: 1,
                    initialSpringVelocity: 1,
                    options: UIViewAnimationOptions(),
                    animations: {
                        self.dimmingView.alpha = 1
                        from.view.tintAdjustmentMode = .dimmed
                        to.view.transform = CGAffineTransform.identity
                        to.view.alpha = 1
                    }, completion: { (finished) in
                        transitionContext.completeTransition(true)
                })

            } else {
                to.view.isUserInteractionEnabled = true

                UIView.animate(
                    withDuration: transitionDuration(using: transitionContext),
                    delay: 0,
                    usingSpringWithDamping: 1,
                    initialSpringVelocity: 1,
                    options: UIViewAnimationOptions(),
                    animations: {
                        self.dimmingView.alpha = 0
                        to.view.tintAdjustmentMode = .automatic
                        from.view.transform = CGAffineTransform(translationX: 0, y: to.view.frame.size.height)
                        from.view.alpha = 0
                    }, completion: { (finished) in
                        self.dimmingView.removeFromSuperview()
                        transitionContext.completeTransition(true)
                })
            }
        }
    }
}
