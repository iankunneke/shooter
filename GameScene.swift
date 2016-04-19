//
//  GameScene.swift
//  shooter
//
//  Created by ian kunneke on 4/11/16.
//  Copyright (c) 2016 zivit. All rights reserved.

import SpriteKit


////Setting up phyics constants

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Target   : UInt32 = 0b1
    static let Bullet: UInt32 = 0b10
}




///////Functions for moving bullet

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

///////////


///////Creating our game scene

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let shooter = SKSpriteNode(imageNamed: "Shooter")
    var targetDestroyed = 0
    
    
    
    override func didMoveToView(view: SKView) {
        
        
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        
        
        backgroundColor = SKColor.whiteColor()
        shooter.position = CGPoint(x: size.width * 0.05, y: size.height * 0.5)
        
        addChild(shooter)
        
        addTarget()
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(addTarget),
                SKAction.waitForDuration(1.0)
                ])
            ))
        }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addTarget() {
        
        let targets = ["Poly", "Square", "Tri"]
        let randomCatchIndex = Int(arc4random_uniform(UInt32(targets.count)))
        let target = SKSpriteNode(imageNamed: targets[randomCatchIndex])
        
        target.physicsBody = SKPhysicsBody(rectangleOfSize: target.size)
        target.physicsBody?.dynamic = true
        target.physicsBody?.categoryBitMask = PhysicsCategory.Target
        target.physicsBody?.contactTestBitMask = PhysicsCategory.Bullet
        target.physicsBody?.collisionBitMask = PhysicsCategory.None
    
        let actualY = random(min: target.size.height/2, max: size.height - target.size.height/2)
        target.position = CGPoint(x: size.width + target.size.width/2, y: actualY)
        
        addChild(target)
        
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        
        let actionMove = SKAction.moveTo(CGPoint(x: -target.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        target.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
        
        //////Losing the game
        
        let loseAction = SKAction.runBlock() {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        target.runAction(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        
        let touch = touches.first as UITouch?
        let touchLocation = touch!.locationInNode(self)
        let bullet = SKSpriteNode(imageNamed: "Star")
        
        
        
        bullet.position = shooter.position
        
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width/2)
        bullet.physicsBody?.dynamic = true
        bullet.physicsBody?.categoryBitMask = PhysicsCategory.Bullet
        bullet.physicsBody?.contactTestBitMask = PhysicsCategory.Target
        bullet.physicsBody?.collisionBitMask = PhysicsCategory.None
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        
        
        let offset = touchLocation - bullet.position
        
        if (offset.x < 0) { return }
        
        
        addChild(bullet)
        
        
        let direction = offset.normalized()
        
        let shootAmount = direction * 1000
        
        let realDest = shootAmount + bullet.position
        
        let actionMove = SKAction.moveTo(realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        bullet.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    func bulletDidCollideWithTarget(bullet:SKSpriteNode, target:SKSpriteNode) {
        print("Gotcha")
        bullet.removeFromParent()
        target.removeFromParent()
        
        targetDestroyed += 1
        if (targetDestroyed > 30) {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.Target != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Bullet != 0)) {
            bulletDidCollideWithTarget(firstBody.node as! SKSpriteNode, target: secondBody.node as! SKSpriteNode)
        }
        
    }
}
   


