//
//  String+Regex.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

extension String {
	
	public func countOccurrences(
		of substring: String,
		options: String.CompareOptions = [.diacriticInsensitive, .caseInsensitive])
		-> Int
	{
		guard !substring.isEmpty
			else {
				return 0
		}
		
		var count = 0
		
		var searchStartIndex = startIndex
		
		while let endOfFoundRange = range(of: substring,
		                                  options: options,
		                                  range: searchStartIndex..<endIndex,
		                                  locale: .none)?.upperBound
		{
			count += 1
			searchStartIndex = endOfFoundRange
		}
		
		return count
		
	}
	
	/// Returns occurrences of `regex` in responder.
	///
	/// - Parameter regex: regex object describing regex pattern to look for.
	/// - Returns: occurrences of `regex` in responder.
	func matches(of regex: Regex) -> [NSTextCheckingResult] {
		// swiftlint:disable:next force_try
		let regularExpression = try! NSRegularExpression(pattern: regex.rawValue,
		                                                 options: [])
		let nsString: NSString = self as NSString
		let range = NSRange(location: 0,
		                    length: nsString.length)
		
		let matches = regularExpression.matches(in: self,
		                                        options: [],
		                                        range: range)
		
		return matches
	}
	
	/// Returns first occurrence of string mathing regex.
	///
	/// - Parameter regex: regex object describing regex pattern to look for.
	/// - Returns: first occurrence of string mathing regex.
	func stringMatching(regex: Regex) -> String? {
		
		return stringsMatching(regex: regex).first
		
	}
	
	/// Returns all occurrences of string mathing regex.
	///
	/// - Parameter regex: regex object describing regex pattern to look for.
	/// - Returns: all occurrences of string mathing regex.
	func stringsMatching(regex: Regex) -> [String] {
		let matches = self.matches(of: regex)
		let nsString: NSString = self as NSString
		let dataStrings = matches
			.flatMap { (result) -> String? in
				guard
					result.numberOfRanges == regex.numberOfRanges
						&& result.rangeAt(regex.rangeIndex).length > 0
					else {
						return .none
				}
				
				let dataString = nsString.substring(with: result.rangeAt(regex.rangeIndex))
				
				return dataString
		}
		return dataStrings
	}
	
	/// Returns string without substring matching regex.
	///
	/// - Parameter regex: regex object describing regex pattern to look for.
	/// - Returns: string without substring matching regex.
	func removingStrings(matching regex: Regex) -> String {
		let matches = self.matches(of: regex).reversed()
		let nsString: NSMutableString = NSMutableString(string: self)
		
		matches.forEach { (result) in
			guard
				result.numberOfRanges == regex.numberOfRanges
					&& result.rangeAt(regex.rangeIndex).length > 0
				else {
					return
			}
			
			nsString.replaceCharacters(in: result.rangeAt(regex.rangeIndex), with: "")
			
		}
		
		return nsString as String
	}
	
}
