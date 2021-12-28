//
//  LocalDataManager.swift
//  pay
//
//  Created by Alexandr on 28.12.2021.
//

import UIKit

final class LocalDataManager {
	
	private init() {}
	
	static var shared: LocalDataManager = {
		  let instance = LocalDataManager()

		  return instance
	  }()

	var userIsPremium: Bool {
		get {
			return UserDefaults.standard.bool(forKey: Constats.UserDefaultsKeys.userIsPremium)
		}
		set {
			UserDefaults.standard.setValue(newValue, forKey: Constats.UserDefaultsKeys.userIsPremium)
		}
	}

	var userSubscriptionIdentifier: String? {
		get {
			return UserDefaults.standard.string(forKey: Constats.UserDefaultsKeys.userSubscriptionIdentifier)
		}
		set {
			UserDefaults.standard.setValue(newValue, forKey: Constats.UserDefaultsKeys.userSubscriptionIdentifier)
		}
	}
}
