//
//  WatchAddInfoOperation.swift
//  Dependn
//
//  Created by David Miotti on 27/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

struct WatchAddictionModel {
    let uri: String
    let name: String
}

struct WatchPlaceModel {
    let uri: String
    let name: String
}

final class WatchAddInfo {
    var addictions = [WatchAddictionModel]()
    var places = [WatchPlaceModel]()
}

final class WatchNewEntryInfoOperation: CoreDataOperation {
    
    var watchInfo: WatchAddInfo?
    
    override func execute() {
        
        do {
            /// The final results if no error occurs
            let info = WatchAddInfo()
            
            /// Need all addictions
            let addictions = try Addiction.getAllAddictions(inContext: context)
            
            /// For each addiction, get the name and and image
            for addiction in addictions {
                let name = addiction.name
                let addictionPath = addiction.objectID.URIRepresentation().absoluteString
                let model = WatchAddictionModel(uri: addictionPath, name: name)
                info.addictions.append(model)
            }
            
            /// Fetch all places
            let places = try Place.allPlaces(inContext: context)
            info.places = places.map {
                WatchPlaceModel(uri: $0.objectID.URIRepresentation().absoluteString, name: $0.name)
            }
            
            watchInfo = info
            
        } catch let err as NSError {
            error = err
        }
        
        finish()
    }
    
    static func formatNewEntryResultsForAppleWatch(result: WatchAddInfo) -> WatchDictionary {
        var dict = WatchDictionary()
        
        var addictions = [WatchDictionary]()
        for element in result.addictions {
            var addiction = WatchDictionary()
            addiction["name"] = element.name
            addiction["uri"] = element.uri
            addictions.append(addiction)
        }
        dict["addictions"] = addictions
        
        var places = [WatchDictionary]()
        for element in result.places {
            var place = WatchDictionary()
            place["name"] = element.name
            place["uri"] = element.uri
            places.append(place)
        }
        dict["places"] = places
        
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
