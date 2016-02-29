//
//  Record+CoreDataProperties.swift
//  Dependn
//
//  Created by David Miotti on 25/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Record {

    @NSManaged var comment: String?
    @NSManaged var date: NSDate
    @NSManaged var after: String?
    @NSManaged var before: String?
    @NSManaged var intensity: NSNumber
    @NSManaged var type: String
    @NSManaged var place: String?
    @NSManaged var lat: NSNumber?
    @NSManaged var lon: NSNumber?

}
