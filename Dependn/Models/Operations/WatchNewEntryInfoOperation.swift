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
        dict["name"] = name
        dict["uri"] = uri
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
                WatchSimpleModel(uri: $0.objectID.URIRepresentation().absoluteString, name: $0.name)
            }
            
            info.mostUsedAddiction = addictionModels.first
            info.addictions = addictionModels
            
            /// Fetch all places
            let places = try Place.getAllPlacesOrderedByCount(inContext: context)
            
            let placeModels = places.map {
                WatchSimpleModel(uri: $0.objectID.URIRepresentation().absoluteString, name: $0.name)
            }
            
            info.mostUsedPlace = placeModels.first
            info.places = placeModels.sort { $0.name < $1.name }
            
            watchInfo = info
            
        } catch let err as NSError {
            error = err
        }
        
        finish()
    }
    
    static func formatNewEntryResultsForAppleWatch(result: WatchAddInfo) -> WatchDictionary {
        var dict = WatchDictionary()
        
        dict["addictions"] = result.addictions.map {
            $0.watchDictionaryRepresentation()
        }
        
        dict["places"] = result.places.map {
            $0.watchDictionaryRepresentation()
        }
        
        if let mostUsedAddiction = result.mostUsedAddiction {
            dict["most_used_addiction"] = mostUsedAddiction.watchDictionaryRepresentation()
        }
        
        if let mostUsedPlace = result.mostUsedPlace {
            dict["most_used_place"] = mostUsedPlace.watchDictionaryRepresentation()
        }
        
        return dict
    }
    
    private func createIconImageWithName(name: String, color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 30, height: 30), false, 0.0)
        
        if let context = UIGraphicsGetCurrentContext() {
            
            let circleView = RecordCircleTypeView()
            circleView.color = color
            if let first = name.capitalizedString.characters.first {
                circleView.textLbl.text = "\(first)"
            }
            circleView.layer.renderInContext(context)
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            return image
        }
        
        return nil
    }

}
