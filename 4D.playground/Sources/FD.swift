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
let permutations = [
    [X,Y],
    [X,Z],
    [X,W],
    [Y,Z],
    [Y,W],
    [Z,W]
]

var currentObject = 0
var cameraNode = SCNNode()
var textView = NSTextView(frame: NSRect(x: 640-180, y: 0, width: 180, height: 40))
var selectedNode = -1
var lastSelectedNode = -1
var cpointLines = SCNNode()
var material = SCNMaterial()
var selectingMaterial = SCNMaterial()
var cprojected = [Vector]()
var theta = Array(repeating: 0.0, count: 6)
var speed = Array(repeating: 0.0, count: 6)

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

class Object4D {
    var name: String
    var vertexRadius: CGFloat
    var vertices: [Vector]
    var edges: [Edge]
    var cameraZ: CGFloat
	var dm: Double
    func getDescription() -> String {
        return "\(name)\n\(vertices.count) vertices | \(edges.count) edges"
    }

	init(name: String, vertexRadius: CGFloat, vertices: [Vector], edges: [Edge], cameraZ: CGFloat, dm: Double = 2.0) {
		self.name = name
		self.vertexRadius = vertexRadius
		self.vertices = vertices
		self.edges = edges
		self.cameraZ = cameraZ
		self.dm = dm
	}
}

func sqr(_ n: Double) -> Double {
    return n*n
}

