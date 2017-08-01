//
//  Ingored.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

internal struct Ignored {
	
	static let extensions: Set<String> = ["jpg", "jpeg", "pdf", "png", "svg", "eps"]
	static let hosts: Set<String> = ["www.facebook.com", "plus.google.com"]
	
}
