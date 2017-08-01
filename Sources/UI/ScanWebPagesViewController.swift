//
//  ScanWebPagesViewController.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 7/26/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

internal class ScanWebPagesViewController: UIViewController {
	
	@IBOutlet fileprivate private(set) weak var startingURLTextField: UITextField!
	@IBOutlet private weak var parallelOpreationsCountLabel: UILabel!
	@IBOutlet private weak var parallelOpreationsCountStepper: UIStepper!
	
	@IBOutlet private weak var maxURLsToScanLabel: UILabel!
	@IBOutlet private weak var maxURLsToScanStepper: UIStepper!
	
	@IBOutlet fileprivate private(set) weak var stringToSearchTextField: UITextField!
	
	@IBOutlet private weak var startButton: UIButton!
	@IBOutlet private weak var pauseResumeButton: UIButton!
	@IBOutlet private weak var cancelButton: UIButton!
	
	@IBOutlet private weak var displayingStateSegmentedControl: UISegmentedControl!
	
	@IBOutlet private var tableView: UITableView!
	
	@IBOutlet private weak var parsingProgressLabel: UILabel!
	@IBOutlet private weak var parsingProgressView: UIProgressView!
	
	@IBOutlet private weak var tapGestureRecognizer: UITapGestureRecognizer!
	
	fileprivate var state: State = .pending {
		didSet {
			configureElements()
		}
	}
	
	private var dataSource: ScanningURLsTableViewDataSource!
	private weak var scanManager: ScanManager?
	
	private let urlSessionConfiguration: URLSessionConfiguration = {
		let urlSessionConfiguration: URLSessionConfiguration = .default
		urlSessionConfiguration.httpShouldUsePipelining = true
		urlSessionConfiguration.httpMaximumConnectionsPerHost = 10
		return urlSessionConfiguration
	}()
	
	private var maxURLsToScan: Int {
		return Int(maxURLsToScanStepper.value)
	}
	
	// MARK: - Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = 57.0
		tableView.rowHeight = UITableViewAutomaticDimension
		
		dataSource = ScanningURLsTableViewDataSource()
		dataSource.tableView = tableView
		dataSource.state = ScanningURLsTableViewDataSource.State(int: displayingStateSegmentedControl.selectedSegmentIndex)
		dataSource.delegate = self
		tableView.dataSource = dataSource
		
		configureElements()
		
		parallelOpreationsCountStepper.value = 5.0
		maxURLsToScanStepper.value = 15.0
		
		displayingStateSegmentedControlDidChange()
		parallelOperationsCountDidChange()
		maxURLsToScanCountDidChange()
		
