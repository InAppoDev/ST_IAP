//
//  PurchaseManager.swift
//  pay
//
//  Created by Alexandr on 28.12.2021.
//


import UIKit
import StoreKit
import SwiftyStoreKit

class PurchaseManager: NSObject {
	//MARK: Property
	private let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: Constats.Purchase.sharedSecret)
	var receipt: [String: AnyObject]?
	public static var shared: PurchaseManager = PurchaseManager()
	public let subscriptions = [Constats.Purchase.monthSubscriptionID, Constats.Purchase.yearSubscriptionID]
	private var products: Set<SKProduct> = []
	
	//MARK: init
	fileprivate override init() {
		super.init()
		
		shouldAddStorePaymentHandler()
	}
	
	func shouldAddStorePaymentHandler() {
		SwiftyStoreKit.shouldAddStorePaymentHandler = { payment, product in
			return false
		}
	}
	
	// MARK: requestSubscriptionsInfo
	public func requestSubscriptionsInfo(_ complete: ((Set<SKProduct>?, Bool, Error?) -> Void)? = nil) {
		let iDs: [String] = [Constats.Purchase.monthSubscriptionID, Constats.Purchase.yearSubscriptionID]
		let productsIDs: Set<String> = Set(iDs)
		SwiftyStoreKit.retrieveProductsInfo(productsIDs) { [weak self] result in
			guard let aSelf = self else { return }
			if let error = result.error {
				complete?(nil, false, error)
				return
			}
			debugPrint("invalid products: \(result.invalidProductIDs)")
			debugPrint("valid products: \(result.retrievedProducts)")
			if result.retrievedProducts.isEmpty {
				complete?(nil, false, nil)
			} else {
				aSelf.products = result.retrievedProducts
				complete?(aSelf.products, true, nil)
			}
		}
	}

	public func completeIAPTransactions() {
		SwiftyStoreKit.completeTransactions { (purchases) in
			for purchase in purchases {
				let state = purchase.transaction.transactionState
				if state == .purchased || state == .restored {
					if purchase.needsFinishTransaction {
						SwiftyStoreKit.finishTransaction(purchase.transaction)
					}
				}
			}
		}
	}
	
	// MARK: - Restore
	func restorePurchase(completion: @escaping (_ ids: [String]?, _ error: String?) -> Void) {
		SwiftyStoreKit.restorePurchases(atomically: true) { results in
			if results.restoreFailedPurchases.count > 0 {
				completion(nil, results.restoreFailedPurchases.first?.0.localizedDescription)
			} else if results.restoredPurchases.count > 0 {
				let ids: [String] = results.restoredPurchases.compactMap({$0.productId})
				completion(ids, nil)
			} else {
				completion(nil, "nothing_to_restore")
			}
		}
	}
	
	// MARK: - Purchase
	public func purchaseSubscription(_ productID: String, complete: @escaping (Bool, String?) -> Void) {
		guard let product = self.products.filter({$0.productIdentifier == productID}).first else { return }
		
		SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { result in
			switch result {
			case .success(let purchase):
				if purchase.needsFinishTransaction {
					SwiftyStoreKit.finishTransaction(purchase.transaction)
				}
				
				self.verifySubsription(product.productIdentifier, type: .autoRenewable, verifyReceiptAfterPurchase: true) { isPurchase in
					complete(isPurchase, nil)
					LocalDataManager.shared.userIsPremium = isPurchase
				}
			case .error(let error):
				complete(false, error.localizedDescription)
			}
		}
	}
	
	//MARK: verifyReceipt
	public func verifyReceipt(complete: @escaping (Bool) -> Void) {
		guard let _ = SwiftyStoreKit.localReceiptData else { complete(false); return }
		
		SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
			switch result {
			case .success(let receipt):
				self.receipt = receipt
				complete(true)
			case .error(let error):
				debugPrint("Verify receipt Failed: \(error)")
				complete(false)
			}
		}
		
	}
		//MARK: verifySubsription
	public func verifySubsription(_ productId: String, type: SubscriptionType = .autoRenewable, verifyReceiptAfterPurchase: Bool = false, complete: @escaping (Bool) -> Void) {
		print(#function)
		
			if verifyReceiptAfterPurchase {
				verifyReceipt { result in
					if result {
						self.verifySubsription(productId, type: type, verifyReceiptAfterPurchase: false, complete: complete)
					} else {
						complete(false)
					}
				}
			} else {
				guard let receipt = self.receipt else { complete(false); return }
				let result = PurchaseManager.requestVerifySubsription(productId, type: type, receipt: receipt)
				complete(result)
			}
		}
		
	
	public func checkSubscriptionsPurchased(_ subscriptions: [SKProduct], complete: @escaping (Bool)->Void) {
		let aSubscriptions = subscriptions
		verifyReceipt() { result in
			if result {
				complete(self.isSubscriptionsPurchased(aSubscriptions))
			} else {
				complete(false)
			}
		}
	}
	
	//MARK: isSubscriptionsPurchased
	public func isSubscriptionsPurchased(_ subscriptions: [SKProduct]) -> Bool {
		guard let receipt = self.receipt else { return false }
		for item in subscriptions {
			if PurchaseManager.requestVerifySubsription(item.productIdentifier, type: .autoRenewable, receipt: receipt) {
				return true
			}
		}
		return false
	}
		
		 class func requestVerifySubsription(_ productId: String, type: SubscriptionType, receipt: [String: AnyObject]) -> Bool {
			let purchaseResult = SwiftyStoreKit.verifySubscription(ofType: type,  productId: productId, inReceipt: receipt)
			switch purchaseResult {
			case .purchased(let expiryDate, _):
				print("expiryDate: \(expiryDate)")
				LocalDataManager.shared.userIsPremium = true
				return true
			case .expired(_, _):
				LocalDataManager.shared.userIsPremium = false
				return false
			case .notPurchased:
				LocalDataManager.shared.userIsPremium = false
				return false
			}
		}
	}