func getAllPairs(from i: Int, to j: Int, with distances: [Double], from vertices: [Vector]) -> [Edge] {
    var result = [Edge]()
    for m in i..<j {
        for k in m+1...j {
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

func vectorParity(vec: Vector, base: Vector) -> Bool {
    if let z = vec.z, let w = vec.w {
        var baseArr = [base.x,base.y,base.z,base.w]
        var cnt=0, a = [vec.x,vec.y,z,w]
        for i in 0..<4 {
            let j = baseArr.firstIndex(of: a[i])!
            baseArr.remove(at: j)
            cnt+=j-1
        }
        return cnt%2==0
    }
    return false
}

func getPermutations(c: [Double]) -> [Vector] {
    var result = [Vector]()
    for x in 0..<c.count {
        for y in 0..<c.count {
            if(x == y) {
                continue
            }
            for z in 0..<c.count {
                if(x==z || y==z) {
                    continue
                }
                for w in 0..<c.count {
                    if(x==w || y==w || z==w) {
                        continue
                    }
                    result.append(Vector(c[x], c[y], c[z], c[w]))
                }
            }
        }
    }
    return result
}

func evenPermutations(c: [Double]) -> [Vector] {
    var result = [Vector]()
    let base = Vector(c[0], c[1], c[2], c[3])
    for x in 0..<c.count {
        for y in 0..<c.count {
            if(x == y) {
                continue
            }
            for z in 0..<c.count {
                if(x==z || y==z) {
                    continue
                }
                for w in 0..<c.count {
                    if(x==w || y==w || z==w) {
                        continue
                    }
                    let vec = Vector(c[x], c[y], c[z], c[w])
                    if(vectorParity(vec: vec, base: base)) {
                        result.append(vec)
                    }
                }
            }
        }
    }
    return result
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

class FDScene: SCNScene {
    var pointNodes = [SCNNode]()
    func draw(speed: [Double], object: Object4D) {
        for i in 0..<object.vertices.count {
            let point = object.vertices[i]
            var pm = Matrix(point)
            for j in 0..<6 {
				pm = Matrix.multiply(Matrix.rotation(permutations[j][0], permutations[j][1], 4, theta[j]), pm)
            }
			pm = Matrix.multiply(Matrix.perspective(4, object.dm, Vector(pm).w!), pm)
            let pv = Vector(pm).multiply(scale)
            cprojected[i] = pv
        }
        for j in 0..<6 {
            theta[j]+=speed[j]
        }
    }
}

var fdscene = FDScene()

public class FDView: SCNView {
    public override func mouseDown(with event: NSEvent) {
        let options: [SCNHitTestOption: Any] = [
            .searchMode: 1
        ]
        let test = hitTest(event.locationInWindow, options: options)
        for result in test {
            for i in 0..<fdscene.pointNodes.count {
                if fdscene.pointNodes[i] == result.node {
                    if selectedNode == i {
                        lastSelectedNode = i
                        fdscene.pointNodes[selectedNode].geometry?.materials = [material]
                        selectedNode = -1
                    } else {
                        if(selectedNode != -1) {
                            lastSelectedNode = selectedNode
                            fdscene.pointNodes[selectedNode].geometry?.materials = [material]
                        }
                        selectedNode = i
                        let node = objects[currentObject].vertices[i]
                        print("X: \(node.x) Y: \(node.y) Z: \(node.z!) W: \(node.w!)")
                        if(lastSelectedNode != -1) {
							print("Distance from last node to current node: \(Vector.distance(objects[currentObject].vertices[lastSelectedNode], node))")
                        }
                        fdscene.pointNodes[selectedNode].geometry?.materials = [selectingMaterial]
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
        //node.isHidden = true
        fdscene.pointNodes.append(node)
        fdscene.rootNode.addChildNode(fdscene.pointNodes.last!)
    }
}

func removeVertices() {
    for i in fdscene.pointNodes {
        i.removeFromParentNode()
    }
    fdscene.pointNodes.removeAll()
}

func fullDraw(object: Object4D) {
    if(cprojected.count != object.vertices.count) {
        cprojected.removeAll()
        for _ in object.vertices {
            cprojected.append(Vector(0, 0))
        }
    }
    fdscene.draw(speed: speed, object: object)
    if(renderMode == .drawEdgesOnly || renderMode == .drawVerticesAndEdges) {
        var positions = [SCNVector3]()
        var indices = [Int]()
        for i in object.edges {
            positions.append(cprojected[i.vertex1].toSCNVector())
            positions.append(cprojected[i.vertex2].toSCNVector())
        }
        for i in positions.indices {
            indices.append(i)
        }
        let source = SCNGeometrySource(vertices: positions)
        let elements = SCNGeometryElement(data: Data(bytes: indices, count: MemoryLayout.size(ofValue: indices)), primitiveType: .line, primitiveCount: indices.count/2, bytesPerIndex: MemoryLayout<Int>.size)
        cpointLines.removeFromParentNode()
        let linesGeometry = SCNGeometry(sources: [source], elements: [elements])
        linesGeometry.materials = [material]
        cpointLines = SCNNode(geometry: linesGeometry)
        fdscene.rootNode.addChildNode(cpointLines)
    }
    if(renderMode == .drawVerticesOnly || renderMode == .drawVerticesAndEdges) {
        for i in 0..<cprojected.count {
            fdscene.pointNodes[i].position = cprojected[i].toSCNVector()
        }
    }
}

func updateDescription() {
    textView.string = objects[currentObject].getDescription()
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

public func startSetup() {
    material.diffuse.contents = renderColor
    selectingMaterial.diffuse.contents = selectingColor
    textView.isEditable = false
    view.addSubview(textView)
    view.backgroundColor = .black
    view.scene = fdscene
    let light = SCNLight()
    light.intensity = 2000
    light.type = .ambient
    light.zFar = 1000
    light.castsShadow = true
    fdscene.rootNode.light = light
    let camera = SCNCamera()
    camera.zFar = 1000
    cameraNode.camera = camera
    cameraNode.position = .init(x: 0, y: 0, z: objects[currentObject].cameraZ)
    fdscene.rootNode.addChildNode(cameraNode)
    addVertices(object: objects[currentObject])
    textView.backgroundColor = textBackgroundColor
    textView.textColor = getTextColor()
    updateDescription()
}

public func startRender() {
    Timer.scheduledTimer(withTimeInterval: 0.04167, repeats: true, block: { timer in
        fullDraw(object: objects[currentObject])
    })
}


let cell5vertices = [
    Vector(1/sqrt(10), 1/sqrt(6), 1/sqrt(3), 1),
    Vector(1/sqrt(10), 1/sqrt(6), 1/sqrt(3), -1),
    Vector(1/sqrt(10), 1/sqrt(6), -2/sqrt(3), 0),
    Vector(1/sqrt(10), -sqrt(1.5), 0, 0),
    Vector(-2*sqrt(0.4), 0, 0, 0)
]
let cell5edges = getAllPairs(from: 0, to: 4, with: [2], from: cell5vertices)
let tesseractVertices = {
	return signPermutations(source: [1, 1, 1, 1]).map { Vector($0[0], $0[1], $0[2], $0[3]) }
}()
let tesseractEdges = {
	return getAllPairs(from: 0, to: tesseractVertices.count - 1, with: [sqrt(4)], from: tesseractVertices)
}()
let cell16vertices = {
	return signPermutations(source: [1, 0, 0, 0]).map { getPermutations(c: $0) }.reduce([], +).unique
}()
let cell16edges = {
	return getAllPairs(from: 0, to: cell16vertices.count - 1, with: [sqrt(2)], from: cell16vertices)
}()
let cell24vertices = {
	return signPermutations(source: [1, 1, 0, 0]).map { getPermutations(c: $0) }.reduce([], +).unique
}()
let cell120vertices = {
	var result = [Vector]()
	var signPerms = signPermutations(source: [0,pow(goldenRatio,-2),1,sqr(goldenRatio)]) +
					signPermutations(source: [0,1/goldenRatio,goldenRatio,sqrt(5)]) +
					signPermutations(source: [1/goldenRatio,1,goldenRatio,2])
	for i in signPerms {
		result.append(contentsOf: evenPermutations(c: i))
	}
	signPerms = signPermutations(source: [2,2,0,0]) +
				signPermutations(source: [sqrt(5),1,1,1]) +
				signPermutations(source: [pow(goldenRatio,-2),goldenRatio,goldenRatio,goldenRatio]) +
				signPermutations(source: [sqr(goldenRatio),1/goldenRatio,1/goldenRatio,1/goldenRatio])
	for i in signPerms {
		result.append(contentsOf: getPermutations(c: i))
	}
	return result.unique
}()

let cell600vertices = {
	var result = [Vector]()
	var signPerms = signPermutations(source: [goldenRatio/2.0,0.5,0.5/goldenRatio,0])
	for i in signPerms {
		result.append(contentsOf: evenPermutations(c: i))
	}
	signPerms = signPermutations(source: [0.5,0.5,0.5,0.5]) + signPermutations(source: [0,0,0,1])
	for i in signPerms {
		result.append(contentsOf: getPermutations(c: i))
	}
	return result.unique
}()

let tesseract = Object4D(name: "Tesseract", vertexRadius: 2, vertices: tesseractVertices, edges: tesseractEdges, cameraZ: 100)
let cell5 = Object4D(name: "5-cell", vertexRadius: 1, vertices: cell5vertices, edges: cell5edges, cameraZ: 50)
let cell16 = Object4D(name: "16-cell", vertexRadius: 1, vertices: cell16vertices, edges: cell16edges, cameraZ: 50)
let cell24 = Object4D(name: "24-cell", vertexRadius: 1, vertices: cell24vertices, edges: getAllPairs(from: 0, to: cell24vertices.count-1, with: [sqrt(2)], from: cell24vertices), cameraZ: 50)
let cell120 = Object4D(name: "120-cell", vertexRadius: 0.5, vertices: cell120vertices, edges: getAllPairs(from: 0, to: cell120vertices.count-1, with: [3-sqrt(5)], from: cell120vertices), cameraZ: 50, dm: 4)
let cell600 = Object4D(name: "600-cell", vertexRadius: 0.5, vertices: cell600vertices, edges: getAllPairs(from: 0, to: 119, with: [1.0/goldenRatio,sqrt(8)], from: cell600vertices), cameraZ: 50,dm: goldenRatio)

var objects = [
    tesseract,
    cell5,
    cell16,
    cell24,
    cell120,
    cell600
]

