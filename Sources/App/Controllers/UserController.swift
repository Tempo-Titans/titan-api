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
    
    func update(request: Request, task: User) throws -> ResponseRepresentable {
        let new = try request.userJSON()
        var task = task
        task.merge(updates: new)
        try task.save()
        return task
    }
    
    func patchRole(request: Request, userToPatch: User) throws -> ResponseRepresentable {
        if let roleType = request.json?["role"]?.string,
            let role = User.Role(rawValue: roleType) {
            var userToPatch = userToPatch
            userToPatch.role = role
            try userToPatch.save()
            return userToPatch
        }
        
        
        
        
        return Abort.badRequest as! ResponseRepresentable
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
