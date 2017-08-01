//
//  WPSOperationDelegate.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

internal protocol WPSOperationDelegate: class {
	
	func wpsOperationDidStart<ResultType>(_ wpsDownloadOperation: WPSOperation<ResultType>)
	
	func wpsOperation<ResultType>(
		_ wpsDownloadOperation: WPSOperation<ResultType>,
		didFinishWith error: WPSOperationError)
	
	func wpsOperation<ResultType>(
		_ wpsDownloadOperation: WPSOperation<ResultType>,
		didFinishWith result: ResultType)
	
}
