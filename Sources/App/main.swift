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
drop.preparations = [User.self]

let auth = AuthMiddleware(user: User.self)
drop.middleware.append(auth)

drop.group("users") { users in
    
    users.post("register") { request in
        guard let username = request.data["username"]?.string, let password = request.data["password"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Missing credentials")
        }
        
        let credentials = UsernamePassword(username: username, password: password)
        
        let authuser = try User.register(credentials: credentials)
        try request.auth.login(credentials)
        
        guard var user = authuser as? User else {
            throw Abort.serverError
        }
        
        try user.save()
        
        return user
    }
    
    users.post("login") { request in
        guard let username = request.data["username"]?.string, let password = request.data["password"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Missing credentials")
        }
        
        let credentials = UsernamePassword(username: username, password: password)
        try request.auth.login(credentials)
        
        guard let user = try request.auth.user() as? User else {
            throw Abort.serverError
        }
        
        return user
    }
}

let protectMiddleware = ProtectMiddleware(error: Abort.custom(status: .unauthorized, message: "Unauthorized"))

drop.grouped(BearerAuthenticationMiddleware(), protectMiddleware).group("me") { me in
    me.get() { request in
        return try request.user()
    }
    
    me.patch() { request in
        var user = try request.user()
        
        if user.username != "syky" || user.username != "palmyman" {
            return Abort.custom(status: .forbidden, message: "Permission denied") 
        }
        
        if let roleValue = request.json?["role"]?.string,
            let role = User.Role(rawValue: roleValue) {
            user.role = role
            try user.save()
        }
        
        return user
    }
}

let managerMiddleware = RoleMiddleware(accessibleRoles: [.manager])
let adminMiddleware = RoleMiddleware(accessibleRoles: [.admin])

let userController = UserController()



drop.grouped(BearerAuthenticationMiddleware(), protectMiddleware, adminMiddleware).resource("users", UserController())

//drop.grouped(BearerAuthenticationMiddleware(), protectMiddleware, adminMiddleware).group("users") {users in
//    users.get { response in
//        try userController.index(request: response)
//    }
//    users.patch()
//
//}

drop.run()
