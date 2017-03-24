//
//  CoreDataOperation.swift
//  Dependn
//
//  Created by David Miotti on 27/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData

class CoreDataOperation: SHOperation {
    
    internal let context: NSManagedObjectContext
    
    var error: NSError?
    
    override init() {
        context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = CoreDataStack.shared.managedObjectContext
    }

}
