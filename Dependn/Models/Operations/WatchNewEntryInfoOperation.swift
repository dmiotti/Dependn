//
//  WatchAddInfoOperation.swift
//  Dependn
//
//  Created by David Miotti on 27/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

struct WatchSimpleModel {
    let uri: String
    let name: String
    
    func watchDictionaryRepresentation() -> WatchDictionary {
        var dict = WatchDictionary()
        dict["name"] = name as AnyObject?
        dict["uri"] = uri as AnyObject?
        return dict
    }
}

final class WatchAddInfo {
    var addictions = [WatchSimpleModel]()
    var places = [WatchSimpleModel]()
    var mostUsedAddiction: WatchSimpleModel?
    var mostUsedPlace: WatchSimpleModel?
}

final class WatchNewEntryInfoOperation: CoreDataOperation {
    
    var watchInfo: WatchAddInfo?
    
    override func execute() {
        
        do {
            /// The final results if no error occurs
            let info = WatchAddInfo()
            
            /// Need all addictions
            let addictions = try Addiction.getAllAddictionsOrderedByCount(inContext: context)
            
            let addictionModels = addictions.map {
                WatchSimpleModel(uri: $0.objectID.uriRepresentation().absoluteString, name: $0.name)
            }
            
            info.mostUsedAddiction = addictionModels.first
            info.addictions = addictionModels
            
            /// Fetch all places
            let places = try Place.getAllPlacesOrderedByCount(inContext: context)
            
            let placeModels = places.map {
                WatchSimpleModel(uri: $0.objectID.uriRepresentation().absoluteString, name: $0.name)
            }
            
            info.mostUsedPlace = placeModels.first
            info.places = placeModels.sorted { $0.name < $1.name }
            
            watchInfo = info
            
        } catch let err as NSError {
            error = err
        }
        
        finish()
    }
    
    static func formatNewEntryResultsForAppleWatch(_ result: WatchAddInfo) -> WatchDictionary {
        var dict = WatchDictionary()
        
        dict["addictions"] = result.addictions.map {
            $0.watchDictionaryRepresentation()
        }
        
        dict["places"] = result.places.map {
            $0.watchDictionaryRepresentation()
        }
        
        if let mostUsedAddiction = result.mostUsedAddiction {
            dict["most_used_addiction"] = mostUsedAddiction.watchDictionaryRepresentation() as AnyObject?
        }
        
        if let mostUsedPlace = result.mostUsedPlace {
            dict["most_used_place"] = mostUsedPlace.watchDictionaryRepresentation() as AnyObject?
        }
        
        return dict
    }
    
    fileprivate func createIconImageWithName(_ name: String, color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 30, height: 30), false, 0.0)
        
        if let context = UIGraphicsGetCurrentContext() {
            
            let circleView = RecordCircleTypeView()
            circleView.color = color
            if let first = name.capitalized.characters.first {
                circleView.textLbl.text = "\(first)"
            }
            circleView.layer.render(in: context)
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            return image
        }
        
        return nil
    }

}
