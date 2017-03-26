//
//  XLSExportOperation.swift
//  Dependn
//
//  Created by David Miotti on 07/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData
import xlsxwriter

private let kExportOperationDayFormatter = DateFormatter(dateFormat: "dd/MM/yyyy")
private let kExportOperationHourFormatter = DateFormatter(dateFormat: "HH:mm")

final class XLSExportOperation: CoreDataOperation {
    
    let path: String
    
    init(path: String) {
        self.path = path
    }
    
    override func execute() {
        
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch let err as NSError {
                print("Error while deleting file \(path): \(err)")
                error = err
                return
            }
            
        }
        
        context.performAndWait {
            
            let headers = [
                L("export.date"),
                L("export.time"),
                L("export.intensity"),
                L("export.place"),
                L("export.feeling"),
                L("export.comment"),
                L("export.desire"),
                L("export.conso")
            ]
            
            do {
                let addictions = try Addiction.getAllAddictionsOrderedByCount(inContext: self.context)

                let workbook = new_workbook(self.path)
                
                let bold = workbook_add_format(workbook)
                format_set_bold(bold)
                
                for addiction in addictions {
                    
                    // Build xlsx header
                    let name = addiction.name
                    let worksheet = workbook_add_worksheet(workbook, name)
                    worksheet_set_column(worksheet, 0, UInt16(headers.count), 15, nil)
                    
                    // Add the addiction name
                    worksheet_write_string(worksheet, 0, 0, name, bold)
                    
                    var rowIdx = 2
                    
                    for (colIdx ,header) in headers.enumerated() {
                        worksheet_write_string(
                            worksheet,
                            UInt32(rowIdx), UInt16(colIdx),
                            header, bold)
                    }
                    
                    rowIdx += 1
                    
                    let req = NSFetchRequest<NSFetchRequestResult>(entityName: Record.entityName)
                    req.predicate = NSPredicate(format: "addiction == %@", addiction)
                    req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
                    let records = try self.context.fetch(req) as! [Record]
                    
                    for (recIdx, record) in records.enumerated() {
                        let values = self.recordToValues(record)
                        for (colIdx, value) in values.enumerated() {
                            worksheet_write_string(worksheet,
                                UInt32(rowIdx + recIdx), UInt16(colIdx), value, nil)
                        }
                    }
                }
                
                workbook_close(workbook)
                
                
            } catch let err as NSError {
                print("Error exporting xlsx: \(err)")
                self.error = err
            }
            
        }
        
        finish()
    }
    
    fileprivate func recordToValues(_ record: Record) -> [String] {
        let date = record.date
        return [
            kExportOperationDayFormatter.string(from: date as Date),
            kExportOperationHourFormatter.string(from: date as Date),
            String(format: "%.1f", arguments: [ record.intensity.floatValue ]),
            record.place?.name.firstLetterCapitalization ?? "",
            record.feeling ?? "",
            record.comment ?? "",
            record.desire.boolValue ? L("export.choosen") : "",
            record.desire.boolValue ? "" : L("export.choosen")
        ]
    }

}
