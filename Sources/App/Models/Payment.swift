//
//  Payment.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 16/11/2016.
//
//

import Foundation
import Vapor
import Fluent
import HTTP

final class Payment: Model {
    
    var id: Node?
    var amount: Int
    var created = Int(Date().timeIntervalSince1970)
    var userID: Node?
    
    var exists: Bool = false
    
    init(amount: Int, user: User) {
        self.amount = amount
        self.userID = user.id
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        amount = try node.extract("amount")
        userID = try node.extract("user_id")
        
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "amount": amount,
            "user_id": userID
            ])
    }
    
    func makeResponse() throws -> Response {
        let json = try JSON(node: [
            "id": id,
            "amount": amount,
            "user_id": userID
            ])
        
        return try json.makeResponse()
    }
}

extension Payment {
    func merge(updates: Payment) {
        amount = updates.amount
        userID = updates.userID ?? userID
    }
}


extension Payment: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("payments") { payments in
            payments.id()
            payments.int("amount")
            payments.string("user_id")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("payments")
    }
}

extension Payment {
    func user() throws -> Parent<User> {
        return try parent(userID)
    }
}

