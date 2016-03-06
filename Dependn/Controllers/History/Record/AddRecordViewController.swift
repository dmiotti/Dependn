//
//  AddRecordViewController.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SnapKit

enum AddRecordSectionType: Int {
    case Addiction
    case DateAndPlace
    case Intensity
    case Optionals
    
    static let count: Int = {
        var max: Int = 0
        while let _ = AddRecordSectionType(rawValue: max) { max += 1 }
        return max
    }()
}

final class AddRecordViewController: UIViewController {
    
    private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: .zero, style: .Grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        view.addSubview(tableView)
        
        configureLayoutConstraints()
    }
    
    private func configureLayoutConstraints() {
        tableView.snp_makeConstraints {
            $0.edges.equalTo(view)
        }
    }

}

extension AddRecordViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return AddRecordSectionType.count
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let type = AddRecordSectionType(rawValue: section)!
        switch type {
        case .Addiction:    break
        case .DateAndPlace: break
        case .Intensity:    break
        case .Optionals: 	break
        }
        return 0
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UITableViewCell", forIndexPath: indexPath)
        return cell
    }
}

extension AddRecordViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}