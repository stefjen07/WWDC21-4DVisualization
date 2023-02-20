import Foundation

class Cell600: Object4D {
	init() {
		let vertices = {
			var result = [Vector]()
			var signPerms = signPermutations(source: [goldenRatio/2.0,0.5,0.5/goldenRatio,0])
			for i in signPerms {
				result.append(contentsOf: evenPermutations(source: i))
			}
			signPerms = signPermutations(source: [0.5,0.5,0.5,0.5]) + signPermutations(source: [0,0,0,1])
			for i in signPerms {
				result.append(contentsOf: getPermutations(source: i))
			}
			return result.unique
		}()
		let edges = getAllPairs(vertices: vertices, distances: [1.0/goldenRatio,sqrt(8)])
		
		super.init(name: "600-cell", vertexRadius: 0.5, vertices: vertices, edges: edges, cameraZ: 25)
	}
}
