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

func prepare(_ drop: Droplet) {
    drop.preparations = [User.self,
                         Payment.self]
    
    let auth = AuthMiddleware(user: User.self)
    drop.middleware.append(auth)
}

func loginRegister(_ drop: Droplet) throws {
    drop.grouped("api")
        .grouped("v1")
        .group("users") { users in
            
            users.post("register") { request in
                guard let username = request.data["username"]?.string, let password = request.data["password"]?.string else {
                    throw Abort.custom(status: .badRequest, message: "Missing credentials")
                }
                
                let credentials = UsernamePassword(username: username, password: password)
                
                let authuser = try User.register(credentials: credentials)
                try request.auth.login(credentials)
                
                guard var user = authuser as? User else {
                    throw Abort.serverError
                }
                
                try user.save()
                
                return user
            }
            
            users.post("login") { request in
                guard let username = request.data["username"]?.string, let password = request.data["password"]?.string else {
                    throw Abort.custom(status: .badRequest, message: "Missing credentials")
                }
                
                let credentials = UsernamePassword(username: username, password: password)
                try request.auth.login(credentials)
                
                guard let user = try request.auth.user() as? User else {
                    throw Abort.serverError
                }
                
                return user
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

func userCRUD(_ drop: Droplet) throws {
    drop.grouped("api")
        .grouped("v1")
        .grouped(BearerAuthenticationMiddleware(), protectMiddleware, adminMiddleware)
        .resource("users", UserController())
}


func userPaymentCRUD(_ drop: Droplet) throws {
    drop.grouped("api")
        .grouped("v1")
        .grouped(BearerAuthenticationMiddleware(), protectMiddleware, adminMiddleware)
        .group("users", ":id") { users in
            users.get("balance") { request in
                guard let userId = request.parameters["id"]?.int else {
                    throw Abort.badRequest
                }
                
                return try User.query().filter("id", userId.makeNode()).all().first!.balance()
            }
    }
}

func paymentCRUD(_ drop: Droplet) throws {
    drop.grouped("api")
        .grouped("v1")
        .grouped("users", ":id")
        .resource("payments", PaymentController())
}

func load(_ drop: Droplet) throws {
    prepare(drop)
    try loginRegister(drop)
    try meEndpoinsts(drop)
    try userCRUD(drop)
    try userPaymentCRUD(drop)
    try paymentCRUD(drop)
}
