//
//  Regex.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

/// Regex
///
/// - urls: Regex for urls`href="http(s)://`
/// - body: Regex for body and styles `<body>*</body>`
/// - script: Regex for scripts and styles `<script>*</script>`
/// - tag: Regex for tags: `<td>`, `<tr>` etc.
internal enum Regex: String {
	
	case urls = "(?i)(<?href\\s*=\\s*[\"\"'])((http|https)(:\\/\\/)(.+?))([\"\"'].*?)" // group 2
	case body = "(?i)(<body\\X*?>)(\\X.*)(?<=<\\/body>)" // group 1
	
	case script = "<(script|style)\\X*?<\\/\\1>"
	case tag = "<\\X*?>"
	
	/// Range ingex of regex in match.
	var rangeIndex: Int {
		switch self {
		case .urls:
			return 2
		case .body:
			return 1
		case .script:
			return 0
		case .tag:
			return 0
		}
	}
	
	/// Number of ranges in regex.
	var numberOfRanges: Int {
		switch self {
		case .urls:
			return 7
		case .body:
			return 3
		case .script:
			return 2
		case .tag:
			return 1
		}
	}
	
}
