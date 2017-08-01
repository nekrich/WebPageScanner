//
//  Array+RemovingDuplicates.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
	
	/// Returns array of elements without duplicates.
	///
	/// - Returns: array of elements without duplicates.
	func removingDuplicates() -> [Element] {
		return Array(Set<Element>(self))
	}
	
}
