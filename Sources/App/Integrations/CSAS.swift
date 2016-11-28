import Vapor
import HTTP



class CSAS {
    weak var drop: BasicClient?
    
    init() {
        self.drop = try! BasicClient(scheme: "https", host: "api.csas.cz/sandbox/webapi/api/v3")
    }
    
    func getAccounts() -> JSON {
        
        guard let apiKey = Env.get("WEB-API-Key") else {
            print("Make sure you set WEB-API-Key")
            return JSON([:])
        }
        
        let registerRequest  = try! Request(method: .get, uri: "/netbanking/my/accounts")
        registerRequest.headers = [ "Content-Type" : "application/json",
                                    "WEB-API-Key" : apiKey,
                                    "Authorization" : "Bearer demo_001"]
        do {
            let response  = try drop?.respond(to: registerRequest)
            print(response?.json)
        } catch let e {
            print(e)
        }
        
        
        return JSON([:])
    }
    
    
}
