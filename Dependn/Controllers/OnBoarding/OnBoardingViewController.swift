//
//  OnBoardingViewController.swift
//  Dependn
//
//  Created by David Miotti on 30/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import SnapKit

final class OnBoardingViewController: UIViewController {
    
    private var scrollView: UIScrollView!
    private var containerScrollView: UIView!
    private var pageControl: UIPageControl!
    private var nextBtn: UIButton!
    private var okBtn: OkButton!
    private var okBtmConstraint: Constraint!
    
    private var textScrollView: UIScrollView!
    private var textContainerScrollView: UIView!
    
    private var images: [UIImage?]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = "F5FAFF".UIColor
        
        images = [
            UIImage(named: "tour_control"),
            UIImage(named: "tour_note"),
            UIImage(named: "tour_specialist")
        ]

        scrollView = UIScrollView()
        scrollView.pagingEnabled = true
        scrollView.delegate = self
        scrollView.directionalLockEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        
        containerScrollView = UIView()
        scrollView.addSubview(containerScrollView)
        
        textScrollView = UIScrollView()
        textScrollView.userInteractionEnabled = false
        textScrollView.showsHorizontalScrollIndicator = false
        view.addSubview(textScrollView)
        
        textContainerScrollView = UIView()
        textScrollView.addSubview(textContainerScrollView)
        
