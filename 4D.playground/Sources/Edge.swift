import Foundation

struct Edge {
	var vertex1: Int
	var vertex2: Int

	init(_ vertex1: Int, _ vertex2: Int) {
		self.vertex1 = vertex1
		self.vertex2 = vertex2
	}
}

extension Edge {
	static func allPairs(_ vertices: [Vector], distances: [Double]) -> [Edge] {
		var result = [Edge]()
		for m in 0..<vertices.count-1 {
			for k in m+1..<vertices.count {
				let distance = Vector.distance(vertices[m],vertices[k]).rounded(toPlaces: 3)
				for d in distances {
					if(distance == d.rounded(toPlaces: 3)) {
						result.append(Edge(m, k))
						break
					}
				}
			}
		}
		return result
	}
}
