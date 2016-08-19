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
    var gun : SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        gun = makeGun()
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
        cameraNode.position = SCNVector3(x: 0, y: 3, z: 13)
        cameraNode.camera?.zFar = 200.0
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    func spawnDisks() {
        var geometry : SCNGeometry
        geometry = SCNCone(topRadius: 1.5, bottomRadius: 2.0, height: 0.7)
        let physicsShape = SCNPhysicsShape(geometry: SCNTorus(ringRadius: 2.0, pipeRadius: 1.0), options: nil)
        let diskNode = SCNNode(geometry: geometry)
        //nil for the physics shape will automatically generate a shape based on the geometry of the node
        diskNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: physicsShape)
        let randomX = Float.random(min: 1, max: 10)
        let randomY = Float.random(min: 18, max: 30)
        let randomZ = Float.random(min: 13, max: 30)
        let randomSide = Int(arc4random_uniform(2))
        var force : SCNVector3
        if randomSide == 1 {
            diskNode.position.x = -8
            force = SCNVector3(x: randomX, y: randomY , z: -randomZ)
        } else {
            diskNode.position.x = 8
            force = SCNVector3(x: -randomX, y: randomY , z: -randomZ)
        }
        diskNode.physicsBody?.applyForce(force, impulse: true)
        geometry.materials.first?.diffuse.contents = UIColor.orangeColor()
        diskNode.name = "Disk"
        diskNode.physicsBody?.collisionBitMask = 1
        scnScene.rootNode.addChildNode(diskNode)
    }
    
    func fireGun(xTouch : CGFloat, yTouch : CGFloat) {
        let direction = (gun.childNodeWithName("Gun Sight", recursively: true)?.convertPosition(SCNVector3(0, 200, 0), toNode: scnScene.rootNode))!
        let bulletNode = makeBullet()
        bulletNode.physicsBody?.applyForce(direction, impulse: true)
        bulletNode.position = (gun.childNodeWithName("Gun Sight", recursively: true)?.convertPosition(SCNVector3(0, 1, -2), toNode: scnScene.rootNode))!
        scnScene.rootNode.addChildNode(bulletNode)
        createBarrelSmoke()
        gun.runAction(SCNAction.playAudioSource(SCNAudioSource(named: "ExplodeBad.wav")!, waitForCompletion: true))
    }
    
    func makeGun() -> SCNNode {
        let gunStockShape = SCNBox(width: 1.0, height: 1.0, length: 5.0, chamferRadius: 0.2)
        gunStockShape.materials.first?.diffuse.contents = UIColor.brownColor()
        let gunStockNode = SCNNode(geometry: gunStockShape)
        gunStockNode.position.z = 10
        gunStockNode.name = "Gun"
        gunStockNode.pivot = SCNMatrix4MakeTranslation(0, 0, 2.5)
        scnScene.rootNode.addChildNode(gunStockNode)
        
        let gunBarrelShape = SCNCylinder(radius: 0.4, height: 7.0)
        gunBarrelShape.materials.first?.diffuse.contents = UIColor.silverColor()
        let gunBarrelNode = SCNNode(geometry: gunBarrelShape)
        gunBarrelNode.position.z = -4
        gunBarrelNode.rotation.x = 90
        gunBarrelNode.rotation.y = 0
        gunBarrelNode.rotation.z = 0
        gunBarrelNode.rotation.w = 29.85
        gunBarrelNode.name = "Gun Barrel"
        gunStockNode.addChildNode(gunBarrelNode)
        
        let gunSightShape = SCNBox(width: 0.2, height: 1.0, length: 0.5, chamferRadius: 0)
        gunSightShape.materials.first?.diffuse.contents = UIColor.silverColor()
        let gunSightNode = SCNNode(geometry: gunSightShape)
        gunSightNode.position.z = 0.5
        gunSightNode.position.y = 3.1
        gunSightNode.name = "Gun Sight"
        gunBarrelNode.addChildNode(gunSightNode)
        
        //create invisible node at the tip of the gun for smoke
        let gunTipShape = SCNSphere(radius: 0.4)
        gunTipShape.materials.first?.diffuse.contents = UIColor.clearColor()
        let gunTipNode = SCNNode(geometry: gunTipShape)
        gunTipNode.position.y = 4
        gunTipNode.name = "Gun Tip"
        gunBarrelNode.addChildNode(gunTipNode)
        
        let crosshairsShape = SCNTorus(ringRadius: 0.7, pipeRadius: 0.1)
        gunSightShape.materials.first?.diffuse.contents = UIColor.whiteColor()
        let crosshairsNode = SCNNode(geometry: crosshairsShape)
        crosshairsNode.position.y = 30
        crosshairsNode.position.z = -1
        gunBarrelNode.addChildNode(crosshairsNode)
        
        return gunStockNode
    }
    
    func pointGun(xTouch : CGFloat, yTouch : CGFloat) {
        let xDir = (self.scnView.center.x - xTouch)/300
        let yDir = (self.scnView.frame.midY - (yTouch - 100))/350
        let direction = SCNVector3(yDir, xDir, 0)
        gun.eulerAngles = direction
    }
    
    func makeBullet() -> SCNNode {
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.2))
        bullet.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
        bullet.physicsBody?.affectedByGravity = false
        bullet.geometry?.materials.first?.diffuse.contents = UIColor.blackColor()
        bullet.position.z = 20
        bullet.name = "bullet"
        bullet.physicsBody?.contactTestBitMask = 1
        bullet.physicsBody?.collisionBitMask = 1
        return bullet
    }
    
    func cleanScene() {
        for node in scnScene.rootNode.childNodes {
            if node.presentationNode.position.y < -50 ||
               node.presentationNode.position.z < -200 {
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
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let xTouch = touches.first?.locationInView(self.scnView).x
        let yTouch = touches.first?.locationInView(self.scnView).y
        pointGun(xTouch!, yTouch: yTouch!)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let bulletQueue = dispatch_queue_create("bullet queue", DISPATCH_QUEUE_SERIAL)
        dispatch_async(bulletQueue) {
            let xTouch = touches.first?.locationInView(self.scnView).x
            let yTouch = touches.first?.locationInView(self.scnView).y
            self.fireGun(xTouch!, yTouch: yTouch!)
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
    
    func createBarrelSmoke() {
        let rotation = gun.childNodeWithName("Gun Tip", recursively: true)?.presentationNode.rotation
        let position = (gun.childNodeWithName("Gun Tip", recursively: true)?.presentationNode.convertPosition(SCNVector3(0, 0, 0), toNode: scnScene.rootNode))!
        let barrelSmoke = SCNParticleSystem(named: "barrelSmoke.scnp", inDirectory: nil)!
        barrelSmoke.emitterShape = gun.childNodeWithName("Gun Tip", recursively: true)?.geometry
        let rotationMatrix = SCNMatrix4MakeRotation(rotation!.w, rotation!.x, rotation!.y, rotation!.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(barrelSmoke, withTransform: transformMatrix)
    }
}

extension GameViewController : SCNSceneRendererDelegate {
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        if time > spawnTime {
            let shapeQueue : dispatch_queue_t = dispatch_queue_create("shape queue", DISPATCH_QUEUE_SERIAL)
            dispatch_async(shapeQueue) {
                self.spawnDisks()
            }
            let cleanUpQueue : dispatch_queue_t = dispatch_queue_create("clean up queue", DISPATCH_QUEUE_SERIAL)
            dispatch_async(cleanUpQueue) {
                self.cleanScene()
            }
            spawnTime = time + NSTimeInterval(Float.random(min: 1.0, max: 3.0))
        }
        game.updateHUD()
    }
}

extension GameViewController : SCNPhysicsContactDelegate {
    func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        if contact.nodeA.name == "bullet" {
            createExplosion(contact.nodeB.geometry!, position: contact.nodeA.presentationNode.position,
                            rotation: contact.nodeB.presentationNode.rotation)
            contact.nodeB.runAction(SCNAction.playAudioSource(SCNAudioSource(named: "ExplodeGood.wav")!, waitForCompletion: true))
        } else if contact.nodeB.name == "bullet" {
            createExplosion(contact.nodeA.geometry!, position: contact.nodeA.presentationNode.position,
                            rotation: contact.nodeA.presentationNode.rotation)
            contact.nodeA.runAction(SCNAction.playAudioSource(SCNAudioSource(named: "ExplodeGood.wav")!, waitForCompletion: true))
        }
    }
}