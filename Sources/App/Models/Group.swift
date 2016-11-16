//
//  Category.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 16/11/2016.
//
//
import Vapor
import Fluent
import Foundation


final class Group: Model {
    var id: Node?
    var name: String
    var description: String?
    var exists: Bool = false
    
    init(name: String, description: String? = nil) {
        self.name = name
        self.description = description
//        super.init()
    }
    
    required init(node: Node, in context: Context) throws {
        name = try node.extract("name")
        description = try node.extract("description")
//        try super.init(node: node, in: context)
    }
    
     func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
//            "created_on": createdOn,
            "name": name,
            "description": description
            ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create("groups") { group in
//            prepare(model: group)
            group.id()
            group.string("name")
            group.string("description", optional: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("groups")
    }
}

// MARK: Merge

extension Group {
    func merge(updates: Group) {
//        super.merge(updates: updates)
        name = updates.name
        description = updates.description ?? description
    }
}

// MARK: Relationships

extension Group {
    func players() throws -> Siblings<User> {
        return try siblings()
    }
}
