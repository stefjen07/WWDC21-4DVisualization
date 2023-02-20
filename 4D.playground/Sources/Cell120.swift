import Foundation

class Cell120: Object4D {
	init() {
		let vertices = {
			var result = [Vector]()
			var signPerms = Permutations.sign(source: [0,pow(goldenRatio,-2),1, goldenRatio.square]) +
			Permutations.sign(source: [0,1/goldenRatio,goldenRatio,sqrt(5)]) +
			Permutations.sign(source: [1/goldenRatio,1,goldenRatio,2])
			for i in signPerms {
				result.append(contentsOf: Permutations.even(source: i))
			}
			signPerms = Permutations.sign(source: [2,2,0,0]) +
			Permutations.sign(source: [sqrt(5),1,1,1]) +
			Permutations.sign(source: [pow(goldenRatio,-2),goldenRatio,goldenRatio,goldenRatio]) +
			Permutations.sign(source: [goldenRatio.square,1/goldenRatio,1/goldenRatio,1/goldenRatio])
			for i in signPerms {
				result.append(contentsOf: Permutations.get(source: i))
			}
			return result.unique
		}()
		let edges = Edge.allPairs(vertices, distances: [3-sqrt(5)])
		
		super.init(name: "120-cell", vertexRadius: 0.5, vertices: vertices, edges: edges, cameraZ: 120)
	}
}
