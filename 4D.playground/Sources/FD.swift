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

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        return Double(String(format: "%.\(places)f", self))!
    }
}

struct Vector: Equatable {
    var x: Double
    var y: Double
    var z: Double?
    var w: Double?
    
    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
    
    init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    func multiply(_ k: Double) -> Vector {
        var a = self
        a.x*=k
        a.y*=k
        if a.z != nil {
            a.z!*=k
        }
        if a.w != nil {
            a.w!*=k
        }
        return a
    }
    
    func toSCNVector() -> SCNVector3 {
        var tz = 0.0
        if z != nil {
            tz = z!
        }
        return SCNVector3(x, y, tz)
    }
    
    static func ==(lhs: Vector, rhs: Vector) -> Bool {
        return lhs.x.rounded(toPlaces: 8) == rhs.x.rounded(toPlaces: 8) && lhs.y.rounded(toPlaces: 8) == rhs.y.rounded(toPlaces: 8) && lhs.z?.rounded(toPlaces: 8) == rhs.z?.rounded(toPlaces: 8) && lhs.w?.rounded(toPlaces: 8) == rhs.w?.rounded(toPlaces: 8)
    }
}

struct Edge {
    var vertex1: Int
    var vertex2: Int
    init(_ vertex1: Int, _ vertex2: Int) {
        self.vertex1 = vertex1
        self.vertex2 = vertex2
    }
}

struct Object4D {
    var name: String
    var vertexRadius: CGFloat
    var vertices: [Vector]
    var edges: [Edge]
    var cameraZ: CGFloat
    var dm = 2.0
    func getDescription() -> String {
        return "\(name)\n\(vertices.count) vertices | \(edges.count) edges"
    }
}

func sqr(_ n: Double) -> Double {
    return n*n
}

func getDistance(_ vector1: Vector, _ vector2: Vector) -> Double {
    if let z1 = vector1.z, let z2 = vector2.z {
        if let w1 = vector1.w, let w2 = vector2.w {
            return sqrt(sqr(vector1.x-vector2.x)+sqr(vector1.y-vector2.y)+sqr(z1-z2)+sqr(w1-w2))
        }
        return sqrt(sqr(vector1.x-vector2.x)+sqr(vector1.y-vector2.y)+sqr(z1-z2))
    }
    return sqrt(sqr(vector1.x-vector2.x)+sqr(vector1.y-vector2.y))
}

