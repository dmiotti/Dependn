//
//  DependnProducts.swift
//  Dependn
//
//  Created by David Miotti on 05/05/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit

public struct DependnProducts {
    
    fileprivate static let Prefix = "com.davidmiotti.dependn."
    
    public static let ExportXLS = Prefix + "export_xls"
    
    fileprivate static let productIdentifiers: Set<ProductIdentifier> = [ DependnProducts.ExportXLS ]
    
    public static let store = IAPHelper(productIds: DependnProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}
