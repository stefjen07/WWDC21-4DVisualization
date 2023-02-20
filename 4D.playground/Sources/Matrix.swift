import Foundation

class Matrix {
	var data: [[Double]]
	var rows: Int {
		data.count
	}
	var cols: Int {
		data.first?.count ?? 0
	}
	
	init(_ rows: Int, _ cols: Int) {
		data = [[Double]]()
		for _ in 0..<rows {
			data.append(Array(repeating: 0, count: cols))
		}
	}
	
	init(_ vector: Vector) {
		if let z = vector.z {
			if let w = vector.w {
				data = [
					[vector.x],
					[vector.y],
					[z],
					[w]
				]
			} else {
				data = [
					[vector.x],
					[vector.y],
					[z]
				]
			}
		} else {
			data = [
				[vector.x],
				[vector.y]
			]
		}
	}
	
	func map( fnc: (_ v: Double, _ i: Int, _ j: Int) -> Double ) -> Matrix {
		for i in 0..<rows {
			for j in 0..<cols {
				data[i][j] = fnc(data[i][j], i, j)
			}
		}
		return self
	}
}

extension Matrix {
	static func identity(_ d: Int) -> Matrix {
		return Matrix(d, d).map() { (v, i, j) -> Double in
			return Double(i == j)
		}
	}
	
	static func rotation(_ axis1: Int, _ axis2: Int, _ d: Int, _ theta: Double) -> Matrix {
		let rot = Matrix.identity(d)
		rot.data[axis1][axis1] = cos(theta)
		rot.data[axis1][axis2] = -sin(theta)
		rot.data[axis2][axis1] = sin(theta)
		rot.data[axis2][axis2] = cos(theta)
		return rot
	}
	
	static func projection(_ n: Int, _ k: Double) -> Matrix {
		return Matrix(n-1, n).map() { (v,i,j) -> Double in
			return Double(i == j)*k
		}
	}
	
	static func perspective(_ n: Int, _ d: Double, _ p: Double) -> Matrix {
		return Matrix.projection(n, 1.0/(d-p))
	}
	
	static func multiply(_ m1: Matrix, _ m2: Matrix) -> Matrix {
		if(m1.cols != m2.rows) {
			return Matrix(0, 0)
		}
		return Matrix(m1.rows, m2.cols).map() { (v,i,j) -> Double in
			var sum = Double()
			for k in 0..<m1.cols {
				sum += m1.data[i][k] * m2.data[k][j];
			}
			return sum;
		}
	}
}
