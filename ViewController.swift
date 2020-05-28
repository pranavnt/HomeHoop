//
//  ViewController.swift
//  HomeHoop!
//
//  Created by Pranav Teegavarapu on 5/24/20.
//  Copyright © 2020 Pranav Teegavarapu. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var timer: Timer?

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var planeDetected: UILabel!
    var power: Float = 1.0
    let configuration = ARWorldTrackingConfiguration()
    var basketAdded: Bool {
        return (self.sceneView.scene.rootNode.childNode(withName: "Basket", recursively: false) != nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded == true {
            timer =  Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (timer) in
                self.power += 1.0
            }
        }
    }
    
    
    
    func shootBall() {
        guard let pointOfView = self.sceneView.pointOfView else {return}
        let location = SCNVector3(pointOfView.transform.m41,pointOfView.transform.m42,pointOfView.transform.m43)
        let orientation = SCNVector3(-pointOfView.transform.m31,-pointOfView.transform.m32,-pointOfView.transform.m33)
        let position = location + orientation
        let ball = SCNNode(geometry: SCNSphere(radius: 0.3))
        ball.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "basketballImage")
        ball.position = position
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
        ball.physicsBody = body
    
        body.restitution = 0.2
        ball.physicsBody?.applyForce(SCNVector3(orientation.x*10.0,orientation.y*10.0,orientation.z*10.0), asImpulse: true)
        self.sceneView.scene.rootNode.addChildNode(ball)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded == true {
            if timer != nil {
                timer?.invalidate()
                timer = nil
            }
            self.shootBall()
        }
        self.power = 1.0
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
        if !hitTestResult.isEmpty {
            self.addBasket(hitTestResult: hitTestResult.first!)
        }
    }
    
    func addBasket(hitTestResult: ARHitTestResult) {
        let basketScene = SCNScene(named: "art.scnassets/Basketball.scn")!
        let basketNode = basketScene.rootNode.childNode(withName: "Basket", recursively: false)
        let positionOfPlane = hitTestResult.worldTransform.columns.3
        let xPos = positionOfPlane.x
        let yPos = positionOfPlane.y
        let zPos = positionOfPlane.z
        basketNode?.position = SCNVector3(xPos,yPos,zPos)
        self.sceneView.scene.rootNode.addChildNode(basketNode!)
        basketNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: basketNode!, options: [SCNPhysicsShape.Option.keepAsCompound: true, SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3){
          self.planeDetected.isHidden = true
        }
    }
    
    
    func timerCalculations() {
        self.power += 1.0
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x+right.x, left.y+right.y, left.z+right.z)
}
