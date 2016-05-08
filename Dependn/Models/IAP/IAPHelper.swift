//
//  IAPHelper.swift
//  Dependn
//
//  Created by David Miotti on 05/05/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (success: Bool, products: [SKProduct]?) -> ()
public typealias ProductsPurchaseCompletionHandler = ((Bool, NSError?) -> Void)

public class IAPHelper: NSObject {
    
    static let IAPHelperPurchaseNotification = "IAPHelperPurchaseNotification"
    
    private let productIdentifiers: Set<ProductIdentifier>
    
    private var purchasedProductIdentifiers = Set<ProductIdentifier>()
    
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    
    private var purchaseCompletionHandler: ProductsPurchaseCompletionHandler?
    private var restoreCompletionHandler: ProductsPurchaseCompletionHandler?
    
    init(productIds: Set<ProductIdentifier>) {
        self.productIdentifiers = productIds
        
        for productIdentifier in productIds {
            let purchased = NSUserDefaults.standardUserDefaults().boolForKey(productIdentifier)
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
            }
        }
        
        super.init()
        
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
}

// MARK: - StoreKit API

extension IAPHelper {
    
    public func requestProducts(completionHandler: ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func buyProduct(product: SKProduct, completion: ProductsPurchaseCompletionHandler) {
        print("Buying \(product.productIdentifier)...")
        purchaseCompletionHandler = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    public func isProductPurchased(productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases(completion: ProductsPurchaseCompletionHandler) {
        restoreCompletionHandler = completion
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {
    public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        let products = response.products
        productsRequestCompletionHandler?(success: true, products: products)
        clearRequestAndHandler()
    }
    
    public func request(request: SKRequest, didFailWithError error: NSError) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(success: false, products: nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    
    public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .Purchased:
                completeTransaction(transaction)
                break
            case .Failed:
                failedTransaction(transaction)
                break
            case .Restored:
                restoreTransaction(transaction)
                break
            case .Deferred:
                break
            case .Purchasing:
                break
            }
        }
    }
    
    private func completeTransaction(transaction: SKPaymentTransaction) {
        deliverPurchaseNotificatioForIdentifier(transaction.payment.productIdentifier)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        
        purchaseCompletionHandler?(true, transaction.error)
        purchaseCompletionHandler = nil
    }
    
    private func restoreTransaction(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.originalTransaction?.payment.productIdentifier else { return }
        
        deliverPurchaseNotificatioForIdentifier(productIdentifier)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        
        restoreCompletionHandler?(true, transaction.error)
        restoreCompletionHandler = nil
    }
    
    private func failedTransaction(transaction: SKPaymentTransaction) {
        if transaction.error!.code != SKErrorCode.PaymentCancelled.rawValue {
            print("Transaction Error: \(transaction.error?.localizedDescription)")
        }
        
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        
        purchaseCompletionHandler?(false, transaction.error)
        purchaseCompletionHandler = nil
    }
    
    public func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        restoreCompletionHandler?(false, error)
        restoreCompletionHandler = nil
    }
    
    private func deliverPurchaseNotificatioForIdentifier(identifier: String?) {
        guard let identifier = identifier else { return }
        
        purchasedProductIdentifiers.insert(identifier)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: identifier)
        NSUserDefaults.standardUserDefaults().synchronize()
        NSNotificationCenter.defaultCenter().postNotificationName(IAPHelper.IAPHelperPurchaseNotification, object: identifier)
    }
}
