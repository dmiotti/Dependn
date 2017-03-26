//
//  Record+CoreDataProperties.swift
//  Dependn
//
//  Created by David Miotti on 05/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Record {

    @NSManaged var feeling: String?
    @NSManaged var comment: String?
    @NSManaged var date: Date
    @NSManaged var intensity: NSNumber
    @NSManaged var lat: NSNumber?
    @NSManaged var lon: NSNumber?
    @NSManaged var place: Place?
    @NSManaged var addiction: Addiction
    @NSManaged var desire: NSNumber

}
