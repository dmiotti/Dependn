//
//  Record.swift
//  Dependn
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData

final class Record: NSManagedObject, NamedEntity {
    static var entityName = "Record"
    
    static let sectionDateFormatter = NSDateFormatter(dateFormat: "EEEE d MMMM yyyy")
    
    var sectionIdentifier: String? {
        return Record.sectionDateFormatter.stringFromDate(date)
    }
    
}
