//
//  WPSOperations.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

internal class WPSOperation<ResultValueType>: Operation {
	
	typealias ResultType = Result<ResultValueType, WPSOperationError>
	
	fileprivate(set) var result: ResultType! {
		didSet {
			guard let result = result
				else {
					return
			}
			switch result {
			case let .failure(error):
				delegate?.wpsOperation(self, didFinishWith: error)
			case let .success(value):
				delegate?.wpsOperation(self, didFinishWith: value)
			}
			operationCompletionBlock?(result)
		}
	}
	
	weak var delegate: WPSOperationDelegate?
	
	var operationCompletionBlock: ((ResultType) -> Void)?
	
	let url: URL
	
	init(url: URL) {
		self.url = url
		super.init()
	}
	
	override func start() {
		delegate?.wpsOperationDidStart(self)
		super.start()
	}
	
	override func cancel() {
		if result == nil {
			result = .failure(.canceled)
		}
		super.cancel()
	}
	
	internal func cancel(with error: WPSOperationError) {
		result = .failure(error)
		self.cancel()
	}
	
}

internal class WPSDownloadOperation: WPSOperation<(data: Data, url: URL)> {
	
	private let apiSource: WPSDownloadOperationAPISource
	private var task: URLSessionTask?
	
	init(
		url: URL,
		apiSource: WPSDownloadOperationAPISource)
	{
		self.apiSource = apiSource
		super.init(url: url)
	}
	
	override func start() {
		super.start()
		let task = apiSource.api.fetchWebPage(at: url,
		                                      using: apiSource.urlSession,
		                                      completionHandler: processDataTaskResponse)
		self.task = task
		task.resume()
	}
	
	private func processDataTaskResponse(
		data: Data?,
		urlResponse: URLResponse?,
		error: Swift.Error?)
	{
		
		defer {
			_isFinished = true
		}
		
		if isCancelled {
			return
		}
		
		if let error = error {
			self.cancel(with: .downloadError(error))
			return
		}
		
		guard let data = data
			else {
				self.cancel(with: .noDataInResponse)
				return
		}
		
		result = .success(data: data, url: url)
		
	}
	
	override func cancel() {
		super.cancel()
		task?.cancel()
	}
	
	private var _isFinished: Bool = false {
		willSet {
			willChangeValue(forKey: "isFinished")
		}
		didSet {
			didChangeValue(forKey: "isFinished")
		}
	}
	override var isFinished: Bool {
		return _isFinished
	}
	
}

internal class WPSParseOperation: WPSOperation<(urls: Set<URL>, matchesCount: Int)> {
	
	private let scanForURLs: Bool
	private let searchString: String
	private let data: Data
	
	init(
		url: URL,
		data: Data,
		searchString: String,
		scanForURLs: Bool)
	{
		self.scanForURLs = scanForURLs
		self.searchString = searchString
		self.data = data
		super.init(url: url)
	}
	
	override func main() {
		
		guard let htmlString = String(data: data, encoding: .utf8)
			else {
				cancel(with: .cantConvertDataToString)
				return
		}
		
		let resultingValue = parseHTMLString(htmlString)
		
		if !isCancelled {
			result = .success(resultingValue)
		} else {
			result = .failure(.canceled)
		}
		
	}
	
	private func parseHTMLString(_ htmlString: String) -> (urls: Set<URL>, matchesCount: Int) {
		
		guard let body = htmlString.stringMatching(regex: .body)
			else {
				return (urls: Set(), matchesCount: 0)
		}
		
		let urls: [URL]
		if scanForURLs {
			urls = body.stringsMatching(regex: .urls)
				.removingDuplicates()
				.flatMap(URL.init)
				.filter {
					if Ignored.hosts.contains($0.host ?? "") {
						return false
					}
					if $0.pathExtension == "" {
						return true
					} else {
						return !Ignored.extensions.contains($0.pathExtension)
					}
			}
		} else {
			urls = []
		}
		
		let clearBodyText = body
			.removingStrings(matching: .script)
			.removingStrings(matching: .tag)
		
		let numberOfMatches = clearBodyText.countOccurrences(of: self.searchString)
		
		return (urls: Set(urls), matchesCount: numberOfMatches)
		
	}
	
}
