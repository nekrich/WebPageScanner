//
//  ScanningURLsTableViewDataSource.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation
import UIKit

internal class ScanningURLsTableViewDataSource: NSObject {
	
	weak var tableView: UITableView!
	
	weak var delegate: ScanningURLsTableViewDataSourceDelegate?
	
	fileprivate var downloadingURLs: [URL] = [] {
		didSet {
			guard state ~= .downloading
				else {
					return
			}
			manageChanges(oldValue: oldValue,
			              newValue: downloadingURLs)
		}
	}
	
	fileprivate var allURLs: [URL] = [] {
		didSet {
			guard state ~= .all
				else {
					return
			}
			manageChanges(oldValue: oldValue,
			              newValue: allURLs)
		}
	}
	
	fileprivate var parsingURLs: [URL] = [] {
		didSet {
			guard state ~= .parsing
				else {
					return
			}
			manageChanges(oldValue: oldValue,
			              newValue: parsingURLs)
		}
	}
	
	fileprivate var erroredURLs: [URL] = [] {
		didSet {
			guard state.isError
				else {
					return
			}
			manageChanges(oldValue: oldValue,
			              newValue: parsingURLs)
		}
	}
	
	fileprivate var finishedURLs: [URL] = [] {
		didSet {
			guard state.isFinished
				else {
					return
			}
			manageChanges(oldValue: oldValue,
			              newValue: parsingURLs)
		}
	}
	
	fileprivate var urlsStates: [URL: State] = [:] {
		didSet {
			guard state ~= .all
				else {
					return
			}
		}
	}
	
	private func manageChanges(oldValue: [URL], newValue: [URL]) {
		if oldValue.count < newValue.count {
			let newRows = Set(newValue)
				.subtracting(oldValue)
				.reduce([Int]()) { (result, url) in
					var result = result
					result.append(newValue.index(of: url)!) // swiftlint:disable:this force_unwrapping
					return result
			}
			insertRows(at: newRows)
		} else {
			let removedRows = Set(oldValue)
				.subtracting(newValue)
				.map {
					oldValue.index(of: $0)! // swiftlint:disable:this force_unwrapping
			}
			removeRows(at: removedRows)
		}
	}
	
	private func insertRows(at rowIndexes: [Int]) {
		let indexPaths = rowIndexes.map {
			IndexPath(row: $0,
			          section: 0)
		}
		tableView.insertRows(at: indexPaths,
		                     with: .automatic)
	}
	
	private func removeRows(at rowIndexes: [Int]) {
		let indexPaths = rowIndexes.map {
			IndexPath(row: $0,
			          section: 0)
		}
		tableView.deleteRows(at: indexPaths,
		                     with: .automatic)
	}
	
	var state: State = .downloading {
		didSet {
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
		}
	}
	
	fileprivate func insert(url: URL, for state: State) {
		DispatchQueue.main.async {
			self.tableView.beginUpdates()
			self._insert(url: url, for: state)
			self.tableView.endUpdates()
		}
	}
	
	private func _insert(url: URL, for state: State) {
		
		// Add URL to corresponding array, and remove from previous
		
		switch state {
		case .downloading:
			downloadingURLs.insert(url, at: 0)
		case .parsing:
			downloadingURLs.remove(at: downloadingURLs.index(of: url)!) // swiftlint:disable:this force_unwrapping
			parsingURLs.insert(url, at: 0)
		case .error:
			if let index = downloadingURLs.index(of: url) {
				downloadingURLs.remove(at: index)
			}
			if let index = parsingURLs.index(of: url) {
				parsingURLs.remove(at: index)
			}
			erroredURLs.insert(url, at: 0)
		case .finished:
			parsingURLs.remove(at: parsingURLs.index(of: url)!) // swiftlint:disable:this force_unwrapping
			finishedURLs.insert(url, at: 0)
		case .all:
			fatalError("Can't insert URL with state `.all`")
		}
		
		// Manage state update
		
		let noState: Bool = urlsStates[url] == nil
		urlsStates[url] = state
		if !noState && self.state ~= .all { // if there was state, ans state is `.all` - reload cell
			let indexPath = IndexPath(row: allURLs.index(of: url)!, // swiftlint:disable:this force_unwrapping
			                          section: 0)
			tableView.reloadRows(at: [indexPath], with: .automatic)
		} else if noState { // if there was no state - add to allURLs
			allURLs.insert(url, at: 0)
		}
		
		// Notify delegate
		nofityDelegateAboutFinishedTask(with: state)
		
	}
	
	private func nofityDelegateAboutFinishedTask(with state: State) {
		switch state {
		case .error,
		     .finished:
			delegate?.didChangeParsedURLsCount(to: allURLs.count)
		case .downloading,
		     .parsing,
		     .all:
			break
		}
	}
	
	fileprivate func removeAllURLs() {
		downloadingURLs = []
		parsingURLs = []
		finishedURLs = []
		erroredURLs = []
		allURLs = []
		urlsStates = [:]
	}
	
}

// MARK: - ScanManagerDelegate

extension ScanningURLsTableViewDataSource: ScanManagerDelegate {
	
	func scanManagerDidStart(_ scanManager: ScanManager) {
		removeAllURLs()
	}
	
	func scanManager(_ scanManager: ScanManager, didStartDownloading url: URL) {
		insert(url: url, for: .downloading)
	}
	
	func scanManager(_ scanManager: ScanManager, didStartParsing url: URL) {
		insert(url: url, for: .parsing)
	}
	
	func scanManager(_ scanManager: ScanManager, didGetError error: WPSOperationError, for url: URL) {
		insert(url: url, for: .error(error))
	}
	
	func scanManager(_ scanManager: ScanManager, didFound matchesCount: Int, at url: URL) {
		insert(url: url, for: .finished(matchesCount: matchesCount))
	}
	
	func scanManagerDidFinishAllTasks(_ scanManager: ScanManager) {
		DispatchQueue.main.async {
			self.delegate?.allDownloadsAreFinished()
		}
	}
	
	func scanManagerDidCancel(_ scanManager: ScanManager) {
		var urlsInProgress = downloadingURLs
		urlsInProgress.append(contentsOf: parsingURLs)
		urlsInProgress.forEach {
			self.scanManager(scanManager, didGetError: .canceled, for: $0)
		}
	}
	
}

// MARK: - UITableViewDataSource

extension ScanningURLsTableViewDataSource: UITableViewDataSource {
	
	private enum CellIdentifier: String {
		case task = "TaskTableViewCell"
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	private var currentURLs: [URL] {
		switch state {
		case .downloading:
			return downloadingURLs
		case .parsing:
			return parsingURLs
		case .error:
			return erroredURLs
		case .finished:
			return finishedURLs
		case .all:
			return allURLs
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard section == 0
			else {
				return 0
		}
		return currentURLs.count
		
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.task.rawValue,
		                              for: indexPath) as! TaskTableViewCell
		// swiftlint:disable:previous force_cast
		
		let url = currentURLs[indexPath.row]
		let state = urlsStates[url]! // swiftlint:disable:this force_unwrapping
		
		cell.urlLabel.text = url.absoluteString
		cell.statusLabel.text = state.humanDescription
		return cell
		
	}
	
}
