import Foundation

extension Double {
	func rounded(toPlaces places: Int) -> Double {
		return Double(String(format: "%.\(places)f", self))!
	}
}

extension Double {
	init(_ value: Bool) {
		self = value ? 1 : 0
	}
}
