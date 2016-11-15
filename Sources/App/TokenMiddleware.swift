//
//  TokenAuthentication.swift
//  titan
//
//  Created by Tomas Sykora, jr. on 15/11/2016.
//
//


import Vapor
import HTTP
import Turnstile


class TokenMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        if let accessToken = request.auth.header?.bearer {
            try? request.auth.login(accessToken)
        }
        
        return try next.respond(to: request)
    }
}
