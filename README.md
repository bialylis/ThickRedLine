# ThickRedLine
Thick Red Line - drawing thick lines with constant on-screen width for SceneKit with metal shaders

Example:
```swift
let geometry = SCNGeometry.lineThrough(points: [SCNVector3(0, 0,0), SCNVector3(0, 10, 0), SCNVector3(10, 10, 0)],
                                       width: 20,
                                       closed: false,
                                       color: UIColor.red.cgColor)
let node = SCNNode(geometry: geometry)
scene.rootNode.addChildNode(node)
```
![Thick line gif](https://github.com/bialylis/ThickRedLine/blob/master/readme_images/recording.gif "Animated gif of of thick red line")

Parameters:
+ points - array of SCNVector3 indicating points on the line
+ width - (int) width of line in points
+ closed - (bool) if line should for a loop
+ color - (CGColor) color of the line 
+ mitter - (bool) if line should form a sharp mitter at the joints. Feature is WIP - not supported with closed (the first and last joint will not be mittered) and there are artefacts when angle between the lines is too small

![img1](https://github.com/bialylis/ThickRedLine/blob/master/readme_images/img1.jpg)
![img2](https://github.com/bialylis/ThickRedLine/blob/master/readme_images/img2.png)
![img3](https://github.com/bialylis/ThickRedLine/blob/master/readme_images/img3.png)


