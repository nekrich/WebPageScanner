//
//  Atomic.swift
//  WebPageScanner
//
//  Created by Vitalii Budnik on 8/1/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

/// Stores thread-safe read/write value.
internal struct Atomic<Value> {
	
	private var semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
	
	private var _value: Value
	var value: Value {
		get {
			lock(); defer { unlock() }
			let value = _value
			return value
		}
		set {
			lock(); defer { unlock() }
			_value = newValue
		}
	}
	
	private func lock() {
		semaphore.wait()
	}
	
	private func unlock() {
		semaphore.signal()
	}
	
	mutating func change(using block: (_ value: Value) -> Value) {
		var value = self.value
		
		lock()
		value = block(value)
		unlock()
		
		self.value = value
	}
	
	func changing(using block: (_ value: Value) -> Value) -> Atomic<Value> {
		var newAtomic = self
		
		newAtomic.change(using: block)
		
		return newAtomic
	}
	
	init(value: Value) {
		self._value = value
	}
	
}
