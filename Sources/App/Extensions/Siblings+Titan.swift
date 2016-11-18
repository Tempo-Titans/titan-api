//
//  Siblings+Titan.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 18/11/2016.
//
//

import Vapor
import Fluent

extension Siblings where T: Model {
    func includes(_ item: T) throws -> Bool {
        return try filter("id", item.id!).all().count > 0
    }
}
