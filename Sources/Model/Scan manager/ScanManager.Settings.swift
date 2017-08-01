//
//  ScanManager.Settings.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 7/26/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

extension ScanManager {
	
	internal struct Settings {
		
		let parseThreadsCount: Int
		let serarchText: String
		let startingURL: URL
		let maxURLsCountToParse: Int
		let urlSessionConfiguration: URLSessionConfiguration
		let urlSessionDelegate: URLSessionDelegate?
		// swiftlint:disable:previous weak_delegate
		
		init(
			parseThreadsCount: Int,
			serarchText: String,
			startingURL: URL,
			maxURLsCountToParse: Int,
			urlSessionConfiguration: URLSessionConfiguration,
			urlSessionDelegate: URLSessionDelegate?)
		{
			self.parseThreadsCount = parseThreadsCount
			self.serarchText = serarchText
			self.startingURL = startingURL
			self.maxURLsCountToParse = maxURLsCountToParse
			self.urlSessionConfiguration = urlSessionConfiguration
			self.urlSessionDelegate = urlSessionDelegate
		}
		
	}
	
}
