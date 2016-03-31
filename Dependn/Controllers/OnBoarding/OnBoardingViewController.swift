//
//  OnBoardingViewController.swift
//  Dependn
//
//  Created by David Miotti on 30/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit

final class OnBoardingViewController: UIViewController {
    
    private var scrollView: UIScrollView!
    private var containerScrollView: UIView!
    private var pageControl: UIPageControl!
    private var nextBtn: UIButton!
    
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
        view.addSubview(scrollView)
        
        containerScrollView = UIView()
        scrollView.addSubview(containerScrollView)
        
        pageControl = UIPageControl()
        pageControl.numberOfPages = images.count
        pageControl.pageIndicatorTintColor = UIColor.appBlueColor().colorWithAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = UIColor.appBlueColor()
        view.addSubview(pageControl)
        
        nextBtn = UIButton(type: .System)
        nextBtn.setImage(UIImage(named: "tour_next"), forState: .Normal)
        nextBtn.addTarget(self, action: #selector(OnBoardingViewController.nextBtnClicked(_:)), forControlEvents: .TouchUpInside)
        view.addSubview(nextBtn)
        
        configureLayoutConstraints()

        setupScrollViewContent()
    }
    
    private func setupScrollViewContent() {
        var lastImageView: UIImageView?
        for (index, img) in images.enumerate() {
            let imgView = UIImageView(image: img)
            imgView.contentMode = .Center
            containerScrollView.addSubview(imgView)
            imgView.snp_makeConstraints {
                $0.top.equalTo(containerScrollView).offset(85)
                
                if let last = lastImageView {
                    $0.left.equalTo(last.snp_right)
                } else {
                    $0.left.equalTo(containerScrollView)
                }
                
                $0.width.equalTo(view)
                $0.height.equalTo(view.snp_width)
                
                if index == images.count - 1 {
                    $0.right.equalTo(containerScrollView)
                }
            }
            lastImageView = imgView
        }
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
            $0.right.equalTo(view).offset(-40)
            $0.centerY.equalTo(pageControl)
            $0.width.equalTo(9)
            $0.height.equalTo(14)
        }
    }
    
    func nextBtnClicked(sender: UIButton) {
        
    }

}
