//
//  InitialImportPlacesOperation.swift
//  Dependn
//
//  Created by David Miotti on 10/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData
import SwiftyUserDefaults

final class InitialImportPlacesOperation: CoreDataOperation {
    
    let placeNames = [
        L("suggested.places.wakeup"),
        L("suggested.places.coffee"),
        L("suggested.places.ontheway"),
        L("suggested.places.beforelunch"),
        L("suggested.places.afterlunch"),
        L("suggested.places.infront_computer"),
        L("suggested.places.workbreak"),
        L("suggested.places.phone"),
        L("suggested.places.waiting"),
        L("suggested.places.inthecar"),
        L("suggested.places.watchingmovie"),
        L("suggested.places.withfriends")
    ]
    
    override func execute() {
        context.performBlockAndWait {
            do {
                for name in self.placeNames {
                    if try Place.findByName(name, inContext: self.context) == nil {
                        Place.insertPlace(name, inContext: self.context)
                    }
                }
                Defaults[.initialPlacesImported] = true
            } catch let err as NSError {
                print("Error while adding place: \(err)")
                self.error = err
            }
        }
        
        saveContext()
        
        finish()
    }
    
    private func saveContext() {
        var contextToSave: NSManagedObjectContext? = context
        while let ctx = contextToSave {
            ctx.performBlockAndWait {
                do {
                    if ctx.hasChanges {
                        try ctx.save()
                    }
                    contextToSave = contextToSave?.parentContext
                } catch let err as NSError {
                    print("Error while saving context: \(err)")
                }
            }
        }
    }
    
    static func shouldImportPlaces() -> Bool {
        return !Defaults[.initialPlacesImported]
    }

}
