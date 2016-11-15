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
            print(e)
            return JSON(["error": "You fucked up"])
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
