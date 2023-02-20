import Foundation

class Tesseract: Object4D {
	init() {
		let vertices = Permutations.sign(source: [1, 1, 1, 1]).map { Vector($0[0], $0[1], $0[2], $0[3]) }
		let edges = Edge.allPairs(vertices, distances: [sqrt(4)])
		
		super.init(name: "Tesseract", vertexRadius: 2, vertices: vertices, edges: edges, cameraZ: 50)
	}
}
