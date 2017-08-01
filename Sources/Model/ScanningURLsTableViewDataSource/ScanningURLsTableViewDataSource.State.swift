//
//  ScanningURLsTableViewDataSource.State.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

extension ScanningURLsTableViewDataSource {
	
	internal enum State {
		
		case all
		case downloading
		case parsing
		case error(WPSOperationError)
		case finished(matchesCount: Int)
		
	}
	
}

extension ScanningURLsTableViewDataSource.State {
	
	var humanDescription: String {
		switch self {
		case .all:
			return ""
		case .downloading:
			return "Downloading..."
		case .parsing:
			return "Parsing..."
		case let .error(error):
			return "Error: \(error.localizedDescription)"
		case let .finished(matchesCount):
			if matchesCount > 0 {
				return "Finished. Found \(matchesCount) matches."
			} else {
				return "Finished. No matches found."
			}
		}
	}
	
}

// MARK: - is's

extension ScanningURLsTableViewDataSource.State {
	
	var isDownloading: Bool {
		switch self {
		case .downloading:
			return true
		case .parsing,
		     .error,
		     .finished,
		     .all:
			return false
		}
	}
	
	var isParsing: Bool {
		switch self {
		case .parsing:
			return true
		case .downloading,
		     .error,
		     .finished,
		     .all:
			return false
		}
	}
	
	var isFinished: Bool {
		switch self {
		case .finished:
			return true
		case .downloading,
		     .parsing,
		     .error,
		     .all:
			return false
		}
	}
	
	var isError: Bool {
		switch self {
		case .error:
			return true
		case .downloading,
		     .parsing,
		     .finished,
		     .all:
			return false
		}
	}
	
}

extension ScanningURLsTableViewDataSource.State {
	
	static func ~= (lhs: ScanningURLsTableViewDataSource.State, rhs: ScanningURLsTableViewDataSource.State) -> Bool {
		switch (lhs, rhs) {
		case (.downloading, .downloading),
		     (.parsing, .parsing),
		     (.error, .error),
		     (.finished, .finished),
		     (.all, .all):
			return true
		default:
			return false
		}
	}
	
}
