/*:
 # 4D Visualization
 *This playground renders 4D objects and allows to perform double rotations of them.*
 ### Objects:
 - *Tesseract*
 - *5-cell*
 - *16-cell*
 - *24-cell*
 - *120-cell*
 - *600-cell*
 ### Controls:
 
 - Switch object - N
 
 - Click to select a vertex
 
 - Positive rotation by X & Y axes - Q
 - Negative rotation by X & Y axes - W
 
 - Positive rotation by X & Z axes - A
 - Negative rotation by X & Z axes - S
 
 - Positive rotation by X & W axes - E
 - Negative rotation by X & W axes - R
 
 - Positive rotation by Y & Z axes - D
 - Negative rotation by Y & Z axes - F
 
 - Positive rotation by Y & W axes - T
 - Negative rotation by Y & W axes - Y
 
 - Positive rotation by Z & W axes - G
 - Negative rotation by Z & W axes - H

 - Reset position - C
 */
import PlaygroundSupport
import SceneKit

renderMode = .drawEdgesOnly
renderColor = .red
textBackgroundColor = .white
selectingColor = .blue
startSetup()
PlaygroundPage.current.liveView = view
startRender()
