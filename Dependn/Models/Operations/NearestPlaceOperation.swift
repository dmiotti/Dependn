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
import CocoaLumberjack

final class NearestPlaceOperation: SHOperation {
    
    let location: CLLocation
    let distance: CLLocationDistance
    
    fileprivate let context: NSManagedObjectContext
    
    fileprivate(set) var place: Place?
    fileprivate(set) var error: NSError?
    
    init(location: CLLocation, distance: CLLocationDistance) {
        self.location = location
        self.distance = distance
        context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = CoreDataStack.shared.managedObjectContext
    }
    
    override func execute() {
        
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: Record.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        req.predicate = NSPredicate(format: "place != nil AND lat != nil AND lon != nil")
        
        context.performAndWait {
            do {
                let records = try self.context.fetch(req) as! [Record]
                for record in records {
                    if let lat = record.lat?.doubleValue, let lon = record.lon?.doubleValue {
                        let recordLocation = CLLocation(latitude: lat, longitude: lon)
                        let dist = self.location.distance(from: recordLocation)
                        if dist <= self.distance {
                            self.place = record.place
                            break
                        }
                    }
                }
            } catch let err as NSError {
                DDLogError("Error while fetching nearest location: \(err)")
                self.error = err
            }
        }
        
        finish()
    }
}
