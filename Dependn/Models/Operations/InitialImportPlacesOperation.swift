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
        L("suggested.places.workbreak"),
        L("suggested.places.phone"),
        L("suggested.places.waiting"),
        L("suggested.places.inthecar"),
        L("suggested.places.watchingmovie"),
        L("suggested.places.withfriends"),
        L("suggested.places.watchingmovie")
    ]
    
    override func execute() {
        context.performBlockAndWait {
            for name in self.placeNames {
                Place.insertPlace(name, inContext: self.context)
            }
            
            do {
                try self.context.cascadeSave()
                Defaults[.initialPlacesImported] = true
            } catch let err as NSError {
                print("Error while saving context: \(err)")
                self.error = err
            }
        }
        
        finish()
    }
    
    static func shouldImportPlaces() -> Bool {
        return !Defaults[.initialPlacesImported]
    }

}
