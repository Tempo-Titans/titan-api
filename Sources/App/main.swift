import Vapor
import VaporMySQL

let drop = Droplet()
try load(drop)
try drop.addProvider(VaporMySQL.Provider.self)
drop.run()