        pageControl = UIPageControl()
        pageControl.numberOfPages = images.count
        pageControl.pageIndicatorTintColor = UIColor.appBlueColor().colorWithAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = UIColor.appBlueColor()
        pageControl.addTarget(self, action: #selector(OnBoardingViewController.pageControlValueChanged(_:)), forControlEvents: .ValueChanged)
        view.addSubview(pageControl)
        
        nextBtn = UIButton(type: .System)
        nextBtn.setImage(UIImage(named: "tour_next"), forState: .Normal)
        nextBtn.addTarget(self, action: #selector(OnBoardingViewController.nextBtnClicked(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(nextBtn)
        
        okBtn = OkButton()
        okBtn.textLbl.text = L("onboarding.ok")
        okBtn.button.addTarget(self, action: #selector(OnBoardingViewController.okBtnClicked(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(okBtn)
        
        configureLayoutConstraints()

        setupScrollViewContent()
        
        setupTextScrollViewContent()
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    private func setupScrollViewContent() {
        var lastImageView: UIImageView?
        for (index, img) in images.enumerate() {
            let imgView = UIImageView(image: img)
            imgView.contentMode = .Center
            containerScrollView.addSubview(imgView)
            imgView.snp_makeConstraints {
                if DeviceType.IS_IPHONE_4_OR_LESS {
                    $0.top.equalTo(containerScrollView).offset(20)
                } else {
                    $0.top.equalTo(containerScrollView).offset(85)
                }
                
                if let last = lastImageView {
                    $0.left.equalTo(last.snp_right)
                } else {
                    $0.left.equalTo(containerScrollView)
                }
                
                $0.width.equalTo(view)
                $0.height.equalTo(view.snp_width).multipliedBy(0.93)
                
                if index == images.count - 1 {
                    $0.right.equalTo(containerScrollView)
                }
            }
            lastImageView = imgView
        }
    }
    
    private func setupTextScrollViewContent() {
        var lastTextContainerView: UIView?
        for i in 1...3 {
            let textId = String(format: "onboarding.tour%d", i)
            let textContainerView = UIView()
            textContainerScrollView.addSubview(textContainerView)
            let textLbl = textLblWithTitle(L(textId))
            textContainerView.addSubview(textLbl)
            
            textLbl.snp_makeConstraints {
                $0.edges.equalTo(textContainerView).offset(
                    UIEdgeInsets(top: 0, left: 50, bottom: 0, right: -50))
            }
            
            textContainerView.snp_makeConstraints {
                $0.top.equalTo(textContainerScrollView)
                $0.bottom.equalTo(textContainerScrollView)
                
                if let last = lastTextContainerView {
                    $0.left.equalTo(last.snp_right)
                } else {
                    $0.left.equalTo(textContainerScrollView)
                }
                
                $0.width.equalTo(view)
                
                if i == 3 {
                    $0.right.equalTo(textContainerScrollView)
                }
            }
            
            lastTextContainerView = textContainerView
        }
    }
    
    private func textLblWithTitle(title: String) -> UILabel {
        let textLbl = UILabel()
        textLbl.text = title
        textLbl.font = UIFont.systemFontOfSize(18, weight: UIFontWeightRegular)
        textLbl.textColor = UIColor.appBlackColor().colorWithAlphaComponent(0.5)
        textLbl.textAlignment = .Center
        textLbl.numberOfLines = 0
        textLbl.adjustsFontSizeToFitWidth = true
        return textLbl
    }
    
    private func configureLayoutConstraints() {
        scrollView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
        
        containerScrollView.snp_makeConstraints {
            $0.edges.equalTo(scrollView)
            $0.height.equalTo(view)
        }
        
        pageControl.snp_makeConstraints {
            $0.left.equalTo(view)
            $0.right.equalTo(view)
            $0.bottom.equalTo(view).offset(-50)
            $0.height.equalTo(6)
        }
        
        nextBtn.snp_makeConstraints {
            $0.right.equalTo(view).offset(-13)
            $0.centerY.equalTo(pageControl)
            $0.width.equalTo(44)
            $0.height.equalTo(44)
        }
        
        textScrollView.snp_makeConstraints {
            if DeviceType.IS_IPHONE_4_OR_LESS {
                $0.bottom.equalTo(pageControl.snp_top).offset(-35)
            } else {
                $0.bottom.equalTo(pageControl.snp_top).offset(-80)
            }
            $0.left.equalTo(view)
            $0.right.equalTo(view)
            $0.height.equalTo(42);
        }
        
        textContainerScrollView.snp_makeConstraints {
            $0.edges.equalTo(textScrollView)
            $0.height.equalTo(42)
        }
        
        okBtn.snp_makeConstraints {
            $0.width.height.equalTo(60)
            $0.centerX.equalTo(view)
            okBtmConstraint = $0.bottom.equalTo(view).offset(83).constraint
        }
    }
    
    func nextBtnClicked(sender: UIButton) {
        let next = pageControl.currentPage + 1
        if next >= images.count {
            return
        }
        pageControl.currentPage = next
        let pageWidth = scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: CGFloat(next) * pageWidth, y: 0), animated: true)
    }
    
    func pageControlValueChanged(pageControl: UIPageControl) {
        let pageWidth = scrollView.frame.size.width
        let index = pageControl.currentPage
        scrollView.setContentOffset(CGPoint(x: CGFloat(index) * pageWidth, y: 0), animated: true)
        updateInterface()
    }
    
    private func updatePageControlIndexBasedOnScrollViewOffset() {
        let pageWidth = scrollView.frame.size.width
        let pageIndex = floor(scrollView.contentOffset.x - pageWidth / 2) / pageWidth + 1
        pageControl.currentPage = Int(pageIndex)
    }
    
    func okBtnClicked(sender: UIButton) {
        let controller = DependencyChooserViewController()
        controller.style = .Onboarding
        navigationController?.pushViewController(controller, animated: true)
    }

    private func progressForPageIndex(index: Int) -> CGFloat {
        let pageWidth = scrollView.frame.size.width
        let scrollPage = scrollView.contentOffset.x / pageWidth
        let page = pageControl.currentPage
        let progress = scrollPage - CGFloat(page)
        return progress
    }
    
    private func updateInterface() {
        let index = pageControl.currentPage
        var progress = progressForPageIndex(index)
        if index >= 1 {
            if index == 2 {
                progress = 1 - fabs(progress)
            }
            okBtmConstraint.updateOffset(-106.0 * progress + 83.0)
            nextBtn.alpha = 1 - progress
            okBtn.alpha = progress
            pageControl.alpha = 1 - progress
        } else {
            okBtmConstraint.updateOffset(83.0)
            nextBtn.alpha = 1
            pageControl.alpha = 1
            okBtn.alpha = 0
        }
        nextBtn.layoutIfNeeded()
        okBtn.layoutIfNeeded()
        let textOffset = CGPoint(x: scrollView.contentOffset.x, y: 0)
        textScrollView.setContentOffset(textOffset, animated: false)
    }
    
    static func showInController(controller: UIViewController, animated: Bool = true) {
        let onBoarding = OnBoardingViewController()
        let nav = PortraitNavigationController(rootViewController: onBoarding)
        nav.statusBarStyle = .Default
        nav.modalPresentationStyle = .FormSheet
        controller.presentViewController(nav, animated: animated, completion: nil)
    }
}

extension OnBoardingViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updatePageControlIndexBasedOnScrollViewOffset()
            updateInterface()
        }
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        updatePageControlIndexBasedOnScrollViewOffset()
        updateInterface()
    }
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y != 0 {
            scrollView.contentOffset.y = 0
        }
        updateInterface()
    }
}