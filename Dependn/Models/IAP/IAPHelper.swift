//
//  IAPHelper.swift
//  Dependn
//
//  Created by David Miotti on 05/05/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> ()
public typealias ProductsPurchaseCompletionHandler = ((Bool, NSError?) -> Void)

open class IAPHelper: NSObject {
    
    static let IAPHelperPurchaseNotification = "IAPHelperPurchaseNotification"
    
    fileprivate let productIdentifiers: Set<ProductIdentifier>
    
    fileprivate var purchasedProductIdentifiers = Set<ProductIdentifier>()
    
    fileprivate var productsRequest: SKProductsRequest?
    fileprivate var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    
    fileprivate var purchaseCompletionHandler: ProductsPurchaseCompletionHandler?
    fileprivate var restoreCompletionHandler: ProductsPurchaseCompletionHandler?
    
    fileprivate var allProducts: [SKProduct]?
    
    init(productIds: Set<ProductIdentifier>) {
        productIdentifiers = productIds
        
        for productIdentifier in productIds {
            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
            }
        }
        
        super.init()
        
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
}

// MARK: - StoreKit API

extension IAPHelper {
    
    public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func buyProduct(_ product: SKProduct, completion: @escaping ProductsPurchaseCompletionHandler) {
        purchaseCompletionHandler = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases(_ completion: @escaping ProductsPurchaseCompletionHandler) {
        restoreCompletionHandler = completion
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        allProducts = products
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    fileprivate func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                completeTransaction(transaction)
                break
            case .failed:
                failedTransaction(transaction)
                break
            case .restored:
                restoreTransaction(transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            }
        }
    }
    
    fileprivate func completeTransaction(_ transaction: SKPaymentTransaction) {
        let productIdentifier = transaction.payment.productIdentifier
        deliverPurchaseNotificatioForIdentifier(productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
        
        if let product = allProducts?.filter({ $0.productIdentifier == productIdentifier }).first {
            if let URL = Bundle.main.appStoreReceiptURL, let receipt = try? Data(contentsOf: URL) {
                Analytics.instance.trackRevenue(productIdentifier, price: product.price.doubleValue, receipt: receipt)
            } else {
                Analytics.instance.trackRevenue(productIdentifier, price: product.price.doubleValue)
            }
        }
        
        purchaseCompletionHandler?(true, transaction.error as NSError?)
        purchaseCompletionHandler = nil
    }
    
    fileprivate func restoreTransaction(_ transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        deliverPurchaseNotificatioForIdentifier(productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
        
        restoreCompletionHandler?(true, transaction.error as NSError?)
        restoreCompletionHandler = nil
    }
    
    fileprivate func failedTransaction(_ transaction: SKPaymentTransaction) {
        if let err = transaction.error as? SKError, err.code == SKError.paymentCancelled {
            print("Transaction Error: \(err.localizedDescription)")
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
        
        purchaseCompletionHandler?(false, transaction.error as NSError?)
        purchaseCompletionHandler = nil
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        restoreCompletionHandler?(false, error as NSError?)
        restoreCompletionHandler = nil
    }
    
    fileprivate func deliverPurchaseNotificatioForIdentifier(_ identifier: String?) {
        guard let identifier = identifier else { return }
        
        purchasedProductIdentifiers.insert(identifier)
        UserDefaults.standard.set(true, forKey: identifier)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: Notification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification), object: identifier)
    }
}
