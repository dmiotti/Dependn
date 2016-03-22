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

        backgroundColor = UIColor.appBlueColor()
        
        blueBackgroundView = UIView()
        blueBackgroundView.backgroundColor = UIColor.appBlueColor()
        addSubview(blueBackgroundView)

        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.pagingEnabled = true
        scrollView.scrollsToTop = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.directionalLockEnabled = true
        scrollView.alwaysBounceHorizontal = true
        addSubview(scrollView)

        scrollContainerView = UIView()
        scrollView.addSubview(scrollContainerView)
        
        pageControl = UIPageControl()
        pageControl.tintColor = UIColor.whiteColor()
        pageControl.addTarget(self, action: #selector(StatsPanelScroller.pageControlValueChanged(_:)), forControlEvents: .ValueChanged)
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
        
        scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: 0)
        
        performTransform()
    }
    
    
    // Animate the transition between stats
    private func performTransform() {
        let numberOfPages = pageControl.numberOfPages
        let pageWidth = scrollView.frame.size.width
        let currentXOffset = range(scrollView.contentOffset.x, minimum: 0, maximum: pageWidth * CGFloat(numberOfPages))
        
        let currentPage = Int(max(floor(currentXOffset / pageWidth), 0))
        let nextPage = Int(min(currentPage + 1, numberOfPages - 1))
        let interpolation = (currentXOffset - (CGFloat(currentPage) * pageWidth)) / pageWidth
        
        let minScale = CGFloat(0.75)
        let currentCellScale = CGFloat(1 - interpolation) * (1 - minScale) + minScale
        let nextCellScale = CGFloat(interpolation) * (1 - minScale) + minScale
        
        let currentBoard = statsBoards[currentPage]
        let nextBoard = statsBoards[nextPage]
        
        currentBoard.layer.transform = CATransform3DMakeScale(currentCellScale, currentCellScale, 1)
        if currentPage != nextPage {
            nextBoard.layer.transform = CATransform3DMakeScale(nextCellScale, nextCellScale, 1)
        }
    }
    
    /**
     Ranges a value between a maximum and a minimum
     
     - Parameter value:   The value that should be ranged
     - Parameter minimum: The minimum result value
     - Parameter maximum: The maximum result value
     
     - Returns: `minimum` if `value` is less than `minimum`, `maximum` if `value` is more than `value`, `value` otherwise
     */
    func range<T: Comparable>(value: T, minimum: T, maximum: T) -> T {
        return max(min(value, maximum), minimum)
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
            $0.edges.equalTo(self).offset(UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0))
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
