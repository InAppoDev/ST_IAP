//
//  PurchaseViewController.swift
//  pay
//
//  Created by Alexandr on 28.12.2021.
//


import UIKit
import StoreKit

class PurchaseViewController: UIViewController {

	@IBOutlet weak var cover: UIImageView!
	@IBOutlet weak var descriptionTextView: UITextView!
	@IBOutlet weak var monthButtonOutlet: UIButton!
	@IBOutlet weak var yearButtonOutlet: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
				
		descriptionTextView.text = "Данное упражнение доступно для просмотра премиум пользователям. Приобретите премиум аккаунт сейчас, чтобы получить доступ к самым лучшим упражнениям."
		requestProducts()
	}
	
	private func requestProducts() {
		PurchaseManager.shared.requestSubscriptionsInfo { products, success, error in
			if let products = products {
				for product in products {
					if product.productIdentifier == Constats.Purchase.monthSubscriptionID {
						let title = "\(product.localizedPrice ?? "")" + "/месяц"
						self.monthButtonOutlet.setTitle(title, for: .normal)
					} else if product.productIdentifier == Constats.Purchase.yearSubscriptionID {
						let title = "\(product.localizedPrice ?? "")" + "/год (экономия 23%)"
						self.yearButtonOutlet.setTitle(title, for: .normal)
					}
				}
			}
		}
	}
	@IBAction func monthButtonTapped(_ sender: Any) {
		PurchaseManager.shared.purchaseSubscription(Constats.Purchase.monthSubscriptionID) { success, error in
			if success {
				LocalDataManager.shared.userSubscriptionIdentifier = Constats.Purchase.monthSubscriptionID
				self.navigationController?.popToRootViewController(animated: true)
			}
		}

	}

	@IBAction func yearButtonTapped(_ sender: UIButton) {
		PurchaseManager.shared.purchaseSubscription(Constats.Purchase.yearSubscriptionID) { success, error in
			if success {
				LocalDataManager.shared.userSubscriptionIdentifier = Constats.Purchase.yearSubscriptionID
				self.navigationController?.popToRootViewController(animated: true)
			}
		}
	}
}

