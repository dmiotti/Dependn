//
//  CSVImportOperation.swift
//  Dependn
//
//  Created by David Miotti on 08/05/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import SwiftHelpers
import CoreData
import CoreLocation
import BrightFutures
import PKHUD
import CocoaLumberjack

let kImportOperationErrorDomain = "ImportOperation"
let kImportOperationNothingToImportCode = 1
let kImportOperationUserCancelledCode = 2

private let kImportOperationDateFormatter = DateFormatter(dateFormat: "dd/MM/yyyy HH:mm")

final class CSVImportOperation: SHOperation {
    
    fileprivate(set) var error: NSError?
    
    fileprivate let context: NSManagedObjectContext
    fileprivate let controller: UIViewController
    
    fileprivate var cachedPlaces = [Place]()
    
    init(controller: UIViewController) {
        self.controller = controller
        context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = CoreDataStack.shared.managedObjectContext
        super.init()
    }
    
    override func execute() {
        let candidates = getCandidateFiles()
        if candidates.count > 0 {
            ask(for: candidates).onComplete { r in
                if let file = r.value {
                    DispatchQueue.main.async {
                        HUD.show(.progress)
                    }
                    self.context.performAndWait {
                        do {
                            try self.deleteAllRecords()
                            try self.deleteAllAddictions()
                            try self.deleteAllPlaces()
                            try self.importFileAtURL(file)
                        } catch let err as NSError {
                            self.error = err
                        }
                    }
                    self.saveContext()
                    DispatchQueue.main.async {
                        HUD.hide(animated: true) { finished in
                            self.finish()
                        }
                    }
                } else {
                    self.error = r.error
                    self.finish()
                }
            }
        } else {
            self.error = NSError(
                domain: kImportOperationErrorDomain,
                code: kImportOperationNothingToImportCode,
                userInfo: [
                    NSLocalizedDescriptionKey: L("import.no_data"),
                    NSLocalizedRecoverySuggestionErrorKey: L("import.no_data_suggestion")])
            finish()
        }
    }
    
    fileprivate func getCandidateFiles() -> [URL] {
        var candidates = [URL]()
        
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        if let directoryURL = urls.last {
            
            /// List all possible import to the user
            let enumerator = fileManager.enumerator(at: directoryURL,
                                                         includingPropertiesForKeys: nil, options: .skipsHiddenFiles, errorHandler: nil)
            
            while let element = enumerator?.nextObject() as? URL {
                if element.pathExtension == "csv" {
                    candidates.append(element)
                }
            }
        }
        
        return candidates
    }
    
    fileprivate func ask(for files: [URL]) -> Future<URL, NSError> {
        let promise = Promise<URL, NSError>()
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: L("import.choose_file"), message: L("import.choose_file_message"), preferredStyle: .actionSheet)
            
            let actions = files.map { file -> UIAlertAction in
                let filename = file.deletingPathExtension().lastPathComponent
                return UIAlertAction(title: filename, style: .default) { action in
                    promise.success(file)
                }
            }
            actions.forEach(alert.addAction)
            
            let cancelAction = UIAlertAction(title: L("cancel"), style: .cancel) { action in
                let err = NSError(domain: kImportOperationErrorDomain,
                                  code: kImportOperationUserCancelledCode,
                                  userInfo: [NSLocalizedDescriptionKey: L("import.cancelled_by_user"),
                                    NSLocalizedRecoverySuggestionErrorKey: L("import.cancelled_by_user_recovery")])
                promise.failure(err)
            }
            alert.addAction(cancelAction)
            
            self.controller.present(alert, animated: true, completion: nil)
        }
        
        return promise.future
    }
    
    fileprivate func importFileAtURL(_ URL: Foundation.URL) throws {
        let csv = try String(contentsOf: URL, encoding: String.Encoding.utf8)
        let lines = csv.components(
            separatedBy: CharacterSet.newlines)
        for (index, line) in lines.enumerated() {
            if index == 0 {
                continue
            }
            let values = line.components(separatedBy: ";")
            newRecordFromValues(values)
        }
    }
    
    fileprivate func deleteAllRecords() throws {
        let req = Record.entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: true) ]
        let records = try context.fetch(req) as! [Record]
        for r in records {
            context.delete(r)
        }
    }
    
    fileprivate func deleteAllAddictions() throws {
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: Addiction.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        let addictions = try context.fetch(req) as! [Addiction]
        for addiction in addictions {
            context.delete(addiction)
        }
    }
    
    fileprivate func deleteAllPlaces() throws {
        let req = Place.entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: false) ]
        let places = try context.fetch(req) as! [Place]
        for place in places {
            context.delete(place)
        }
    }
    
    fileprivate func getPlaceOrCreate(_ name: String) -> Place {
        do {
            let pred = NSPredicate(format: "name == %@", name)
            let places = try Place.allPlaces(inContext: context, usingPredicate: pred)
            if let first = places.first {
                return first
            }
        } catch let err as NSError {
            print("Error while getting all places: \(err)")
        }
        
        return Place.insertPlace(name, inContext: context)
    }
    
    fileprivate func newRecordFromValues(_ values: [String]) {
        guard values.count >= 9 else {
            return
        }
        
        do {
            let addiction = try Addiction.findOrInsertNewAddiction(values[0], inContext: context)
            
            let daystr = values[1]
            let hourstr = values[2]
            let datestr = "\(daystr) \(hourstr)"
            let date = kImportOperationDateFormatter.date(from: datestr) ?? Date()
            let intensity = NSString(string: values[3]).floatValue
            let placeName = values[4]
            let feeling = values[5]
            let comment = values[6]
            let lat = values[7]
            let lon = values[8]
            let isDesire: Bool
            if values.count > 9 {
                let desire = values[9]
                isDesire = desire.characters.count > 0
            } else {
                isDesire = false
            }
            
            var place: Place? = nil
            if placeName.characters.count > 0 {
                place = getPlaceOrCreate(placeName)
            }
            
            _ = Record.insertNewRecord(
                addiction,
                intensity: intensity,
                feeling: feeling,
                comment: comment,
                place: place,
                latitude: doubleOrNil(lat),
                longitude: doubleOrNil(lon),
                desire: isDesire,
                date: date,
                inContext: context)
        } catch let err as NSError {
            DDLogError("Error while adding new record: \(err)")
        }
    }
    
    fileprivate func doubleOrNil(_ value: String) -> Double? {
        if value.characters.count > 0 {
            return Double(value.floatValue)
        }
        return nil
    }
    
    fileprivate func saveContext() {
        var contextToSave: NSManagedObjectContext? = context
        while let ctx = contextToSave {
            ctx.performAndWait {
                do {
                    if ctx.hasChanges {
                        try ctx.save()
                    }
                    contextToSave = contextToSave?.parent
                } catch let err as NSError {
                    print("Error while saving context: \(err)")
                }
            }
        }
    }
    
}
