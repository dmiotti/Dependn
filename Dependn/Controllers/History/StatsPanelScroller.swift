//
// Created by David Miotti on 08/03/16.
// Copyright (c) 2016 David Miotti. All rights reserved.
//

import Foundation
import UIKit
import SwiftHelpers

final class StatsPanelScroller: SHCommonInitView, UIScrollViewDelegate {

    var addictions = [Addiction]() {
        didSet {
            buildBoard()
        }
    }

    private var scrollView: UIScrollView!
    private var scrollContainerView: UIView!
    private var pageControl: UIPageControl!
    private var blueBackgroundView: UIView!

    override func commonInit() {
        super.commonInit()

        backgroundColor = UIColor(r: 52, g: 167, b: 230, a: 1)
        
        blueBackgroundView = UIView()
        blueBackgroundView.backgroundColor = UIColor(r: 52, g: 167, b: 230, a: 1)
        addSubview(blueBackgroundView)

        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.directionalLockEnabled = true
        scrollView.alwaysBounceHorizontal = true
        addSubview(scrollView)

        scrollContainerView = UIView()
        scrollView.addSubview(scrollContainerView)
        
        pageControl = UIPageControl()
        pageControl.tintColor = UIColor.whiteColor()
        pageControl.addTarget(self, action: "pageControlValueChanged:", forControlEvents: .ValueChanged)
        addSubview(pageControl)

        configureLayoutConstraints()
    }
    
    func pageControlValueChanged(pc: UIPageControl) {
        var offset = scrollView.contentOffset
        offset.x = CGFloat(pc.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(offset, animated: true)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        let pageWidth = scrollView.frame.size.width
        let frac = offset.x / pageWidth
        let page = Int(lround(Double(frac)))
        pageControl.currentPage = page
    }
    
    private var statsBoards = [StatsPanelView]()

    private func buildBoard() {
        for board in statsBoards {
            board.removeFromSuperview()
        }
        
        statsBoards.removeAll()
        
        pageControl.numberOfPages = addictions.count
        
        for (index, addiction) in addictions.enumerate() {
            let board = StatsPanelView()
            board.updateWithAddiction(addiction)
            scrollContainerView.addSubview(board)
            board.snp_makeConstraints {
                $0.top.equalTo(scrollContainerView)
                $0.bottom.equalTo(scrollContainerView)
                $0.width.equalTo(self)
                
                if let last = statsBoards.last {
                    $0.left.equalTo(last.snp_right)
                } else {
                    $0.left.equalTo(scrollContainerView)
                }
                
                if index == addictions.count - 1 {
                    $0.right.equalTo(scrollContainerView)
                }
            }
            statsBoards.append(board)
        }
        
        layoutIfNeeded()
    }

    private func configureLayoutConstraints() {
        blueBackgroundView.snp_makeConstraints {
            $0.bottom.equalTo(self.snp_top)
            $0.left.equalTo(self)
            $0.right.equalTo(self)
            $0.height.equalTo(480)
        }
        
        scrollView.snp_makeConstraints {
            $0.edges.equalTo(self)
        }
        
        scrollContainerView.snp_makeConstraints {
            $0.edges.equalTo(scrollView)
            $0.height.equalTo(self)
        }
        
        pageControl.snp_makeConstraints {
            $0.left.equalTo(self)
            $0.right.equalTo(self)
            $0.height.equalTo(6)
            $0.bottom.equalTo(self).offset(-15)
        }
    }
}
