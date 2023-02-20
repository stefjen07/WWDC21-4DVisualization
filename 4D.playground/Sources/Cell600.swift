import Foundation

class Cell600: Object4D {
	init() {
		let vertices = {
			var result = [Vector]()
			var signPerms = Permutations.sign(source: [goldenRatio/2.0,0.5,0.5/goldenRatio,0])
			for i in signPerms {
				result.append(contentsOf: Permutations.even(source: i))
			}
			signPerms = Permutations.sign(source: [0.5,0.5,0.5,0.5]) + Permutations.sign(source: [0,0,0,1])
			for i in signPerms {
				result.append(contentsOf: Permutations.get(source: i))
			}
			return result.unique
		}()
		let edges = Edge.allPairs(vertices, distances: [1.0/goldenRatio,sqrt(8)])
		
		super.init(name: "600-cell", vertexRadius: 0.5, vertices: vertices, edges: edges, cameraZ: 25)
	}
}
