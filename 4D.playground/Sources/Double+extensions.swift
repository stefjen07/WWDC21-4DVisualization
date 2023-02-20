import Foundation

extension Double {
	func rounded(toPlaces places: Int) -> Double {
		return Double(String(format: "%.\(places)f", self))!
	}

	var rounded: Double {
		rounded(toPlaces: 8)
	}
}

extension Double {
	init(_ value: Bool) {
		self = value ? 1 : 0
	}
}

extension Double {
	var square: Double {
		return self * self
	}
}
