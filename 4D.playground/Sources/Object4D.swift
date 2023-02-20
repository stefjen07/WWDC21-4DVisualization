import Foundation

class Object4D {
	static let defaultObjects = [
		Tesseract(),
		Cell5(),
		Cell16(),
		Cell24(),
		Cell120(),
		Cell600()
	]

	var name: String
	var vertexRadius: CGFloat
	var vertices: [Vector]
	var edges: [Edge]
	var cameraZ: CGFloat

	var description: String {
		return "\(name)\n\(vertices.count) vertices | \(edges.count) edges"
	}

	init(name: String, vertexRadius: CGFloat, vertices: [Vector], edges: [Edge], cameraZ: CGFloat) {
		self.name = name
		self.vertexRadius = vertexRadius
		self.vertices = vertices
		self.edges = edges
		self.cameraZ = cameraZ
	}
}
