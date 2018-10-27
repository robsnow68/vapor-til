import Vapor
// 1
struct UsersController: RouteCollection {
    // 2
    func boot(router: Router) throws {
        // 3
        let usersRoute = router.grouped("api", "users")
        // 4
        usersRoute.post(User.self, use: createHandler)
        //1
        usersRoute.get(use: getAllHandler)
        // 2
        usersRoute.get(User.parameter, use: getHandler)
        
        usersRoute.get(
            User.parameter, "acronyms",
            use: getAcronymsHandler)
    }
    // 5
    func createHandler(
        _ req: Request,
        user: User
        ) throws -> Future<User> {
        // 6
        return user.save(on: req)
    }
    
    // 1
    func getAllHandler(_ req: Request) throws -> Future<[User]> {
        // 2
        return User.query(on: req).all()
    }
    // 3
    func getHandler(_ req: Request) throws -> Future<User> {
        // 4
        return try req.parameters.next(User.self)
    }
    
    // 1
    func getAcronymsHandler(_ req: Request)
        throws -> Future<[Acronym]> {
            // 2
            return try req
                .parameters.next(User.self)
                .flatMap(to: [Acronym].self) { user in
                    // 3
                    try user.acronyms.query(on: req).all()
            }
    }
}
