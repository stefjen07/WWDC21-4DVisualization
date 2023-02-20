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

public enum RenderMode {
	case drawVerticesAndEdges
	case drawVerticesOnly
	case drawEdgesOnly
}

public class FDView: SCNView {
	var textView = NSTextView(frame: NSRect(x: 640-180, y: 0, width: 180, height: 40))

	var cameraNode = SCNNode()
	var pointNodes = [SCNNode]()
	var pointLines = SCNNode()
	let material = SCNMaterial()
	let selectingMaterial = SCNMaterial()

	var currentObjectIndex = 0
	var selectedNode: Int? = nil
	var lastSelectedNode: Int? = nil

	var objects = Object4D.defaultObjects
	var currentObject: Object4D {
		objects[currentObjectIndex]
	}

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
						pointNodes[i].geometry?.materials = [material]
						selectedNode = nil
					} else {
						if let selectedNode = selectedNode {
							lastSelectedNode = selectedNode
							pointNodes[selectedNode].geometry?.materials = [material]
						}
						selectedNode = i
						let node = currentObject.vertices[i]
						print("X: \(node.x) Y: \(node.y) Z: \(node.z!) W: \(node.w!)")
						if let lastSelectedNode = lastSelectedNode {
							print("Distance from last node to current node: \(Vector.distance(currentObject.vertices[lastSelectedNode], node))")
						}
						pointNodes[i].geometry?.materials = [selectingMaterial]
					}
					break
				}
			}
		}
	}

	public override func keyDown(with event: NSEvent) {
		let baseSpeed = 0.1
		switch event.keyCode {
		case 12:
			speed[0] = baseSpeed
		case 13:
			speed[0] = -baseSpeed
		case 0:
			speed[1] = baseSpeed
		case 1:
			speed[1] = -baseSpeed
		case 14:
			speed[2] = baseSpeed
		case 15:
			speed[2] = baseSpeed
		case 2:
			speed[3] = -baseSpeed
		case 3:
			speed[3] = -baseSpeed
		case 17:
			speed[4] = baseSpeed
		case 16:
			speed[4] = -baseSpeed
		case 5:
			speed[5] = baseSpeed
		case 4:
			speed[5] = -baseSpeed
		case 0x08:
			theta = .init(repeating: .zero, count: 6)
		case 45:
			removeVertices()
			selectedNode = -1

			currentObjectIndex = (currentObjectIndex + 1) % objects.count

			cameraNode.position = .init(x: 0, y: 0, z: currentObject.cameraZ)
			addVertices(object: currentObject)
			updateDescription()
		default:
			break
		}
	}

	public override func keyUp(with event: NSEvent) {
		switch event.keyCode {
		case 12, 13:
			speed[0] = 0
		case 0, 1:
			speed[1] = 0
		case 14, 15:
			speed[2] = 0
		case 2, 3:
			speed[3] = 0
		case 17, 16:
			speed[4] = 0
		case 5, 4:
			speed[5] = 0
		default:
			break
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
		cameraNode.position = .init(x: 0, y: 0, z: currentObject.cameraZ)
		scene?.rootNode.addChildNode(cameraNode)
		addVertices(object: currentObject)
		textView.backgroundColor = textBackgroundColor
		textView.textColor = textColor
		updateDescription()
	}

	func updateDescription() {
		textView.string = currentObject.description
	}

	var textColor: NSColor {
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
			self.draw(object: self.currentObject)
		})
	}
}
