import Foundation
import SceneKit

public var renderColor = NSColor()
public var selectingColor = NSColor()
public var textBackgroundColor = NSColor()
public var renderMode: RenderMode = .drawVerticesAndEdges
public var view = FDView(frame: NSRect(x: 0, y: 0, width: 640, height: 480))

let goldenRatio = (1.0+sqrt(5))/2
let X = 0, Y = 1, Z = 2, W = 3
let scale = 25.0
let fieldOfView = Double.pi
let permutations = [
	[X,Y],
	[X,Z],
	[X,W],
	[Y,Z],
	[Y,W],
	[Z,W]
]

var currentObject = 0
var selectedNode = -1
var lastSelectedNode = -1
var material = SCNMaterial()
var selectingMaterial = SCNMaterial()

public enum RenderMode {
	case drawVerticesAndEdges
	case drawVerticesOnly
	case drawEdgesOnly
}

struct Edge {
	var vertex1: Int
	var vertex2: Int
	init(_ vertex1: Int, _ vertex2: Int) {
		self.vertex1 = vertex1
		self.vertex2 = vertex2
	}
}

func getAllPairs(vertices: [Vector], distances: [Double]) -> [Edge] {
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

func vectorParity(vector: Vector, base: Vector) -> Bool {
	if let z = vector.z, let w = vector.w {
		var baseArr = [base.x,base.y,base.z,base.w]
		var count = 0, a = [vector.x, vector.y, z, w]
		for i in 0..<4 {
			let j = baseArr.firstIndex(of: a[i])!
			baseArr.remove(at: j)
			count += j-1
		}
		return count % 2==0
	}
	return false
}

func getPermutations(source: [Double]) -> [Vector] {
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

func evenPermutations(source: [Double]) -> [Vector] {
	let base = Vector(source[0], source[1], source[2], source[3])
	return getPermutations(source: source).filter { vectorParity(vector: $0, base: base) }
}

func signPermutations(source: [Double], currentIndex: Int = 0) -> [[Double]] {
	if(currentIndex >= source.count) {
		return [source]
	}

	var result = [[Double]]()
	result.append(contentsOf: signPermutations(source: source, currentIndex: currentIndex+1))
	var minusSource = source
	minusSource[currentIndex] = -minusSource[currentIndex]
	result.append(contentsOf: signPermutations(source: minusSource, currentIndex: currentIndex+1))
	return result
}

public class FDView: SCNView {
	var textView = NSTextView(frame: NSRect(x: 640-180, y: 0, width: 180, height: 40))

	var cameraNode = SCNNode()
	var pointNodes = [SCNNode]()
	var pointLines = SCNNode()

	var objects = Object4D.defaultObjects

	var projectedVertices = [Vector]()

	var theta = Array(repeating: 0.0, count: 6)
	var speed = Array(repeating: 0.0, count: 6)

	func rotate(speed: [Double], object: Object4D) {
		for i in 0..<object.vertices.count {
			let point = object.vertices[i]
			var pointMatrix = Matrix(point)
			for j in 0..<6 {
				pointMatrix = Matrix.multiply(Matrix.rotation(permutations[j][0], permutations[j][1], 4, theta[j]), pointMatrix)
			}
			pointMatrix = Matrix.multiply(Matrix.perspective(4, fieldOfView, Vector(pointMatrix).w!), pointMatrix)
			let pointVector = Vector(pointMatrix).multiply(scale)
			projectedVertices[i] = pointVector
		}
		for j in 0..<6 {
			theta[j]+=speed[j]
		}
	}

	public override func mouseDown(with event: NSEvent) {
		let options: [SCNHitTestOption: Any] = [
			.searchMode: 1
		]
		let test = hitTest(event.locationInWindow, options: options)
		for result in test {
			for i in 0..<pointNodes.count {
				if pointNodes[i] == result.node {
					if selectedNode == i {
						lastSelectedNode = i
						pointNodes[selectedNode].geometry?.materials = [material]
						selectedNode = -1
					} else {
						if(selectedNode != -1) {
							lastSelectedNode = selectedNode
							pointNodes[selectedNode].geometry?.materials = [material]
						}
						selectedNode = i
						let node = objects[currentObject].vertices[i]
						print("X: \(node.x) Y: \(node.y) Z: \(node.z!) W: \(node.w!)")
						if(lastSelectedNode != -1) {
							print("Distance from last node to current node: \(Vector.distance(objects[currentObject].vertices[lastSelectedNode], node))")
						}
						pointNodes[selectedNode].geometry?.materials = [selectingMaterial]
					}
					break
				}
			}
		}
	}

	public override func keyDown(with event: NSEvent) {
		let baseSpeed = 0.1
		if(event.keyCode == 12) {
			speed[0] = baseSpeed
		}
		if(event.keyCode == 13) {
			speed[0] = -baseSpeed
		}
		if(event.keyCode == 0) {
			speed[1] = baseSpeed
		}
		if(event.keyCode == 1) {
			speed[1] = -baseSpeed
		}
		if(event.keyCode == 14) {
			speed[2] = baseSpeed
		}
		if(event.keyCode == 15) {
			speed[2] = -baseSpeed
		}
		if(event.keyCode == 2) {
			speed[3] = baseSpeed
		}
		if(event.keyCode == 3) {
			speed[3] = -baseSpeed
		}
		if(event.keyCode == 17) {
			speed[4] = baseSpeed
		}
		if(event.keyCode == 16) {
			speed[4] = -baseSpeed
		}
		if(event.keyCode == 5) {
			speed[5] = baseSpeed
		}
		if(event.keyCode == 4) {
			speed[5] = -baseSpeed
		}
		if event.keyCode == 0x08 {
			theta = .init(repeating: .zero, count: 6)
		}
		if(event.keyCode == 45) {
			removeVertices()
			selectedNode = -1
			currentObject+=1
			if(currentObject == objects.count) {
				currentObject=0
			}
			cameraNode.position = .init(x: 0, y: 0, z: objects[currentObject].cameraZ)
			addVertices(object: objects[currentObject])
			updateDescription()
		}
	}

	public override func keyUp(with event: NSEvent) {
		if(event.keyCode == 12 || event.keyCode == 13) {
			speed[0] = 0
		}
		if(event.keyCode == 0 || event.keyCode == 1) {
			speed[1] = 0
		}
		if(event.keyCode == 14 || event.keyCode == 15) {
			speed[2] = 0
		}
		if(event.keyCode == 2 || event.keyCode == 3) {
			speed[3] = 0
		}
		if(event.keyCode == 17 || event.keyCode == 16) {
			speed[4] = 0
		}
		if(event.keyCode == 5 || event.keyCode == 4) {
			speed[5] = 0
		}
	}

	func addVertices(object: Object4D) {
		if(renderMode == .drawEdgesOnly) {
			return
		}
		for _ in object.vertices {
			let sphereGeometry = SCNSphere(radius: object.vertexRadius)
			sphereGeometry.materials = [material]
			let node = SCNNode(geometry: sphereGeometry)
			node.position = SCNVector3(0, 0, 0)
			pointNodes.append(node)
			scene?.rootNode.addChildNode(node)
		}
	}

	func removeVertices() {
		for i in pointNodes {
			i.removeFromParentNode()
		}
		pointNodes.removeAll()
	}

	func draw(object: Object4D) {
		if(projectedVertices.count != object.vertices.count) {
			projectedVertices.removeAll()
			for _ in object.vertices {
				projectedVertices.append(Vector(0, 0))
			}
		}

		rotate(speed: speed, object: object)
		
		if(renderMode == .drawEdgesOnly || renderMode == .drawVerticesAndEdges) {
			var positions = [SCNVector3]()
			var indices = [Int]()
			for i in object.edges {
				positions.append(projectedVertices[i.vertex1].toSCNVector())
				positions.append(projectedVertices[i.vertex2].toSCNVector())
			}
			for i in positions.indices {
				indices.append(i)
			}

			let source = SCNGeometrySource(vertices: positions)
			let elements = SCNGeometryElement(
				data: Data(bytes: indices, count: MemoryLayout.size(ofValue: indices)),
				primitiveType: .line,
				primitiveCount: indices.count/2,
				bytesPerIndex: MemoryLayout<Int>.size
			)
			pointLines.removeFromParentNode()
			let linesGeometry = SCNGeometry(sources: [source], elements: [elements])
			linesGeometry.materials = [material]
			pointLines = SCNNode(geometry: linesGeometry)
			scene?.rootNode.addChildNode(pointLines)
		}
		if(renderMode == .drawVerticesOnly || renderMode == .drawVerticesAndEdges) {
			for i in 0..<projectedVertices.count {
				pointNodes[i].position = projectedVertices[i].toSCNVector()
			}
		}
	}

	public func setup() {
		scene = SCNScene()

		material.diffuse.contents = renderColor
		selectingMaterial.diffuse.contents = selectingColor
		textView.isEditable = false
		addSubview(textView)
		backgroundColor = .black
		let light = SCNLight()
		light.intensity = 2000
		light.type = .ambient
		light.zFar = 1000
		light.castsShadow = true
		scene?.rootNode.light = light
		let camera = SCNCamera()
		camera.zFar = 1000
		cameraNode.camera = camera
		cameraNode.position = .init(x: 0, y: 0, z: objects[currentObject].cameraZ)
		scene?.rootNode.addChildNode(cameraNode)
		addVertices(object: objects[currentObject])
		textView.backgroundColor = textBackgroundColor
		textView.textColor = getTextColor()
		updateDescription()
	}

	func updateDescription() {
		textView.string = objects[currentObject].description
	}

	func getTextColor() -> NSColor {
		if let background = CIColor(color: textBackgroundColor) {
			let middle = (background.red+background.green+background.blue)/3.0
			if(middle>0.5) {
				return .black
			}
		}
		return .white
	}

	public func startRender() {
		Timer.scheduledTimer(withTimeInterval: 0.04167, repeats: true, block: { timer in
			self.draw(object: self.objects[currentObject])
		})
	}
}
