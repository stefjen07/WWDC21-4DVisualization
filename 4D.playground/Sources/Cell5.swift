import Foundation

class Cell5: Object4D {
	init() {
		let vertices = [
			Vector(1/sqrt(10), 1/sqrt(6), 1/sqrt(3), 1),
			Vector(1/sqrt(10), 1/sqrt(6), 1/sqrt(3), -1),
			Vector(1/sqrt(10), 1/sqrt(6), -2/sqrt(3), 0),
			Vector(1/sqrt(10), -sqrt(1.5), 0, 0),
			Vector(-2*sqrt(0.4), 0, 0, 0)
		]
		let edges = Edge.allPairs(vertices, distances: [2])
		
		super.init(name: "5-cell", vertexRadius: 1, vertices: vertices, edges: edges, cameraZ: 25)
	}
}
