//
//  UserController.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 14/11/2016.
//
//

import Vapor
import HTTP
import Turnstile
import Fluent

struct UserController: ResourceRepresentable {
    
    func addRoutes(drop: Droplet) {
        let apiV1 = drop.grouped("api").grouped("v1").grouped("users")
        apiV1.post("register", handler: register)
        apiV1.post("login", handler: login)
        
        let apiV1Protected = drop.grouped("api").grouped("v1").grouped(BearerAuthenticationMiddleware(),protectMiddleware, adminMiddleware)
        /// REST
        apiV1Protected.resource("users", self)
        /// Balance
        let userActions =  apiV1Protected.grouped("users", ":id")
        userActions.get("balance", handler: balance)
        userActions.get("groups", handler: groups)
        userActions.put("addgroups", handler: addGroups)
        userActions.put("setgroups", handler: setGroups)
        
        /// Payments
        userActions.resource("payments", PaymentController())
        
        
        
    }
    
    func setGroups(request: Request) throws -> ResponseRepresentable {
        guard let userId = request.parameters["id"]?.int else {
            throw Abort.badRequest
        }
        
        if let user = try User.find(userId) {
            try Pivot<User, Group>.query().filter("user_id", user.id!).delete()
            return try addGroups(request: request)
        }
        
        throw Abort.custom(status: .notFound, message: "User with id:\(userId) doesn't exists")
    }
    
    func addGroups(request: Request) throws -> ResponseRepresentable {
        guard let userId = request.parameters["id"]?.int else {
            throw Abort.badRequest
        }
        
        if let user = try User.find(userId){
            if let groups = request.json?["groups"]?.array {
                for element in groups {
                    if let group = try Group.find(element.int!) {
                        if try user.groups().includes(group) {
                            throw Abort.custom(status: .conflict, message: "Groups with id:\(group.id!.int!) already constains user with id:\(user.id!.int!)")
                        }
                        
                        var pivot = Pivot<User, Group>(user, group)
                        try pivot.save()
                        
                        
                        
                    } else {
                        throw Abort.custom(status: .notFound, message: "group_id: \(element.int!)")
                    }
                }
                return user
            } else {
                throw Abort.custom(status: .badRequest, message: "Request needs to contain 'groups' key")
            }
        
        }
        
        throw Abort.custom(status: .notFound, message: "User doesn't exists")
    }
    
    func groups(request: Request) throws -> ResponseRepresentable {
        guard let userId = request.parameters["id"]?.int else {
            throw Abort.badRequest
        }
        
        return try User.query().filter("id", userId.makeNode()).first()?.groups().all().toJSON() ?? JSON([:])
    }
    
    func balance(request: Request) throws -> ResponseRepresentable {
        guard let userId = request.parameters["id"]?.int else {
            throw Abort.badRequest
        }
        
        return try User.query().filter("id", userId.makeNode()).all().first!.balance()
    }
    
    func register(request: Request) throws -> ResponseRepresentable {
        guard let username = request.data["username"]?.string,
                let password = request.data["password"]?.string,
                let firstName = request.data["first_name"]?.string,
                let lastName = request.data["last_name"]?.string,
                let birthID = request.data["birth_id"]?.string else {
                throw Abort.custom(status: .badRequest,
                                   message: "Missing credentials, Mandatory field: username, password, first_name, last_name, birth_id")
        }
        
        let credentials = TitanUserCredentials(username: username,
                                               password: password,
                                               firstName: firstName,
                                               lastName: lastName,
                                               birthID: birthID)
        
        let authuser = try User.register(credentials: credentials)
        try request.auth.login(credentials)
        
        guard var user = authuser as? User else {
            throw Abort.serverError
        }
        
        try user.save()
        return user
    }
    
    func login(request: Request) throws -> ResponseRepresentable {
        guard let username = request.data["username"]?.string,
                let password = request.data["password"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Missing credentials")
        }
        
        let credentials = UsernamePassword(username: username, password: password)
        try request.auth.login(credentials)
        
        guard let user = try request.auth.user() as? User else {
            throw Abort.serverError
        }
        
        return user
    }
    
    func index(request: Request) throws -> ResponseRepresentable {
        return try User.all().toJSON()
    }
    
    func update(request: Request, user: User) throws -> ResponseRepresentable {
        do {
            let new = try request.userJSON()
            var user = user
            user.merge(updates: new)
            try user.save()
            return user
        } catch let e {
            throw Abort.custom(status: .badRequest, message: "You fucked up => \(e.localizedDescription)")
        }
    }
    

    func delete(request: Request, user: User) throws -> ResponseRepresentable {
        try user.delete()
        return user
    }
    
    
    
    func makeResource() -> Resource<User> {
        return Resource(
            index: index,
            modify: update,
            destroy: delete
            
        )
    }
}


