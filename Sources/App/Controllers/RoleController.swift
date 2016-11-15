//
//  RoleController.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 15/11/2016.
//
//

import Vapor
import HTTP
import Turnstile


struct RoleController: ResourceRepresentable {
    
    func index(request: Request) throws -> ResponseRepresentable {
        return try Role.all().toJSON()
    }
    
    func makeResource() -> Resource<User> {
        return Resource(
            index: index,
            store: nil,
            show: nil,
            modify: nil,
            destroy: nil
        )
    }
}
