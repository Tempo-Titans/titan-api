import Vapor
import Fluent
import VaporMySQL
import Auth
import Routing
import HTTP
import Foundation
import Turnstile
import TurnstileWeb
import TurnstileCrypto

let drop = Droplet()

try drop.addProvider(VaporMySQL.Provider.self)

drop.addConfigurable(middleware: AuthMiddleware(user: User.self), name: "auth")

drop.preparations = [
    User.self,
]

let authenticate = ProtectMiddleware(error:
    Abort.custom(status: .forbidden, message: "Not authorized.")
)

let userController = UserController()

let api: RouteGroup  = drop.grouped("api")
let v1: RouteGroup = api.grouped("v1")
let authenticated: RouteGroup = v1.grouped(authenticate)

api.get { req in try JSON(node: ["Welcome to the Titan API"]) }

api.get("versions") { request in
    try JSON(node: ["versions" : ["v1"]])
}

v1.get { req in try JSON(node: ["version": "1"]) }

// /users
authenticated.resource("users", userController)

v1.post("register") { request in
    guard let username = request.json?["username"]?.string,
        let password = request.json?["password"]?.string else {
            throw Abort.custom(status: Status.badRequest, message: "You need to provide username and password, in order to register")
    }
    
    let credentials = UsernamePassword(username: username, password: password)
    
    do {
        let user = try User.register(credentials: credentials)
        return try JSON(node: user.makeNode())
    } catch let e as TurnstileError {
        return try JSON(node: ["Exception raised": e.description])
    }
    
}

v1.post("login") { request in
    guard let username = request.json?["username"]?.string,
        let password = request.json?["password"]?.string else {
            throw Abort.custom(status: Status.badRequest, message: "You need to provide username and password, in order to login")
    }
    
    let credentials = UsernamePassword(username: username, password: password)
    
    do {
        let user = try User.authenticate(credentials: credentials)
        return try JSON(node: user.makeNode())
    } catch let e as TurnstileError {
        return try JSON(node: ["Exception raised": e.description])
    }
    
}




drop.run()
