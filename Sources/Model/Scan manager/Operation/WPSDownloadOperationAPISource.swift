//
//  WPSDownloadOperationAPISource.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

internal protocol WPSDownloadOperationAPISource {
	var api: WebPageFetcherAPIProtocol { get }
	var urlSession: URLSession { get }
}
