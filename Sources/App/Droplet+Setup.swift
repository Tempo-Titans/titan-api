//
//  Droplet+Setup.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 15/11/2016.
//
//

import Vapor
import Fluent
import VaporMySQL
import Auth
import Routing
import HTTP
import Foundation
import Turnstile
import TurnstileWeb
import TurnstileCrypto

let protectMiddleware = ProtectMiddleware(error: Abort.custom(status: .unauthorized, message: "Unauthorized"))
let adminMiddleware = RoleMiddleware(accessibleRoles: [.admin])
let bearerAuthMiddleware = BearerAuthenticationMiddleware()

func prepare(_ drop: Droplet) {
    drop.preparations = [User.self,
                         Payment.self,
                         Group.self,
                         Pivot<User, Group>.self]
    
    let auth = AuthMiddleware(user: User.self)
    drop.middleware.append(auth)
    
    let userController = UserController()
    userController.addRoutes(drop: drop)
    
    let groupController = GroupController()
    groupController.addRoutes(drop: drop)
    
    drop.group("api/v1") { v1 in
        v1.get() { request in
            return try JSON(["version":"v1"])
        }
    }
}



func meEndpoinsts(_ drop: Droplet) throws {
    drop.grouped("api").grouped("v1").grouped(BearerAuthenticationMiddleware(), protectMiddleware).group("me") { me in
        me.get() { request in
            return try request.user()
        }
        
        me.patch() { request in
            var user = try request.user()
            
            if user.username != "syky" && user.username != "palmyman" {
                throw Abort.custom(status: .forbidden, message: "Permission denied")
            }
            
            if let roleValue = request.json?["role"]?.string,
                let role = User.Role(rawValue: roleValue) {
                user.role = role
                try user.save()
            }
            
            return user
        }
    }
}


func load(_ drop: Droplet) throws {
    prepare(drop)
    try meEndpoinsts(drop)
}