func getAllPairs(from i: Int, to j: Int, with distances: [Double], from vertices: [Vector]) -> [Edge] {
    var result = [Edge]()
    for m in i..<j {
        for k in m+1...j {
            let distance = getDistance(vertices[m],vertices[k]).rounded(toPlaces: 3)
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

func uniqueVectors(a: [Vector]) -> [Vector] {
    var result = [Vector]()
    for i in a {
        if(!result.contains(i)) {
            result.append(i)
        }
    }
    return result
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

func signPermutations(c: [Double], idx: Int) -> [[Double]] {
    if(idx == c.count) {
        return [c]
    }
    var result = [[Double]]()
    result.append(contentsOf: signPermutations(c: c, idx: idx+1))
    var ccopy = c
    ccopy[idx] = -ccopy[idx]
    result.append(contentsOf: signPermutations(c: ccopy, idx: idx+1))
    return result
}

class Matrix {
    var data: [[Double]]
    var rows: Int
    var cols: Int
    
    init(_ rows: Int, _ cols: Int) {
        data = [[Double]]()
        self.rows = rows
        self.cols = cols
        for _ in 0..<rows {
            data.append(Array(repeating: 0, count: cols))
        }
    }
    
    func toVec() -> Vector {
        switch(rows) {
        case 3:
            return Vector(data[0][0], data[1][0], data[2][0])
        case 4:
            return Vector(data[0][0], data[1][0], data[2][0], data[3][0])
        default:
            return Vector(data[0][0], data[1][0])
        }
    }
    
    func map( fnc: (_ v: Double, _ i: Int, _ j: Int) -> Double ) -> Matrix {
        for i in 0..<rows {
            for j in 0..<cols {
                data[i][j] = fnc(data[i][j], i, j)
            }
        }
        return self
    }
}

func matrixFromVec(vec: Vector) -> Matrix {
    if let w = vec.w {
        let m = Matrix(4, 1)
        let z = vec.z!
        m.data = [
            [vec.x],
            [vec.y],
            [z],
            [w]
        ]
        return m
    } else if let z = vec.z {
        let m = Matrix(3, 1)
        m.data = [
            [vec.x],
            [vec.y],
            [z]
        ]
        return m
    } else {
        let m = Matrix(2, 1)
        m.data = [
            [vec.x],
            [vec.y]
        ]
        return m
    }
}

func matrixMultiply(m1: Matrix, m2: Matrix) -> Matrix {
    if(m1.cols != m2.rows) {
        return Matrix(0, 0)
    }
    return Matrix(m1.rows, m2.cols).map() { (v,i,j) -> Double in
        var sum = Double()
        for k in 0..<m1.cols {
            sum += m1.data[i][k] * m2.data[k][j];
        }
        return sum;
    }
}

func matrixIdentity(_ d: Int) -> Matrix {
    return Matrix(d, d).map() { (v, i, j) -> Double in
        return boolToDouble(i==j)
    }
}

func matrixRotation(_ axis1: Int, _ axis2: Int, _ d: Int, _ theta: Double) -> Matrix {
    let rot = matrixIdentity(d)
    rot.data[axis1][axis1] = cos(theta)
    rot.data[axis1][axis2] = -sin(theta)
    rot.data[axis2][axis1] = sin(theta)
    rot.data[axis2][axis2] = cos(theta)
    return rot
}

func matrixProjection(_ n: Int, _ k: Double) -> Matrix {
    return Matrix(n-1, n).map() { (v,i,j) -> Double in
        return boolToDouble(i==j)*k
    }
}

func matrixPerspective(_ n: Int, _ d: Double, _ p: Double) -> Matrix {
    return matrixProjection(n, 1.0/(d-p))
}

func boolToDouble(_ v: Bool) -> Double {
    return v ? 1 : 0
}

class FDScene: SCNScene {
    var pointNodes = [SCNNode]()
    func draw(speed: [Double], object: Object4D) {
        for i in 0..<object.vertices.count {
            let point = object.vertices[i]
            var pm = matrixFromVec(vec: point)
            for j in 0..<6 {
                pm = matrixMultiply(m1: matrixRotation(permutations[j][0], permutations[j][1], 4, theta[j]), m2: pm)
            }
            pm = matrixMultiply(m1: matrixPerspective(4, object.dm, pm.toVec().w!), m2: pm)
            let pv = pm.toVec().multiply(scale)
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
                            print("Distance from last node to current node: \(getDistance(objects[currentObject].vertices[lastSelectedNode], node))")
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
let tesseractVertices = [
    Vector(-1, -1, -1, 1),
    Vector(1, -1, -1, 1),
    Vector(1, 1, -1, 1),
    Vector(-1, 1, -1, 1),
    Vector(-1, -1, 1, 1),
    Vector(1, -1, 1, 1),
    Vector(1, 1, 1, 1),
    Vector(-1, 1, 1, 1),
    Vector(-1, -1, -1, -1),
    Vector(1, -1, -1, -1),
    Vector(1, 1, -1, -1),
    Vector(-1, 1, -1, -1),
    Vector(-1, -1, 1, -1),
    Vector(1, -1, 1, -1),
    Vector(1, 1, 1, -1),
    Vector(-1, 1, 1, -1)
]
let tesseractEdges = [
    Edge(0, 1),
    Edge(4, 5),
    Edge(0, 4),
    Edge(1, 2),
    Edge(5, 6),
    Edge(1, 5),
    Edge(2, 3),
    Edge(6, 7),
    Edge(2, 6),
    Edge(3, 0),
    Edge(7, 4),
    Edge(3, 7),
    Edge(8, 9),
    Edge(12, 13),
    Edge(8, 12),
    Edge(9, 10),
    Edge(13, 14),
    Edge(9, 13),
    Edge(10, 11),
    Edge(14, 15),
    Edge(10, 14),
    Edge(11, 8),
    Edge(15, 12),
    Edge(11, 15),
    Edge(0, 8),
    Edge(1, 9),
    Edge(2, 10),
    Edge(3, 11),
    Edge(4, 12),
    Edge(5, 13),
    Edge(6, 14),
    Edge(7, 15)
]
let cell16vertices = [
    Vector(1, 0, 0, 0),
    Vector(-1, 0, 0, 0),
    Vector(0, 1, 0, 0),
    Vector(0, -1, 0, 0),
    Vector(0, 0, 1, 0),
    Vector(0, 0, -1, 0),
    Vector(0, 0, 0, 1),
    Vector(0, 0, 0, -1)
]
let cell16edges = [
    Edge(0, 2),
    Edge(0, 3),
    Edge(0, 4),
    Edge(0, 5),
    Edge(0, 6),
    Edge(0, 7),
    Edge(1, 2),
    Edge(1, 3),
    Edge(1, 4),
    Edge(1, 5),
    Edge(1, 6),
    Edge(1, 7),
    Edge(2, 4),
    Edge(2, 5),
    Edge(2, 6),
    Edge(2, 7),
    Edge(3, 4),
    Edge(3, 5),
    Edge(3, 6),
    Edge(3, 7),
    Edge(4, 6),
    Edge(4, 7),
    Edge(5, 6),
    Edge(5, 7)
]
let cell24vertices = [
    Vector(1, 1, 0, 0),
    Vector(-1, 1, 0, 0),
    Vector(1, -1, 0, 0),
    Vector(-1, -1, 0, 0),
    Vector(1, 0, 1, 0),
    Vector(-1, 0, 1, 0),
    Vector(1, 0, -1, 0),
    Vector(-1, 0, -1, 0),
    Vector(1, 0, 0, 1),
    Vector(-1, 0, 0, 1),
    Vector(1, 0, 0, -1),
    Vector(-1, 0, 0, -1),
    Vector(0, 1, 1, 0),
    Vector(0, -1, 1, 0),
    Vector(0, 1, -1, 0),
    Vector(0, -1, -1, 0),
    Vector(0, 1, 0, 1),
    Vector(0, -1, 0, 1),
    Vector(0, 1, 0, -1),
    Vector(0, -1, 0, -1),
    Vector(0, 0, 1, 1),
    Vector(0, 0, -1, 1),
    Vector(0, 0, 1, -1),
    Vector(0, 0, -1, -1)
]
func getCell120Vertices() -> [Vector] {
    var result = [Vector]()
    var signPerms = signPermutations(c: [0,pow(goldenRatio,-2),1,sqr(goldenRatio)], idx: 0)+signPermutations(c: [0,1/goldenRatio,goldenRatio,sqrt(5)], idx: 0)+signPermutations(c: [1/goldenRatio,1,goldenRatio,2], idx: 0)
    for i in signPerms {
        result.append(contentsOf: evenPermutations(c: i))
    }
    signPerms = signPermutations(c: [2,2,0,0], idx: 0)+signPermutations(c: [sqrt(5),1,1,1], idx: 0)+signPermutations(c: [pow(goldenRatio,-2),goldenRatio,goldenRatio,goldenRatio], idx: 0)+signPermutations(c: [sqr(goldenRatio),1/goldenRatio,1/goldenRatio,1/goldenRatio], idx: 0)
    for i in signPerms {
        result.append(contentsOf: getPermutations(c: i))
    }
    return uniqueVectors(a: result)
}
let cell120vertices = getCell120Vertices()
func getCell600Vertices() -> [Vector] {
    var result = [Vector]()
    var signPerms = signPermutations(c: [goldenRatio/2.0,0.5,0.5/goldenRatio,0], idx: 0)
    for i in signPerms {
        result.append(contentsOf: evenPermutations(c: i))
    }
    signPerms = signPermutations(c: [0.5,0.5,0.5,0.5], idx: 0)+signPermutations(c: [0,0,0,1], idx: 0)
    for i in signPerms {
        result.append(contentsOf: getPermutations(c: i))
    }
    return uniqueVectors(a: result)
}
let cell600vertices = getCell600Vertices()

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

