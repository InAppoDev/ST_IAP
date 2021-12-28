//
//  Constats.swift
//  pay
//
//  Created by Alexandr on 28.12.2021.
//

import Foundation

struct Constats {
	
	struct Purchase {
		static let sharedSecret = "a02aebfb3177474cb34a375839068929"
		static let monthSubscriptionID = "yorich.fitness.monthly.new"
		static let yearSubscriptionID = "yorich.fitness.yearly.new"
	}
	
	struct UserDefaultsKeys {
		static let userTrainingLevel = "UserTrainingLevel"
		static let userIsPremium = "userIsPremium"
		
		static let userSubscriptionIdentifier = "UserSubscriptionIdentifier"
	}

}

