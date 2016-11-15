//
//  BearerAuthenticationMiddleware.swift
//  timezoner
//
//  Created by Aleš Kocur on 18/10/2016.
//
//

import Foundation
import Vapor
import HTTP
import Turnstile

class BearerAuthenticationMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        if let apiKey = request.auth.header?.bearer {
            try? request.auth.login(apiKey)
        }
        return try next.respond(to: request)
    }
}
