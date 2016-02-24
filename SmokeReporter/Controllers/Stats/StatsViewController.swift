//
//  StatsViewController.swift
//  SmokeReporter
//
//  Created by David Miotti on 24/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

enum StatsRowType: Int {
    case GlobalCount
    case Version
    static let count: Int = {
        var max: Int = 0
        while let _ = StatsRowType(rawValue: max) { max += 1 }
        return max
    }()
}

struct StatsModel {
    var total = 0
    var avgPerDay = 0
}

final class StatsViewController: UIViewController {
    
    private var tableView: UITableView!
    private var refreshBtn: UIBarButtonItem!
    private var loadingView: UIActivityIndicatorView!
    private var loadingBtn: UIBarButtonItem!
    
    private var model = StatsModel()
    private let operationQueue = NSOperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L("Stats")
        
        refreshBtn = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refreshBtnClicked:")
        navigationItem.rightBarButtonItem = refreshBtn
        
        loadingView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        loadingBtn = UIBarButtonItem(customView: loadingView)
        
        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(StatsCell.self, forCellReuseIdentifier: StatsCell.reuseIdentifier)
        view.addSubview(tableView)
        
        configureLayoutConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        refreshStats()
    }
    
    // MARK: - Refresh
    
    func refreshBtnClicked(sender: UIBarButtonItem) {
        refreshStats()
    }
    
    // MARK: - Compute stats
    
    private func refreshStats() {
        operationQueue.cancelAllOperations()
        
        navigationItem.setRightBarButtonItem(loadingBtn, animated: true)
        loadingView.startAnimating()
        
        let countOp = CountOperation()
        countOp.completionBlock = {
            dispatch_async(dispatch_get_main_queue()) {
                if let total = countOp.total {
                    self.model.total = total
                    self.tableView.reloadData()
                }
                self.navigationItem.setRightBarButtonItem(self.refreshBtn, animated: true)
            }
        }
        
        operationQueue.addOperation(countOp)
    }
    
    // MARK: - Configure Layout Constraints
    
    private func configureLayoutConstraints() {
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }

}

extension StatsViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StatsRowType.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(StatsCell.reuseIdentifier, forIndexPath: indexPath)
        configureCell(cell, forIndexPath: indexPath)
        return cell
    }
    private func configureCell(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? StatsCell, row = StatsRowType(rawValue: indexPath.row) {
            switch row {
            case .GlobalCount:
                cell.titleLbl.text = L("Total")
                cell.valueLbl.text = "\(model.total)"
            case .Version:
                cell.titleLbl.text = L("Version")
                cell.valueLbl.text = appVersion()
            }
        }
    }
}

extension StatsViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
