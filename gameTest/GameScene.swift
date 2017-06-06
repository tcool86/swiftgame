//
//  GameScene.swift
//  gameTest
//
//  Created by Timothy Cool on 5/5/17.
//  Copyright © 2017 Timothy Cool. All rights reserved.
//

import SpriteKit
import GameplayKit
import Foundation

enum KeyPressed : UInt16 {
    case up    = 126
    case down  = 125
    case left  = 123
    case right = 124
    case space = 49
}

class GameScene : SKScene, SKPhysicsContactDelegate {

    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    var gameCamera : SKCameraNode = SKCameraNode()
    var stars = [Star]()
    var starsInAura = [Base]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var player : Player?
    private var bases : [Base]?
    private var interactionTime : TimeInterval = 0

    override func sceneDidLoad() {
        self.view?.showsPhysics = true
        self.physicsWorld.contactDelegate = self
        
        self.lastUpdateTime = 0
        self.player = Player.init(imageNamed: "playerPlaceholder")
        self.player?.initPlayer()
        self.player?.position = CGPoint(x: 100, y: 100)
        self.addChild(self.player!)
    
        self.gameCamera.contains(self.player!)
        self.camera = self.gameCamera
        self.gameCamera.position = player!.position

        self.loadStars()
    }

    func loadStars() {
        guard let appDelegate = NSApplication.shared().delegate as? AppDelegate else {
            return
        }

        let managedContext = appDelegate.persistentContainer.viewContext
        let starFetch = Star.fetchRequestStar()
        managedContext.perform {
            self.stars = try! starFetch.execute()
            for star in self.stars {
                star.addStarToScene(scene: self)
            }
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        createStar(position: pos)
    }
    
    func touchMoved(toPoint pos : CGPoint) {}
    
    func touchUp(atPoint pos : CGPoint) {}
    
    override func mouseDown(with event: NSEvent) {
        self.touchDown(atPoint: event.location(in: self))
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.touchMoved(toPoint: event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        self.touchUp(atPoint: event.location(in: self))
    }
    
    override func keyDown(with event: NSEvent) {
        let key = event.keyCode
        if (key == KeyPressed.up.rawValue) {
            self.player?.fly(direction: .up)
        }else if (key == KeyPressed.down.rawValue) {
            self.player?.fly(direction: .down)
        }
        if (key == KeyPressed.left.rawValue) {
            self.player?.fly(direction: .left)
        }else if (key == KeyPressed.right.rawValue) {
            self.player?.fly(direction: .right)
        }
        if (key == KeyPressed.space.rawValue) {
            self.player?.special()
        }
    }

    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case KeyPressed.up.rawValue: break
        case KeyPressed.down.rawValue: break
        case KeyPressed.left.rawValue: break
        case KeyPressed.right.rawValue: break
        case KeyPressed.space.rawValue:
            self.player?.disableSpecial()
        default:
            print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }

        if (player?.isAuraActive())! {
            for base in starsInAura {
                base.reduceBaseHealth(amount: (self.player?.consumptionRate)! )
            }
        }

        self.gameCamera.position = player!.position
        
        self.lastUpdateTime = currentTime
    }

    func createStar() {
        let randomPosition = self.randomPositionInUniverse()
        self.createStar(position: randomPosition)
    }

    func createStar(position:CGPoint) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let star = Star(entity: Star.entity(), insertInto: managedContext)
        star.brightness = 10 + Float(drand48()) * 65.0
        star.position = position as NSObject?
        star.power = Int64(Float(1000.00) + (Float(drand48()) * 3000.0))
        do {
            try managedContext.save()
        } catch {
            let contextError = error as NSError
            fatalError("Error: \(contextError), \(contextError.userInfo)")
        }
        appDelegate.saveContext()
        star.addStarToScene(scene: self)
    }

    func randomPositionInUniverse() -> CGPoint {
        let x = drand48() * 800
        let y = drand48() * 800
        return CGPoint(x: x, y: y)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if (contact.bodyA.categoryBitMask == PhysicsCategory.PlayerAura
            && contact.bodyB.categoryBitMask == PhysicsCategory.Star) {
            print("in range")
            let star = contact.bodyB.node as! Base
            starsInAura.append(star)
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        if (contact.bodyA.categoryBitMask == PhysicsCategory.PlayerAura
            && contact.bodyB.categoryBitMask == PhysicsCategory.Star) {
            print("out of range")
            let star = contact.bodyB.node as! Base
            if (starsInAura.contains(star)) {
                let index = starsInAura.index(of: star)
                starsInAura.remove(at: index!)
            }
        }
    }
}
