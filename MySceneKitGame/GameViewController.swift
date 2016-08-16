//
//  GameViewController.swift
//  MySceneKitGame
//
//  Created by Connor Mosley on 8/12/16.
//  Copyright (c) 2016 Connor Mosley. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var spawnTime:NSTimeInterval = 0
    var game = GameHelper.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        setupHUD()
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func setupView() {
        scnView = self.view as! SCNView
        scnView.showsStatistics = true
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.delegate = self
        scnView.playing = true
    }
    
    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.physicsWorld.contactDelegate = self
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.png"
    }
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 20)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    func spawnShape() {
        var geometry : SCNGeometry
        switch ShapeType.random() {
            case .Sphere:
                geometry = SCNSphere(radius: 1.0)
            case .Pyramid:
                geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
            case .Torus:
                geometry = SCNTorus(ringRadius: 1.0, pipeRadius: 0.5)
            case .Capsule:
                geometry = SCNCapsule(capRadius: 1.0, height: 1.5)
            case .Cylinder:
                geometry = SCNCylinder(radius: 1.0, height: 1.5)
            case .Cone:
                geometry = SCNCone(topRadius: 0.0, bottomRadius: 1.0, height: 1.0)
            case .Tube:
                geometry = SCNTube(innerRadius: 0.5, outerRadius: 1.0, height: 1.0)
            default:
                geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        }
        let geometryNode = SCNNode(geometry: geometry)
        //nil for the physics shape will automatically generate a shape based on the geometry of the node
        geometryNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        let force = SCNVector3(x: randomX, y: randomY , z: 0)
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        geometryNode.physicsBody?.applyForce(force, atPosition: position, impulse: true)
        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color
        let trailEmitter = createTrail(color, geometry: geometry)
        geometryNode.addParticleSystem(trailEmitter)
        if color == UIColor.blackColor() {
            geometryNode.name = "BAD"
        } else {
            geometryNode.name = "GOOD"
        }
        scnScene.rootNode.addChildNode(geometryNode)
    }
    
    func fireGun(direction: SCNVector3) {
        let geometryNode = SCNNode(geometry: SCNSphere(radius: 0.1))
        geometryNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
        geometryNode.physicsBody?.affectedByGravity = false
        geometryNode.physicsBody?.applyForce(direction, impulse: true)
        geometryNode.geometry?.materials.first?.diffuse.contents = UIColor.blackColor()
        geometryNode.position.z = 18
        geometryNode.name = "bullet"
        geometryNode.physicsBody?.contactTestBitMask = 1
        scnScene.rootNode.addChildNode(geometryNode)
    }
    
    func cleanScene() {
        for node in scnScene.rootNode.childNodes {
            if node.presentationNode.position.y < -10 ||
               node.presentationNode.position.z < -100 {
                node.removeFromParentNode()
            }
        }
    }
    
    func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
        let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        trail.particleColor = color
        trail.emitterShape = geometry
        return trail
    }
    
    func setupHUD() {
        game.hudNode.position = SCNVector3(x: 0.0, y: 15.0, z: 0.0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
//    func handleTouchFor(node: SCNNode) {
//        if node.name == "GOOD" {
//            game.score += 1
//            createExplosion(node.geometry!, position: node.presentationNode.position,
//                            rotation: node.presentationNode.rotation)
//            node.removeFromParentNode()
//        } else if node.name == "BAD" {
//            game.lives -= 1
//            createExplosion(node.geometry!, position: node.presentationNode.position,
//                            rotation: node.presentationNode.rotation)
//            node.removeFromParentNode()
//        }
//    }
//    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let bulletQueue = dispatch_queue_create("bullet queue", DISPATCH_QUEUE_SERIAL)
//        dispatch_async(dispatch_get_main_queue()) {
        dispatch_async(bulletQueue) {
            let xDir = -(self.scnView.center.x - (touches.first?.locationInView(self.scnView).x)!)/3
            let yDir = ((self.scnView.frame.maxY - (touches.first?.locationInView(self.scnView).y)!)/6)
            self.fireGun(SCNVector3(xDir, yDir, -150))
        }
    }
    
    func createExplosion(geometry: SCNGeometry, position: SCNVector3,
                         rotation: SCNVector4) {
        let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
        explosion.emitterShape = geometry
        explosion.birthLocation = .Surface
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x,
                                                    rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y,
                                                          position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(explosion, withTransform: transformMatrix)
    }
    
//    func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
//        if contact.nodeA.name == "bullet" {
//            createExplosion(contact.nodeB.geometry!, position: contact.nodeB.presentationNode.position,
//                            rotation: contact.nodeB.presentationNode.rotation)
//        } else if contact.nodeB.name == "bullet" {
//            createExplosion(contact.nodeA.geometry!, position: contact.nodeA.presentationNode.position,
//                            rotation: contact.nodeA.presentationNode.rotation)
//        }
//    }
}

extension GameViewController : SCNSceneRendererDelegate {
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        if time > spawnTime {
            let shapeQueue : dispatch_queue_t = dispatch_queue_create("shape queue", DISPATCH_QUEUE_SERIAL)
            dispatch_async(shapeQueue) {
                self.spawnShape()
            }
            spawnTime = time + NSTimeInterval(Float.random(min: 1.0, max: 3.0))
            cleanScene()
        }
        game.updateHUD()
    }
}

extension GameViewController : SCNPhysicsContactDelegate {
    func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        if contact.nodeA.name == "bullet" {
            createExplosion(contact.nodeB.geometry!, position: contact.nodeB.presentationNode.position,
                            rotation: contact.nodeB.presentationNode.rotation)
        } else if contact.nodeB.name == "bullet" {
            createExplosion(contact.nodeA.geometry!, position: contact.nodeA.presentationNode.position,
                            rotation: contact.nodeA.presentationNode.rotation)
        }
    }
}