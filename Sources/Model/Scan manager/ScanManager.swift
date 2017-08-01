//
//  ScanManager.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 7/26/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation
import UIKit

internal class ScanManager: WPSDownloadOperationAPISource {
	
	let underlyingOperationQueue: OperationQueue
	
	weak var delegate: ScanManagerDelegate?
	
	private(set) var foundURLs: Atomic<Set<URL>> = Atomic(value: Set()) {
		didSet {
			let oldSet = oldValue.value
			let newURLs = foundURLs.value.subtracting(oldSet)
			newURLs.forEach {
				addDownloadOperation(for: $0)
			}
		}
	}
	
	let api: WebPageFetcherAPIProtocol
	let urlSession: URLSession
	let serarchText: String
	let maxURLsCountToParse: Int
	init(settings: Settings, api: WebPageFetcherAPIProtocol) {
		
		let underlyingOperationQueue = OperationQueue()
		underlyingOperationQueue.maxConcurrentOperationCount = settings.parseThreadsCount
		let uuidString = UUID().uuidString
		underlyingOperationQueue.name = "WebPageScannerQueue ".appending(uuidString)
		underlyingOperationQueue.qualityOfService = .userInitiated
		underlyingOperationQueue.isSuspended = true
		
		self.api = api
		self.serarchText = settings.serarchText
		self.maxURLsCountToParse = settings.maxURLsCountToParse
		self.underlyingOperationQueue = underlyingOperationQueue
		self.urlSession = URLSession(configuration: settings.urlSessionConfiguration,
		                             delegate: settings.urlSessionDelegate,
		                             delegateQueue: {
																	let queue = OperationQueue()
																	queue.qualityOfService = .utility
																	queue.name = "WebPageScannerURLSessionQueue".appending(uuidString)
																	return queue
		}())
		
		// Add startingURL to queue
		DispatchQueue.main.async {
			self.foundURLs.change { (_) -> Set<URL> in
				Set([settings.startingURL])
			}
		}
	}
	
	// MARK: - Start, Pause, Cancel, Resume
	
	func start() {
		delegate?.scanManagerDidStart(self)
		underlyingOperationQueue.isSuspended = false
	}
	
	/// Cancels all operations.
	/// - Warning: sets `delegate` property to `nil`.
	func cancel() {
		delegate?.scanManagerDidCancel(self)
		delegate = .none
		underlyingOperationQueue.cancelAllOperations()
	}
	
	func pause() {
		underlyingOperationQueue.isSuspended = true
	}
	
	func resume() {
		underlyingOperationQueue.isSuspended = false
	}
	
	deinit {
		delegate?.scanManagerDidFinishAllTasks(self)
	}
	
	// MARK: Operation management
	
	private func addDownloadOperation(for url: URL) {
		let downloadOperation = WPSDownloadOperation(url: url,
		                                             apiSource: self)
		downloadOperation.operationCompletionBlock = didFinishDownload
		downloadOperation.delegate = self
		underlyingOperationQueue.addOperation(downloadOperation)
	}
	
	private func addParseOperation(url: URL, data: Data) {
		let parseOperation = WPSParseOperation(url: url,
		                            data: data,
		                            searchString: serarchText,
		                            scanForURLs: foundURLs.value.count < maxURLsCountToParse)
		parseOperation.delegate = self
		parseOperation.operationCompletionBlock = didFinishParse
		underlyingOperationQueue.addOperation(parseOperation)
	}
	
	// MARK: - Operations completion handlers
	
	private func didFinishDownload(_ result: Result<(data: Data, url: URL), WPSOperationError>) {
		
		defer {
			delegeateCompletedIfNeeded()
		}
		
		guard let result = result.value
			else {
				return
		}
		
		addParseOperation(url: result.url, data: result.data)
		
	}
	
	func didFinishParse(_ result: Result<(urls: Set<URL>, matchesCount: Int), WPSOperationError>) {
		
		defer {
			delegeateCompletedIfNeeded()
		}
		
		guard let (urls, _) = result.value
			else {
				return
		}
		
		addNewFoundURLs(urls)
		
	}
	
	private func delegeateCompletedIfNeeded() {
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
			if self.underlyingOperationQueue.operationCount == 0 {
				self.delegate?.scanManagerDidFinishAllTasks(self)
			}
		}
	}
	
	private func addNewFoundURLs(_ newFoundURLs: Set<URL>) {
		guard
			!newFoundURLs.isEmpty // if found some uls
				&& self.foundURLs.value.count < maxURLsCountToParse // and we still not reached the limit
			else {
				return
		}
		
		var newURLs = newFoundURLs.subtracting(self.foundURLs.value) // get 100% new urls
		foundURLs.change { (oldValues) -> Set<URL> in
			// How many urls we can append
			let availableCountMembersToInsert = max(maxURLsCountToParse - oldValues.count,
			                                        0)
			while newURLs.count > availableCountMembersToInsert {
				// remove overlaping urls
				newURLs.removeFirst()
			}
			return oldValues.union(newURLs) // add new urls to our set
		}
		
	}
	
}

// MARK: - WPSOperationDelegate

extension ScanManager: WPSOperationDelegate {
	
	func wpsOperationDidStart<ResultType>(_ wpsDownloadOperation: WPSOperation<ResultType>) {
		switch type(of: wpsDownloadOperation) {
		case is WPSDownloadOperation.Type:
			delegate?.scanManager(self, didStartDownloading: wpsDownloadOperation.url)
		case is WPSParseOperation.Type:
			delegate?.scanManager(self, didStartParsing: wpsDownloadOperation.url)
		default:
			fatalError("Unknown operation type: \(type(of: wpsDownloadOperation))")
		}
	}
	
	func wpsOperation<ResultType>(
		_ wpsDownloadOperation: WPSOperation<ResultType>,
		didFinishWith error: WPSOperationError)
	{
		delegate?.scanManager(self,
		                      didGetError: error,
		                      for: wpsDownloadOperation.url)
	}
	
	func wpsOperation<ResultType>(
		_ wpsDownloadOperation: WPSOperation<ResultType>,
		didFinishWith result: ResultType)
	{
		switch type(of: wpsDownloadOperation) {
		case is WPSDownloadOperation.Type:
			break
		case is WPSParseOperation.Type:
			// swiftlint:disable force_unwrapping force_cast
			let parseOperation = wpsDownloadOperation as! WPSParseOperation
			delegate?.scanManager(self,
			                      didFound: parseOperation.result.value!.matchesCount,
			                      at: wpsDownloadOperation.url)
			// swiftlint:enable force_unwrapping force_cast
		default:
			fatalError("Unknown operation type: \(type(of: wpsDownloadOperation))")
		}
	}
	
}
