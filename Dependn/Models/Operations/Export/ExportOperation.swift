//
//  ExportOperation.swift
//  Dependn
//
//  Created by David Miotti on 08/05/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import SwiftHelpers
import PKHUD
import BrightFutures

final class ExportOperation: SHOperation {
    
    private let controller: UIViewController
    private let internalQueue = NSOperationQueue()
    
    init(controller: UIViewController) {
        self.controller = controller
        super.init()
    }
    
    override func execute() {
        dispatch_async(dispatch_get_main_queue()) {
            self.ensureExportXLSIsPurchased { purchased in
                if purchased {
                    self.launchXLSExport().onComplete { r in
                        if let path = r.value {
                            let URL = NSURL(fileURLWithPath: path)
                            let doc = UIDocumentInteractionController(URL: URL)
                            doc.delegate = self
                            doc.presentPreviewAnimated(true)
                        } else if let err = r.error {
                            HUD.flash(HUDContentType.Label(err.localizedDescription))
                        }
                        Analytics.instance.trackExport(true)
                        self.finish()
                    }
                } else {
                    Analytics.instance.trackExport(false)
                    self.finish()
                }
            }
        }
    }
    
    private func launchXLSExport() -> Future<String, NSError> {
        let promise = Promise<String, NSError>()
        
        HUD.show(.Progress)
        let path = exportPath()
        let exportOp = XLSExportOperation(path: path)
        exportOp.completionBlock = {
            dispatch_async(dispatch_get_main_queue()) {
                HUD.hide(animated: true) { finished in
                    if let err = exportOp.error {
                        promise.failure(err)
                    } else {
                        promise.success(path)
                    }
                }
            }
        }
        internalQueue.addOperation(exportOp)
        
        return promise.future
        
    }
    
    private func ensureExportXLSIsPurchased(completion: Bool -> Void) {
        let isPurchased = DependnProducts.store.isProductPurchased(DependnProducts.ExportXLS)
        if isPurchased {
            completion(isPurchased)
        } else {
            HUD.show(.Progress)
            DependnProducts.store.requestProducts{ success, products in
                HUD.hide { finished in
                    if let products = products {
                        let exportProducts = products.filter {
                            $0.productIdentifier == DependnProducts.ExportXLS
                        }
                        if let product = exportProducts.first {
                            let alert = UIAlertController(title: L("export.title"), message: L("export.message"), preferredStyle: .Alert)
                            let okAction = UIAlertAction(title: L("yes"), style: .Default) { action in
                                DependnProducts.store.buyProduct(product) { succeed, error in
                                    completion(succeed)
                                }
                            }
                            let cancelAction = UIAlertAction(title: L("no"), style: .Cancel, handler: nil)
                            alert.addAction(cancelAction)
                            alert.addAction(okAction)
                            self.controller.presentViewController(alert, animated: true, completion: nil)
                            
                            return
                        }
                    }
                    completion(false)
                }
            }
        }
    }
    
    private func exportPath() -> String {
        let dateFormatter = NSDateFormatter(dateFormat: "dd'_'MM'_'yyyy'_'HH'_'mm")
        let filename = "export_\(dateFormatter.stringFromDate(NSDate()))"
        return applicationCachesDirectory
            .URLByAppendingPathComponent(filename)
            .URLByAppendingPathExtension("xlsx").path!
    }
    
    private lazy var applicationCachesDirectory: NSURL = {
        let urls = NSFileManager.defaultManager()
            .URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

}

// MARK: - UIDocumentInteractionControllerDelegate
extension ExportOperation: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return self.controller
    }
}
