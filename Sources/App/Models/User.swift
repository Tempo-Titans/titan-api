//
//  User.swift
//  timezoner
//
//  Created by Aleš Kocur on 17/10/2016.
//
//

import Vapor
import Fluent
import Foundation
import Auth
import Turnstile
import HTTP
import TurnstileCrypto

final class User: Model {
    
    enum Role: String {
        case admin = "admin"
        case manager = "manager"
        case user = "user"
    }
    
    var id: Node?
    var username: String
    var password: String
    var role: Role = Role.user
    var authorizationToken: String = URandom().secureToken
    
    var exists: Bool = false
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        username = try node.extract("username")
        password = try node.extract("password")
        role = try Role(rawValue: node.extract("role")) ?? .user
        authorizationToken = try node.extract("token")
    }
    
    init(patchJSON: Node) throws {
        username = try patchJSON.extract("username")
        password = try patchJSON.extract("password")
        role = try Role(rawValue: patchJSON.extract("role")) ?? .user
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "username": username,
            "password": password,
            "role": role.rawValue,
            "token": authorizationToken
            ])
    }
    
    func makeResponse() throws -> Response {
        let json = try JSON(node: [
            "id": id,
            "token": authorizationToken,
            "username": username,
            "role": role.rawValue
            ])
        
        return try json.makeResponse()
    }
}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
            users.string("username")
            users.string("password")
            users.string("role")
            users.string("token")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}

extension User: Auth.User {
    
    static func register(credentials: Credentials) throws -> Auth.User {
        switch credentials {
        case let credentials as UsernamePassword:
            
            if try User.query().filter("username", credentials.username).first() != nil {
                throw Abort.custom(status: .conflict, message: "Already registered")
            }
            
            var user = User(username: credentials.username, password: credentials.password)
            try user.save()
            return user
            
        default:
            throw AccountTakenError()
        }
    }
    
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        
        switch credentials {
        case let credentials as UsernamePassword:
            guard let user = try User.query().filter("username", credentials.username).first() else {
                throw Abort.badRequest
            }
            
            if user.password != credentials.password {
                throw Abort.custom(status: .unauthorized, message: "Wrong password")
            }
            
            return user
        case let accessToken as AccessToken:
            if let user = try User.query().filter("token", accessToken.string).first() {
                return user
            } else {
                throw Abort.custom(status: .unauthorized, message: "Invalid token")
            }
        default:
            throw UnsupportedCredentialsError()
        }
    }
}

extension Request {
    func user() throws -> User {
        guard let user = try auth.user() as? User else {
            throw Abort.custom(status: .enhanceYourCalm, message: "Calm down!")
        }
        return user
    }
    func userJSON() throws -> User {
        guard let json = json else { throw Abort.badRequest }
        return try User(patchJSON: json.makeNode())
    }
}

extension User {
    func merge(updates: User) {
        id = updates.id ?? id
        username = updates.username
        password = updates.password
        role = updates.role
    }
}

extension User {
    func payments() throws -> Children<Payment> {
        return children()
        
    }
}
