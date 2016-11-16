//
//  BaseModel.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 16/11/2016.
//
//

import Vapor
import Fluent
import Foundation


class BaseModel {
    var id: Node?
    var exists: Bool = false
    
    var createdOn: String
    
    init() {
        createdOn = ""
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        createdOn = try node.extract("created_on")
    }
    
    func makeNode(context: Context) throws -> Node {
        fatalError("Needs to overidden!")
    }
    
    func merge(updates: BaseModel) {
        id = updates.id ?? id
        createdOn = updates.createdOn
    }
    
    static func prepare(model: Schema.Creator) {
        model.id()
        model.string("created_on")
    }
}


extension BaseModel: Equatable {
    
    static func ==(lhs: BaseModel, rhs: BaseModel) -> Bool {
        return type(of: lhs) == type(of: rhs) && lhs.id == rhs.id
    }
}
