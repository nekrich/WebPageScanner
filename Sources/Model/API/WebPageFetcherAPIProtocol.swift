//
//  WebPageFetcherAPIProtocol.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/2/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

internal protocol WebPageFetcherAPIProtocol {
	
	@discardableResult
	func fetchWebPage(
		at url: URL,
		using session: URLSession,
		completionHandler: @escaping (_ data: Data?, _ urlResponse: URLResponse?, _ error: Error?) -> Void)
		-> URLSessionTask
	
}

extension WebPageFetcherAPIProtocol {
	
	@discardableResult
	func fetchWebPage(
		at url: URL,
		using session: URLSession,
		completionHandler: @escaping (_ data: Data?, _ urlResponse: URLResponse?, _ error: Error?) -> Void)
		-> URLSessionTask
	{
		
		let task = session.dataTask(with: url, completionHandler: completionHandler)
		return task
		
	}
	
}
