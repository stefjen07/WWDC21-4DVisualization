import Foundation

class Cell120: Object4D {
	init() {
		let vertices = {
			var result = [Vector]()
			var signPerms = signPermutations(source: [0,pow(goldenRatio,-2),1, goldenRatio.square]) +
			signPermutations(source: [0,1/goldenRatio,goldenRatio,sqrt(5)]) +
			signPermutations(source: [1/goldenRatio,1,goldenRatio,2])
			for i in signPerms {
				result.append(contentsOf: evenPermutations(source: i))
			}
			signPerms = signPermutations(source: [2,2,0,0]) +
			signPermutations(source: [sqrt(5),1,1,1]) +
			signPermutations(source: [pow(goldenRatio,-2),goldenRatio,goldenRatio,goldenRatio]) +
			signPermutations(source: [goldenRatio.square,1/goldenRatio,1/goldenRatio,1/goldenRatio])
			for i in signPerms {
				result.append(contentsOf: getPermutations(source: i))
			}
			return result.unique
		}()
		let edges = getAllPairs(vertices: vertices, distances: [3-sqrt(5)])
		
		super.init(name: "120-cell", vertexRadius: 0.5, vertices: vertices, edges: edges, cameraZ: 120)
	}
}
