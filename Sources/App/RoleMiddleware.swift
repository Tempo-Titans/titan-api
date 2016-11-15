//
//  RoleMiddleware.swift
//  timezoner
//
//  Created by Aleš Kocur on 23/10/2016.
//
//

import Vapor
import HTTP

class RoleMiddleware: Middleware {
    var accessibleRoles: [User.Role] = []
    
    init(accessibleRoles: [User.Role]) {
        self.accessibleRoles = accessibleRoles
    }
    
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        
        let user = try request.user()
        
        if !accessibleRoles.contains(user.role) {
            throw Abort.custom(status: .forbidden, message: "You don't have permissions")
        }
        
        return try next.respond(to: request)
    }
}
