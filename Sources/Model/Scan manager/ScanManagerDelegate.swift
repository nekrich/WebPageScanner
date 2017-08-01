//
//  ScanManagerDelegate.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

internal protocol ScanManagerDelegate: class {
	
	func scanManager(
		_ scanManager: ScanManager,
		didStartDownloading url: URL)
	
	func scanManager(
		_ scanManager: ScanManager,
		didStartParsing url: URL)
	
	func scanManager(
		_ scanManager: ScanManager,
		didGetError error: WPSOperationError,
		for url: URL)
	
	func scanManager(
		_ scanManager: ScanManager,
		didFound matchesCount: Int,
		at url: URL)
	
	func scanManagerDidFinishAllTasks(_ scanManager: ScanManager)
	
	func scanManagerDidCancel(_ scanManager: ScanManager)
	
	func scanManagerDidStart(_ scanManager: ScanManager)
	
}
