//
//  V1Collection.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 15/11/2016.
//
//

import Foundation

import Vapor
import HTTP
import Routing

class V1Collection: RouteCollection {
    typealias Wrapped = HTTP.Responder
    
    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
        
        let v1 = builder.grouped("v1")
        let users = v1.grouped("users")
        let roles = v1.grouped("roles")
        
        users.get { request in
            return "Requested all users."
        }
        
        roles.get(Role.self) { request, role in
            return "Requested \(role.roleType)"
        }
    }
}
