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
    case AveragePerDay
    case AverageBtwTakes
    case AverageIntensity
    case GlobalCount
    case Version
    static let count: Int = {
        var max: Int = 0
        while let _ = StatsRowType(rawValue: max) { max += 1 }
        return max
    }()
}

struct StatsModel {
    var total: Int?
    var avgPerDay: Float?
    var avgBtwTakes: NSTimeInterval?
    var avgIntensity: Float?
}

final class StatsViewController: UIViewController {
    
    private var tableView: UITableView!
    private var refreshBtn: UIBarButtonItem!
    private var loadingView: UIActivityIndicatorView!
    private var loadingBtn: UIBarButtonItem!
    
    private var model = StatsModel()
    private let operationQueue = NSOperationQueue()
    private lazy var numberFormatter: NSNumberFormatter = {
        let fmt = NSNumberFormatter()
        fmt.numberStyle = .DecimalStyle
        fmt.maximumFractionDigits = 1
        return fmt
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L("stats.title")
        
        refreshBtn = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refreshBtnClicked:")
        navigationItem.rightBarButtonItem = refreshBtn
        
        loadingView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        loadingBtn = UIBarButtonItem(customView: loadingView)
        
        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.backgroundColor = UIColor.lightBackgroundColor()
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
            self.model.total = countOp.total
        }
        
        let avgOp = AveragePerDayOperation()
        avgOp.completionBlock = {
            self.model.avgPerDay = avgOp.average
        }
        
        let avgBtw2TakesOp = AverageTimeInBetweenTwoTakesOperation()
        avgBtw2TakesOp.completionBlock = {
            self.model.avgBtwTakes = avgBtw2TakesOp.average
        }
        
        let avgIntensityOp = AverageIntensityOperation()
        avgIntensityOp.completionBlock = {
            self.model.avgIntensity = avgIntensityOp.average
        }
        
        let finishOp = NSBlockOperation {
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
                self.navigationItem.setRightBarButtonItem(self.refreshBtn, animated: true)
            }
        }
        finishOp.addDependency(avgIntensityOp)
        finishOp.addDependency(countOp)
        finishOp.addDependency(avgOp)
        finishOp.addDependency(avgBtw2TakesOp)
        
        operationQueue.addOperation(countOp)
        operationQueue.addOperation(avgOp)
        operationQueue.addOperation(avgBtw2TakesOp)
        operationQueue.addOperation(avgIntensityOp)
        operationQueue.addOperation(finishOp)
    }
    
    // MARK: - Configure Layout Constraints
    
    private func configureLayoutConstraints() {
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    // MARK: - Private Helpers
    
    private func stringFromTimeInterval(interval: NSTimeInterval) -> String {
        let interval = Int(interval)
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        var str = String()
        if hours > 0 {
            str += String(format:"%02dh", hours)
        }
        if minutes > 0 {
            str += String(format:" %02dm", minutes)
        }
        return str
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
            cell.valueLbl.text = L("stats.not_available")
            switch row {
            case .AveragePerDay:
                cell.titleLbl.text = L("stats.average_per_day")
                if let avg = model.avgPerDay {
                    cell.valueLbl.text = numberFormatter.stringFromNumber(avg)
                }
            case .AverageBtwTakes:
                cell.titleLbl.text = L("stats.average_btw_takes")
                if let avg = model.avgBtwTakes {
                    cell.valueLbl.text = stringFromTimeInterval(avg)
                }
            case .AverageIntensity:
                cell.titleLbl.text = L("stats.average_intensity")
                if let avg = model.avgIntensity {
                    cell.valueLbl.text = numberFormatter.stringFromNumber(avg)
                }
            case .GlobalCount:
                cell.titleLbl.text = L("stats.total")
                if let total = model.total {
                    cell.valueLbl.text = numberFormatter.stringFromNumber(total)
                }
            case .Version:
                cell.titleLbl.text = L("stats.version")
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
