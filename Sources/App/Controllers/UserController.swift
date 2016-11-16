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


struct UserController: ResourceRepresentable {
    
    func index(request: Request) throws -> ResponseRepresentable {
        guard let userId = request.parameters["id"]?.int else {
            throw Abort.badRequest
        }

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
