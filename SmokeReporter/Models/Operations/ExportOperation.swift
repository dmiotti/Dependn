//
//  ExportOperation.swift
//  SmokeReporter
//
//  Created by David Miotti on 23/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData

private let kExportOperationSeparator = ";"
private let kExportOperationNewLine = "\n"

final class ExportOperation: SHOperation {
    
    var exportedPath: String?
    var error: NSError?
    
    private let context: NSManagedObjectContext
    private let dayFormatter: NSDateFormatter
    private let hourFormatter: NSDateFormatter
    
    override init() {
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
        dayFormatter = NSDateFormatter(dateFormat: "dd/MM/yyyy")
        hourFormatter = NSDateFormatter(dateFormat: "HH:mm")
        super.init()
    }
    
    override func execute() {
        
        context.performBlockAndWait {
            do {
                let req = NSFetchRequest(entityName: Smoke.entityName)
                req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: true) ]
                let smokes = try self.context.executeFetchRequest(req) as! [Smoke]

                let path = self.exportPath()
                let csv = self.createCSV(smokes)
                
                try csv.writeToFile(path,
                    atomically: true,
                    encoding: NSUTF8StringEncoding)
                
                self.exportedPath = path
            } catch let err as NSError {
                self.error = err
            }
        }

        finish()
    }
    
    private func createCSV(smokes: [Smoke]) -> String {
        let header = [
            L("Date"),
            L("Hour"),
            L("Kind"),
            L("Intensity"),
            L("FeelingBefore"),
            L("FeelingAfter"),
            L("Comment") ]
            .joinWithSeparator(kExportOperationSeparator)
        
        let content = smokes.map({ recordToCSV($0) })
            .joinWithSeparator(kExportOperationNewLine)
        return header + kExportOperationNewLine
            + content + kExportOperationNewLine
    }
    
    private func recordToCSV(smoke: Smoke) -> String {
        let date = smoke.date
        let values = [
            dayFormatter.stringFromDate(date),
            hourFormatter.stringFromDate(date),
            smoke.kind,
            String(format: "%.1f", arguments: [ smoke.intensity.floatValue ]),
            smoke.feelingBefore ?? "",
            smoke.feelingAfter ?? "",
            smoke.comment ?? ""
        ]
        return values.joinWithSeparator(kExportOperationSeparator)
    }
    
    private func exportPath() -> String {
        let fileUUID = NSUUID().UUIDString
        return applicationCachesDirectory
            .URLByAppendingPathComponent(fileUUID)
            .URLByAppendingPathExtension("csv").path!
    }
    
    private lazy var applicationCachesDirectory: NSURL = {
        let urls = NSFileManager.defaultManager()
            .URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

}
