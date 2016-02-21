//
//  Smoke+CoreDataProperties.swift
//  SmokeReporter
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Smoke {

    @NSManaged var date: NSDate
    @NSManaged var feelingAfter: String?
    @NSManaged var feelingBefore: String?
    @NSManaged var intensity: NSNumber
    @NSManaged var kind: String
    @NSManaged var comment: String?

}
