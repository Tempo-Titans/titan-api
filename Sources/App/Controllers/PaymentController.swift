//
//  PaymentController.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 16/11/2016.
//
//

import Vapor
import HTTP
import Turnstile


struct PaymentController: ResourceRepresentable {
    
    func index(request: Request) throws -> ResponseRepresentable {
        guard let userId = request.parameters["id"]?.int else {
            throw Abort.badRequest
        }
        
        return try User.query().filter("id", userId).first()?.payments().all().toJSON() ?? JSON([:])
    }
    
    func create(request: Request) throws -> ResponseRepresentable {
        guard let userId = request.parameters["id"]?.int else {
            throw Abort.badRequest
        }
        var payment = try request.payment()
        payment.userID = try userId.makeNode()
        try payment.save()
        return payment
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
            store: create,
            destroy: delete
        )
    }
}

extension Request {
    func payment() throws -> Payment {
        guard let json = json else { throw Abort.badRequest }
        return try Payment(node: json)
    }
}
