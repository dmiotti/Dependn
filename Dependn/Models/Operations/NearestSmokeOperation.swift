//
//  NearestPlaceOperation.swift
//  Dependn
//
//  Created by David Miotti on 29/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData
import CoreLocation

final class NearestPlaceOperation: SHOperation {
    
    let location: CLLocation
    let distance: CLLocationDistance
    
    private let context: NSManagedObjectContext
    
    private(set) var place: String?
    private(set) var error: NSError?
    
    init(location: CLLocation, distance: CLLocationDistance) {
        self.location = location
        self.distance = distance
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
    }
    
    override func execute() {
        
        let req = NSFetchRequest(entityName: Record.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        req.predicate = NSPredicate(format: "place != nil AND lat != nil AND lon != nil")
        
        context.performBlockAndWait {
            do {
                let records = try self.context.executeFetchRequest(req) as! [Record]
                for record in records {
                    if let lat = record.lat?.doubleValue, lon = record.lon?.doubleValue {
                        let recordLocation = CLLocation(latitude: lat, longitude: lon)
                        let dist = self.location.distanceFromLocation(recordLocation)
                        if dist <= self.distance {
                            self.place = record.place
                            break
                        }
                    }
                }
            } catch let err as NSError {
                self.error = err
            }
        }
        
        finish()
    }
}
