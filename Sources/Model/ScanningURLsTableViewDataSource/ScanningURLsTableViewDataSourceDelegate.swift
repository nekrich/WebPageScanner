//
//  ScanningURLsTableViewDataSourceDelegate.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

internal protocol ScanningURLsTableViewDataSourceDelegate: class {
	func allDownloadsAreFinished()
	func didChangeParsedURLsCount(to newParsedURLsCount: Int)
}
