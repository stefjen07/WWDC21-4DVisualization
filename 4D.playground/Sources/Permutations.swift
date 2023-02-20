import Foundation

class Permutations {
	static func get(source: [Double]) -> [Vector] {
		var result = [Vector]()
		for x in 0..<source.count {
			for y in 0..<source.count {
				if(x == y) {
					continue
				}
				for z in 0..<source.count {
					if(x==z || y==z) {
						continue
					}
					for w in 0..<source.count {
						if(x==w || y==w || z==w) {
							continue
						}
						result.append(Vector(source[x], source[y], source[z], source[w]))
					}
				}
			}
		}
		return result
	}

	static func even(source: [Double]) -> [Vector] {
		let base = Vector(source[0], source[1], source[2], source[3])
		return get(source: source).filter { Vector.parity($0, base: base) }
	}

	static func sign(source: [Double], currentIndex: Int = 0) -> [[Double]] {
		if(currentIndex >= source.count) {
			return [source]
		}

		var result = [[Double]]()
		result.append(contentsOf: Permutations.sign(source: source, currentIndex: currentIndex+1))
		var minusSource = source
		minusSource[currentIndex] = -minusSource[currentIndex]
		result.append(contentsOf: Permutations.sign(source: minusSource, currentIndex: currentIndex+1))
		return result
	}
}
