//
//  WPSOperationError.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

internal enum WPSOperationError: Swift.Error, LocalizedError {
	
	case noDataInResponse
	case canceled
	case cantConvertDataToString
	case downloadError(Swift.Error)
	
	var errorDescription: String? {
		switch self {
		case .noDataInResponse:
			return "Serverd returned no data."
		case .canceled:
			return "Canceled."
		case .cantConvertDataToString:
			return "Server returned not UTF-8 encoded string."
		case let .downloadError(error):
			return "URL download error: \(error.localizedDescription)"
		}
	}
	
}
