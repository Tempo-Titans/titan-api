//
//  GroupController.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 16/11/2016.
//
//

import Vapor
import HTTP
import VaporMySQL
import Turnstile
import Fluent


struct GroupController: ResourceRepresentable {
    
    func addRoutes(drop: Droplet) {
        let apiV1 = drop.grouped("api").grouped("v1").grouped(bearerAuthMiddleware, protectMiddleware, adminMiddleware)
        apiV1.resource("groups", self)
        
        let groupUser = apiV1.grouped("groups", ":id")
        groupUser.put("addusers", handler: addUsers)
    
    }
    
    func addUsers(request: Request) throws -> ResponseRepresentable {
        guard let groupID = request.parameters["id"]?.int else {
            throw Abort.badRequest
        }
        
        if let group = try Group.query().filter("id", groupID.makeNode()).first() {
            for element in (request.json?["users"]?.array)! {
                print(element)
                if let user = try User.query().filter("id", element.int!).first() {
                    if try user.groups().includes(group) {
                        throw Abort.custom(status: .conflict,
                                           message: "User with id:\(user.id!.int!) and name:\(user.firstName + " " + user.lastName) is already in group with id:\(group.id!.int!) and name:\(group.name)")
                    }
                    var pivot = Pivot<User, Group>(user, group)
                    try pivot.save()
                    
                } else {
                    throw Abort.custom(status: .badRequest, message: "Check if all these user ids exists")
                }
            }
         return group
            
        }else {
            throw Abort.custom(status: .badRequest, message: "Group with group_id \(groupID) doestn't exists")
        }
        
        
        
    }
    
    func index(request: Request) throws -> ResponseRepresentable {

        
        return try Group.query().all().toJSON()
    }
    
    func create(request: Request) throws -> ResponseRepresentable {
        var group = try request.group()
        try group.save()
        return group
    }
    
    
    func delete(request: Request, group: Group) throws -> ResponseRepresentable {
        try group.delete()
        return group
    }
    
    func makeResource() -> Resource<Group> {
        return Resource(
            index: index,
            store: create,
            destroy: delete
        )
    }
}

extension Request {
    func group() throws -> Group {
        guard let json = json else { throw Abort.badRequest }
        return try Group(node: json)
    }
}