		addKeyboardObservers()
	}
	
	deinit {
		removeKeyboardObservers()
	}
	
	// MARK: - Config
	private func configureElements() {
		switch state {
		case .pending:
			setEnabledStateForConfiguringElements(true)
		case .paused,
		     .running:
			setEnabledStateForConfiguringElements(false)
		}
		
		let pauseResumeButtonTitle: String = state == .paused
			? "Resume"
			: "Pause"
		pauseResumeButton.setTitle(pauseResumeButtonTitle, for: .normal)
		
	}
	
	private func setEnabledStateForConfiguringElements(_ enabled: Bool) {
		
		startingURLTextField.isEnabled = enabled
		parallelOpreationsCountStepper.isEnabled = enabled
		maxURLsToScanStepper.isEnabled = enabled
		stringToSearchTextField.isEnabled = enabled
		
		startButton.isEnabled = enabled
		
		pauseResumeButton.isEnabled = !enabled
		cancelButton.isEnabled = !enabled
		
	}
	
	fileprivate func updateProgress(with newParsedURLsCount: Int) {
		parsingProgressLabel.text = "\(newParsedURLsCount)/\(maxURLsToScan)"
		parsingProgressView.setProgress(Float(newParsedURLsCount) / Float(maxURLsToScan), animated: true)
	}
	
	// MARK: - Actions
	
	fileprivate func search() {
		let settings: ScanManager.Settings
		do {
			settings = try ScanManager.Settings(parseThreadsCount: parallelOpreationsCountStepper.value,
			                                    serarchText: stringToSearchTextField.text,
			                                    startingURLstring: startingURLTextField.text,
			                                    maxURLsCountToParse: maxURLsToScan,
			                                    urlSessionConfiguration: self.urlSessionConfiguration,
			                                    urlSessionDelegate: .none)
		} catch {
			showError(error)
			return
		}
		
		let api = API()
		
		let scanManager = ScanManager(settings: settings, api: api)
		scanManager.delegate = dataSource
		
		updateProgress(with: 0)
		
		scanManager.start()
		
		self.scanManager = scanManager
		
		state = .running
	}
	
	@IBAction private func didTapOnView() {
		view.endEditing(true)
	}
	
	@IBAction private func parallelOperationsCountDidChange() {
		parallelOpreationsCountLabel.text = "\(Int(parallelOpreationsCountStepper.value))"
	}
	
	@IBAction private func maxURLsToScanCountDidChange() {
		maxURLsToScanLabel.text = "\(maxURLsToScan)"
		updateProgress(with: 0)
	}
	
	@IBAction private func displayingStateSegmentedControlDidChange() {
		dataSource.state = ScanningURLsTableViewDataSource.State(int: displayingStateSegmentedControl.selectedSegmentIndex)
	}
	
	// MARK: - Start, Stop, Pause, Resume
	
	@IBAction private func didTapStartButton() {
		
		search()
		
	}
	
	@IBAction private func didTapPauseResumeButton() {
		if state == .paused {
			scanManager?.resume()
			state = .running
		} else {
			scanManager?.pause()
			state = .paused
		}
	}
	
	@IBAction private func didTapCancelButton() {
		scanManager?.cancel()
		state = .pending
	}
	
	// MARK: - Error
	
	private func showError(_ error: Error) {
		
		let alertController = UIAlertController(title: "Error",
		                                        message: error.localizedDescription,
		                                        preferredStyle: .alert)
		
		let dismissAction = UIAlertAction(title: "Dismiss",
		                                  style: .cancel,
		                                  handler: .none)
		
		alertController.addAction(dismissAction)
		
		present(alertController, animated: true, completion: .none)
		
	}
	
	// MARK: - Keyboard
	
	private func addKeyboardObservers() {
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(keyboardWillShow(_:)),
		                                       name: .UIKeyboardWillShow,
		                                       object: .none)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(keyboardWillHide(_:)),
		                                       name: .UIKeyboardWillHide,
		                                       object: .none)
	}
	
	private func removeKeyboardObservers() {
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: .none)
		NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: .none)
	}
	
	@objc
	private func keyboardWillShow(_ notification: Notification) {
		guard isViewLoaded
			else {
				return
		}
		tapGestureRecognizer.cancelsTouchesInView = true
	}
	
	@objc
	private func keyboardWillHide(_ notification: Notification) {
		guard isViewLoaded
			else {
				return
		}
		tapGestureRecognizer.cancelsTouchesInView = false
	}
	
}

private extension ScanWebPagesViewController {
	
	enum State: UInt8 {
		case pending
		case running
		case paused
	}
	
}

extension ScanWebPagesViewController: ScanningURLsTableViewDataSourceDelegate {
	
	func allDownloadsAreFinished() {
		if state != .pending {
			state = .pending
		}
	}
	
	func didChangeParsedURLsCount(to newParsedURLsCount: Int) {
		updateProgress(with: newParsedURLsCount)
	}
	
}

extension ScanWebPagesViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		switch textField {
		case startingURLTextField:
			self.stringToSearchTextField.becomeFirstResponder()
		case stringToSearchTextField:
			search()
		default:
			break
		}
		
		return true
	}
	
}

private extension ScanManager.Settings {
	
	enum Error: Swift.Error, LocalizedError {
		case noSearchText
		case noURL
		case wrongURL
		
		var localizedDescription: String {
			switch self {
			case .noSearchText:
				return "Search text is empty"
			case .noURL:
				return "Starting url is empty"
			case .wrongURL:
				return "Starting URL is not a valid URL"
			}
		}
		
		var errorDescription: String? {
			return localizedDescription
		}
		
	}
	
	init(
		parseThreadsCount: Double,
		serarchText: String?,
		startingURLstring: String?,
		maxURLsCountToParse: Int,
		urlSessionConfiguration: URLSessionConfiguration,
		urlSessionDelegate: URLSessionDelegate?) throws
	{
		guard
			let serarchText = serarchText,
			!serarchText.isEmpty
			else {
				throw Error.noSearchText
		}
		guard
			let startingURLstring = startingURLstring,
			!startingURLstring.isEmpty
			else {
				throw Error.noURL
		}
		guard let startingURL = URL(string: startingURLstring)
			else {
				throw Error.wrongURL
		}
		self.parseThreadsCount = Int(parseThreadsCount)
		self.serarchText = serarchText
		self.startingURL = startingURL
		self.maxURLsCountToParse = Int(maxURLsCountToParse)
		self.urlSessionConfiguration = urlSessionConfiguration
		self.urlSessionDelegate = urlSessionDelegate
	}
	
}

private extension ScanningURLsTableViewDataSource.State {
	
	init(int: Int) {
		switch int {
		case 1:
			self = .downloading
		case 2:
			self = .parsing
		case 3:
			self = .finished(matchesCount: 0)
		case 4:
			self = .error(.canceled)
		default:
			self = .all
		}
	}
	
}
