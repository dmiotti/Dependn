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
    
    fileprivate var scrollView: UIScrollView!
    fileprivate var containerScrollView: UIView!
    fileprivate var pageControl: UIPageControl!
    fileprivate var nextBtn: UIButton!
    fileprivate var okBtn: OkButton!
    fileprivate var okBtmConstraint: Constraint!
    
    fileprivate var textScrollView: UIScrollView!
    fileprivate var textContainerScrollView: UIView!
    
    fileprivate var images: [UIImage?]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = "F5FAFF".UIColor
        
        images = [
            UIImage(named: "tour_control"),
            UIImage(named: "tour_note"),
            UIImage(named: "tour_specialist")
        ]

        scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.isDirectionalLockEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        
        containerScrollView = UIView()
        scrollView.addSubview(containerScrollView)
        
        textScrollView = UIScrollView()
        textScrollView.isUserInteractionEnabled = false
        textScrollView.showsHorizontalScrollIndicator = false
        view.addSubview(textScrollView)
        
        textContainerScrollView = UIView()
        textScrollView.addSubview(textContainerScrollView)
        
        pageControl = UIPageControl()
        pageControl.numberOfPages = images.count
        pageControl.pageIndicatorTintColor = UIColor.appBlueColor().withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = UIColor.appBlueColor()
        pageControl.addTarget(self, action: #selector(OnBoardingViewController.pageControlValueChanged(_:)), for: .valueChanged)
        view.addSubview(pageControl)
        
        nextBtn = UIButton(type: .system)
        nextBtn.setImage(UIImage(named: "tour_next"), for: UIControlState())
        nextBtn.addTarget(self, action: #selector(OnBoardingViewController.nextBtnClicked(_:)), for: .touchUpInside)
        view.addSubview(nextBtn)
        
        okBtn = OkButton()
        okBtn.textLbl.text = L("onboarding.ok")
        okBtn.button.addTarget(self, action: #selector(OnBoardingViewController.okBtnClicked(_:)), for: .touchUpInside)
        view.addSubview(okBtn)
        
        configureLayoutConstraints()

        setupScrollViewContent()
        
        setupTextScrollViewContent()
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    fileprivate func setupScrollViewContent() {
        var lastImageView: UIImageView?
        for (index, img) in images.enumerated() {
            let imgView = UIImageView(image: img)
            imgView.contentMode = .center
            containerScrollView.addSubview(imgView)
            imgView.snp.makeConstraints {
                if DeviceType.IS_IPHONE_4_OR_LESS {
                    $0.top.equalTo(containerScrollView).offset(20)
                } else {
                    $0.top.equalTo(containerScrollView).offset(85)
                }
                
                if let last = lastImageView {
                    $0.left.equalTo(last.snp.right)
                } else {
                    $0.left.equalTo(containerScrollView)
                }
                
                $0.width.equalTo(view)
                $0.height.equalTo(view.snp.width).multipliedBy(0.93)
                
                if index == images.count - 1 {
                    $0.right.equalTo(containerScrollView)
                }
            }
            lastImageView = imgView
        }
    }
    
    fileprivate func setupTextScrollViewContent() {
        var lastTextContainerView: UIView?
        for i in 1...3 {
            let textId = String(format: "onboarding.tour%d", i)
            let textContainerView = UIView()
            textContainerScrollView.addSubview(textContainerView)
            let textLbl = textLblWithTitle(L(textId))
            textContainerView.addSubview(textLbl)
            
            textLbl.snp.makeConstraints {
                $0.edges.equalTo(textContainerView).inset(UIEdgeInsets(top: 0, left: 50, bottom: 0, right: -50))
            }
            
            textContainerView.snp.makeConstraints {
                $0.top.equalTo(textContainerScrollView)
                $0.bottom.equalTo(textContainerScrollView)
                
                if let last = lastTextContainerView {
                    $0.left.equalTo(last.snp.right)
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
    
    fileprivate func textLblWithTitle(_ title: String) -> UILabel {
        let textLbl = UILabel()
        textLbl.text = title
        textLbl.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightRegular)
        textLbl.textColor = UIColor.appBlackColor().withAlphaComponent(0.5)
        textLbl.textAlignment = .center
        textLbl.numberOfLines = 0
        textLbl.adjustsFontSizeToFitWidth = true
        return textLbl
    }
    
    fileprivate func configureLayoutConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
        
        containerScrollView.snp.makeConstraints {
            $0.edges.equalTo(scrollView)
            $0.height.equalTo(view)
        }
        
        pageControl.snp.makeConstraints {
            $0.left.equalTo(view)
            $0.right.equalTo(view)
            $0.bottom.equalTo(view).offset(-50)
            $0.height.equalTo(6)
        }
        
        nextBtn.snp.makeConstraints {
            $0.right.equalTo(view).offset(-13)
            $0.centerY.equalTo(pageControl)
            $0.width.equalTo(44)
            $0.height.equalTo(44)
        }
        
        textScrollView.snp.makeConstraints {
            if DeviceType.IS_IPHONE_4_OR_LESS {
                $0.bottom.equalTo(pageControl.snp.top).offset(-35)
            } else {
                $0.bottom.equalTo(pageControl.snp.top).offset(-80)
            }
            $0.left.equalTo(view)
            $0.right.equalTo(view)
            $0.height.equalTo(42);
        }
        
        textContainerScrollView.snp.makeConstraints {
            $0.edges.equalTo(textScrollView)
            $0.height.equalTo(42)
        }
        
        okBtn.snp.makeConstraints {
            $0.width.height.equalTo(60)
            $0.centerX.equalTo(view)
            okBtmConstraint = $0.bottom.equalTo(view).offset(83).constraint
        }
    }
    
    func nextBtnClicked(_ sender: UIButton) {
        let next = pageControl.currentPage + 1
        if next >= images.count {
            return
        }
        pageControl.currentPage = next
        let pageWidth = scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: CGFloat(next) * pageWidth, y: 0), animated: true)
    }
    
    func pageControlValueChanged(_ pageControl: UIPageControl) {
        let pageWidth = scrollView.frame.size.width
        let index = pageControl.currentPage
        scrollView.setContentOffset(CGPoint(x: CGFloat(index) * pageWidth, y: 0), animated: true)
        updateInterface()
    }
    
    fileprivate func updatePageControlIndexBasedOnScrollViewOffset() {
        let pageWidth = scrollView.frame.size.width
        let pageIndex = floor(scrollView.contentOffset.x - pageWidth / 2) / pageWidth + 1
        pageControl.currentPage = Int(pageIndex)
    }
    
    func okBtnClicked(_ sender: UIButton) {
        let controller = DependencyChooserViewController()
        controller.style = .onboarding
        navigationController?.pushViewController(controller, animated: true)
    }

    fileprivate func progressForPageIndex(_ index: Int) -> CGFloat {
        let pageWidth = scrollView.frame.size.width
        let scrollPage = scrollView.contentOffset.x / pageWidth
        let page = pageControl.currentPage
        let progress = scrollPage - CGFloat(page)
        return progress
    }
    
    fileprivate func updateInterface() {
        let index = pageControl.currentPage
        var progress = progressForPageIndex(index)
        if index >= 1 {
            if index == 2 {
                progress = 1 - fabs(progress)
            }
            okBtmConstraint.update(offset: -106.0 * progress + 83.0)
            nextBtn.alpha = 1 - progress
            okBtn.alpha = progress
            pageControl.alpha = 1 - progress
        } else {
            okBtmConstraint.update(offset: 83.0)
            nextBtn.alpha = 1
            pageControl.alpha = 1
            okBtn.alpha = 0
        }
        nextBtn.layoutIfNeeded()
        okBtn.layoutIfNeeded()
        let textOffset = CGPoint(x: scrollView.contentOffset.x, y: 0)
        textScrollView.setContentOffset(textOffset, animated: false)
    }
    
    static func showInController(_ controller: UIViewController, animated: Bool = true) {
        let onBoarding = OnBoardingViewController()
        let nav = PortraitNavigationController(rootViewController: onBoarding)
        nav.statusBarStyle = .default
        nav.modalPresentationStyle = .formSheet
        controller.present(nav, animated: animated, completion: nil)
    }
}

extension OnBoardingViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updatePageControlIndexBasedOnScrollViewOffset()
            updateInterface()
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updatePageControlIndexBasedOnScrollViewOffset()
        updateInterface()
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y != 0 {
            scrollView.contentOffset.y = 0
        }
        updateInterface()
    }
}
