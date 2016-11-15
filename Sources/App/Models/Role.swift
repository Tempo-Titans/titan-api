//
//  Role.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 15/11/2016.
//
//

import Vapor
import Fluent

enum RoleType: String {
    case aministrator = "administrator"
    case boardMember = "boardMember"
    case member = "member"
    case player = "player"
    case guest = "guest"
    case notDefined = "n/a"
    
    
    static func from(str: String) -> RoleType {
        switch str {
        case "administrator":
            return .aministrator
            
        case "boardMember":
            return .boardMember
            
        case "member":
            return .member

        case "player":
            return .player
            
        case "guest":
            return .guest
            
        default:
            return .notDefined
            
        }
    }
}

final class Role: BaseModel, Model {
    var roleType: String
    
    init(roleType: RoleType){
        self.roleType = roleType.rawValue
        super.init()
    }
    
    class func exists(roleType: RoleType) -> Role? {
        var role: Role
        do {
            if let fetch = try Role.query().filter("roleType", roleType.rawValue).first() {
                return fetch
            } else {
                role = Role(roleType: roleType)
                try role.save()
                return role
            }
        } catch let e {
            print("Could not create role \(e)")
        }
        return nil
        
    }
    
    override init(node: Node, in context: Context) throws {
        roleType = try RoleType.from(str: node.extract("username")).rawValue
        try super.init(node: node, in: context)
    }
    
    override func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "created_on": createdOn,
            "roleType": roleType
            ])
    }
    
}

extension Role: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("roles") { role in
            prepare(model: role)
            role.string("roleType")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("roles")
    }
}

extension Role {
    func users() throws -> Siblings<User> {
        return try siblings()
    }
}
