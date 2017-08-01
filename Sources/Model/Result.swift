//
//  Result.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 7/26/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

internal enum Result<Value, Error: Swift.Error> {
	
	case success(Value)
	case failure(Error)
	
	var isSuccess: Bool {
		switch self {
		case .success:
			return true
		case .failure:
			return false
		}
	}
	
	var isFailure: Bool {
		return !isSuccess
	}
	
	var error: Error? {
		switch self {
		case .success:
			return nil
		case .failure(let error):
			return error
		}
	}
	
	var value: Value? {
		switch self {
		case .success(let value):
			return value
		case .failure:
			return nil
		}
	}
	
}
