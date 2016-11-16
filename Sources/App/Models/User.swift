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

public class TitanUserCredentials: Credentials {
    /// Username or email address
    public let username: String
    
    /// Password (unhashed)
    public let password: String
    
    /// The rest of mandatory properties
    public let firstName: String
    public let lastName: String
    public let birthID: String
    
    /// Initializer for PasswordCredentials
    public init(username: String, password: String, firstName: String, lastName: String, birthID: String) {
        self.username = username
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
        self.birthID = birthID
    }
}



final class User: Model {
    
    enum Role: String {
        case admin = "admin"
        case manager = "manager"
        case user = "user"
    }
    
    enum Gender: String {
        case male = "male"
        case female = "female"
        case unisex = "unisex"
        case notDefined = "notDefined"
    }
    
    var id: Node?
    var firstName: String
    var lastName: String
    var birthID: String
    var username: String
    var password: String
    
    var role: Role = Role.user
    var authorizationToken: String = URandom().secureToken
    
    var gender: Gender?
    var email: String?
    var cellNumber: String?
    var middleName: String?
    
    var exists: Bool = false
    
    init(username: String,
         password: String,
         firstName: String,
         lastName: String,
         birthID: String) {
        self.username = username
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
        self.birthID = birthID
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        username = try node.extract("username")
        password = try node.extract("password")
        role = try Role(rawValue: node.extract("role")) ?? .user
        firstName = try node.extract("first_name")
        lastName = try node.extract("last_name")
        birthID = try node.extract("birth_id")
        
        do {
            gender = try Gender(rawValue: node.extract("gender"))
            middleName = try node.extract("middle_name")
            email = try node.extract("email")
            cellNumber = try node.extract("cell_number")
        
        } catch let e  {
            print(e)
        }
        
        
        authorizationToken = try node.extract("token")
    }
    
    init(patchJSON: Node) throws {
        
        username = try patchJSON.extract("username")
        password = try patchJSON.extract("password")
        role = try Role(rawValue: patchJSON.extract("role")) ?? .user
        firstName = try patchJSON.extract("first_name")
        lastName = try patchJSON.extract("last_name")
        birthID = try patchJSON.extract("birth_id")
        
        do {
            gender = try Gender(rawValue: patchJSON.extract("gender"))
            middleName = try patchJSON.extract("middle_name")
            email = try patchJSON.extract("email")
            cellNumber = try patchJSON.extract("cell_number")
        } catch let e  {
            print(e)
        }
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "username": username,
            "password": password,
            "role": role.rawValue,
            "token": authorizationToken,
            
            "first_name": firstName,
            "last_name": lastName,
            "birth_id": birthID,
            
            "gender": gender?.rawValue,
            "middle_name": middleName,
            "email": email,
            "cell_number": cellNumber
            ])
    }
    
    func makeResponse() throws -> Response {
        let json = try JSON(node: [
            "id": id,
            "token": authorizationToken,
            "username": username,
            "role": role.rawValue,
            "first_name": firstName,
            "last_name": lastName,
            "birth_id": birthID,
            
            "gender": gender?.rawValue,
            "middle_name": middleName,
            "email": email,
            "cell_number": cellNumber
            
            
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
            users.string("first_name")
            users.string("last_name")
            users.string("birth_id")
            
            
            users.string("gender", optional: true)
            users.string("middle_name", optional: true)
            users.string("email", optional: true)
            users.string("cell_number", optional: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}

extension User: Auth.User {
    
    static func register(credentials: Credentials) throws -> Auth.User {
        switch credentials {
        case let credentials as TitanUserCredentials:
            
            if try User.query().filter("username", credentials.username).first() != nil {
                throw Abort.custom(status: .conflict, message: "Already registered")
            }
            
            var user = User(username: credentials.username,
                            password: credentials.password,
                            firstName: credentials.firstName,
                            lastName: credentials.lastName,
                            birthID: credentials.birthID)
            try user.save()
            return user
            
        default:
            throw AccountTakenError()
        }
    }
    
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        
        switch credentials {
        case let credentials as TitanUserCredentials:
            guard let user = try User.query().filter("username", credentials.username).first() else {
                throw Abort.badRequest
            }
            
            if user.password != credentials.password {
                throw Abort.custom(status: .unauthorized, message: "Wrong password")
            }
            
            return user
        
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
        firstName = updates.firstName
        lastName = updates.lastName
        birthID = updates.birthID
        
        email = updates.email ?? email
        middleName = updates.middleName ?? middleName
        cellNumber = updates.cellNumber ?? cellNumber
        gender = updates.gender ?? gender
    }
}

// MARK: - Relations

extension User {
    func payments() throws -> Children<Payment> {
        return children()
    }
    
    func groups() throws -> Siblings<Group> {
        return try siblings()
    }
    
    func balance() throws -> ResponseRepresentable {
        var balance = 0
        for payment in try payments().all() {
            balance += payment.amount
        }
        
        return try JSON(["balance": balance.makeNode()])
    }
}


