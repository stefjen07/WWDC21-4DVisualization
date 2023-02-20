import Foundation
import SceneKit

struct Vector: Equatable {
	var x: Double
	var y: Double
	var z: Double?
	var w: Double?

	init(_ x: Double, _ y: Double) {
		self.x = x
		self.y = y
	}

	init(_ x: Double, _ y: Double, _ z: Double) {
		self.x = x
		self.y = y
		self.z = z
	}

	init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
		self.x = x
		self.y = y
		self.z = z
		self.w = w
	}

	init(_ matrix: Matrix) {
		switch(matrix.rows) {
		case 3:
			self = Vector(matrix.data[0][0], matrix.data[1][0], matrix.data[2][0])
		case 4:
			self = Vector(matrix.data[0][0], matrix.data[1][0], matrix.data[2][0], matrix.data[3][0])
		default:
			self = Vector(matrix.data[0][0], matrix.data[1][0])
		}
	}

	func multiply(_ k: Double) -> Vector {
		var a = self
		a.x*=k
		a.y*=k
		a.z?*=k
		if a.w != nil {
			a.w!*=k
		}
		return a
	}

	func toSCNVector() -> SCNVector3 {
		var tz = 0.0
		if z != nil {
			tz = z!
		}
		return SCNVector3(x, y, tz)
	}

	static func ==(lhs: Vector, rhs: Vector) -> Bool {
		return lhs.x.rounded == rhs.x.rounded && lhs.y.rounded == rhs.y.rounded && lhs.z?.rounded == rhs.z?.rounded && lhs.w?.rounded == rhs.w?.rounded
	}
}

extension Vector {
	static func distance(_ vector1: Vector, _ vector2: Vector) -> Double {
		if let z1 = vector1.z, let z2 = vector2.z {
			if let w1 = vector1.w, let w2 = vector2.w {
				return sqrt((vector1.x-vector2.x).square+(vector1.y-vector2.y).square+(z1-z2).square+(w1-w2).square)
			}
			return sqrt((vector1.x-vector2.x).square+(vector1.y-vector2.y).square+(z1-z2).square)
		}
		return sqrt((vector1.x-vector2.x).square+(vector1.y-vector2.y).square)
	}
}

extension Array<Vector> {
	var unique: [Vector] {
		var result = [Vector]()
		for i in self {
			if(!result.contains(i)) {
				result.append(i)
			}
		}
		return result
	}
}
