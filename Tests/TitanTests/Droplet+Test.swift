
@testable import Vapor
@testable import Fluent
@testable import HTTP
//import Turnstile

import XCTest



class TitanTests: XCTestCase {
    let drop = Droplet(arguments: ["dummy/path", "prepare"])
    var token: String = ""
    
    override func setUp() {
        drop.database = Database(MemoryDriver())
        try! load(drop)
        try! drop.runCommands()
        
        testRegisterUser()
        
        super.setUp()
    }
    
    func testRegisterUser() {
        let registerRequest  = try! Request(method: .post, uri: "/api/v1/users/register")
        registerRequest.headers = ["Content-Type" : "application/json"]
        registerRequest.body = JSON(["username" : "syky",
                                     "password" : "password"]).makeBody()
        
        let registerResponse = try! drop.respond(to: registerRequest)
        XCTAssertNotNil(registerResponse.json)
        
        if let token = registerResponse.json?["token"]?.string {
            self.token = token
        }
    }
    
    func testGetUsers() throws {
        try patchSykyToAdmin()
        let usersRequest  = try Request(method: .get, uri: "/api/v1/users")
        usersRequest.headers = ["Content-Type" : "application/json",
                                "Authorization": "Bearer \(token)"]
        
        let userResponse = try drop.respond(to: usersRequest)
        XCTAssertNotNil(userResponse.json)
        
        XCTAssertEqual(200, userResponse.status.hashValue)
    }
    
    func testDeleteUser() throws {
        try patchSykyToAdmin()
        
        let userToDeleteID = try registerUser(username: "fekal", password: "fekal")
        
        let deleteReq = try Request(method: .delete, uri: "/api/v1/users/\(userToDeleteID)")
        deleteReq.headers = ["Content-Type" : "application/json",
                             "Authorization": "Bearer \(token)"]
        
        let userResponse = try drop.respond(to: deleteReq)
        XCTAssertEqual(200, userResponse.status.hashValue)
        
        let getDeleted = try Request(method: .get, uri: "/api/v1/users/\(userToDeleteID)")
        getDeleted.headers = ["Content-Type" : "application/json",
                             "Authorization": "Bearer \(token)"]
        
        let getDeletedRes = try drop.respond(to: getDeleted)
        XCTAssertEqual(404, getDeletedRes.status.hashValue)
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
}

extension TitanTests {
    func registerUser(username: String, password: String) throws -> Int{
        let registerReq  = try! Request(method: .post, uri: "/api/v1/users/register")
        registerReq.headers = ["Content-Type" : "application/json"]
        registerReq.body = JSON(["username" : username.makeNode(),
                                 "password" : password.makeNode()]).makeBody()
        
        let registerRes = try! drop.respond(to: registerReq)
        XCTAssertEqual(200, registerRes.status.hashValue)
        XCTAssertNotNil(registerRes.json)
        if let id = registerRes.json?["id"]?.int {
            return id
        }
        
        XCTFail()
        return 0
    }
    
    func patchSykyToAdmin() throws {
        let role = "admin"
        let patchReq = try Request(method: .patch, uri: "/api/v1/me")
        patchReq.headers = ["Content-Type" : "application/json",
                            "Authorization": "Bearer \(token)"]
        patchReq.body = JSON(["role" : role.makeNode()]).makeBody()
        
        let patchRes = try drop.respond(to: patchReq)
        print(patchRes)
        XCTAssertEqual(200, patchRes.status.hashValue)
        XCTAssertEqual(role, patchRes.json?["role"]?.string)
        
        
    }
}
