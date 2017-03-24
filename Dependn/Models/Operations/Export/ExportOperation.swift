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
    
    fileprivate let controller: UIViewController
    fileprivate let internalQueue = OperationQueue()
    
    init(controller: UIViewController) {
        self.controller = controller
        super.init()
    }
    
    override func execute() {
        DispatchQueue.main.async {
            self.ensureExportXLSIsPurchased { purchased in
                if purchased {
                    self.launchXLSExport().onComplete { r in
                        if let path = r.value {
                            let url = URL(fileURLWithPath: path)
                            let doc = UIDocumentInteractionController(url: url)
                            doc.delegate = self
                            doc.presentPreview(animated: true)
                        } else if let err = r.error {
                            HUD.flash(.label(err.localizedDescription))
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
    
    fileprivate func launchXLSExport() -> Future<String, NSError> {
        let promise = Promise<String, NSError>()

        HUD.show(.progress)
        let path = exportPath()
        let exportOp = XLSExportOperation(path: path)
        exportOp.completionBlock = {
            DispatchQueue.main.async {
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
    
    fileprivate func ensureExportXLSIsPurchased(_ completion: @escaping (Bool) -> Void) {
        let isPurchased = DependnProducts.store.isProductPurchased(DependnProducts.ExportXLS)
        if isPurchased {
            completion(isPurchased)
        } else {
            HUD.show(.progress)
            DependnProducts.store.requestProducts{ success, products in
                HUD.hide { finished in
                    if let products = products {
                        let exportProducts = products.filter {
                            $0.productIdentifier == DependnProducts.ExportXLS
                        }
                        if let product = exportProducts.first {
                            let alert = UIAlertController(title: L("export.title"), message: L("export.message"), preferredStyle: .alert)
                            let okAction = UIAlertAction(title: L("yes"), style: .default) { action in
                                DependnProducts.store.buyProduct(product) { succeed, error in
                                    completion(succeed)
                                }
                            }
                            let cancelAction = UIAlertAction(title: L("no"), style: .cancel, handler: nil)
                            alert.addAction(cancelAction)
                            alert.addAction(okAction)
                            self.controller.present(alert, animated: true, completion: nil)
                            
                            return
                        }
                    }
                    completion(false)
                }
            }
        }
    }
    
    fileprivate func exportPath() -> String {
        let dateFormatter = DateFormatter(dateFormat: "dd'_'MM'_'yyyy'_'HH'_'mm")
        let filename = "export_\(dateFormatter.string(from: NSDate() as Date))"
        return applicationCachesDirectory.appendingPathComponent(filename).appendingPathComponent("xlsx").path
    }
    
    fileprivate lazy var applicationCachesDirectory: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

}

// MARK: - UIDocumentInteractionControllerDelegate
extension ExportOperation: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self.controller
    }
}
