import Foundation

class Cell24: Object4D {
	init() {
		let vertices = Permutations.sign(source: [1, 1, 0, 0]).map { Permutations.get(source: $0) }.reduce([], +).unique
		let edges = Edge.allPairs(vertices, distances: [sqrt(2)])
		
		super.init(name: "24-cell", vertexRadius: 1, vertices: vertices, edges: edges, cameraZ: 25)
	}
}
