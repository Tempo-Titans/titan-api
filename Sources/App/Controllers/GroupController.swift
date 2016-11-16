//
//  GroupController.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 16/11/2016.
//
//

import Vapor
import HTTP
import Turnstile


struct GroupController: ResourceRepresentable {
    
    func index(request: Request) throws -> ResponseRepresentable {
//        guard let userId = request.parameters["id"]?.int else {
//            throw Abort.badRequest
//        }
        
        return try Group.query().all().toJSON()
        //        return try User.query().filter("id", userId).first()?.payments().all().toJSON() ?? JSON([:])
    }
    
    func create(request: Request) throws -> ResponseRepresentable {
//        guard let userId = request.parameters["id"]?.int else {
//            throw Abort.badRequest
//        }

        var group = try request.group()
        try group.save()
        return group
    }
    
    func delete(request: Request, group: Group) throws -> ResponseRepresentable {
        try group.delete()
        return group
    }
    
    func makeResource() -> Resource<User> {
        return Resource(
            index: index,
            store: create
        )
    }
}

extension Request {
    func group() throws -> Group {
        guard let json = json else { throw Abort.badRequest }
        return try Group(node: json)
    }
}
