
import Vapor
import Fluent
import Authentication

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        
        
       // router.get("api", "acronyms", use: getAllHandler)
        acronymsRoutes.get(use: getAllHandler)
        // 1
        //acronymsRoutes.post(Acronym.self, use: createHandler)
        // 2
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        // 3
      
        // 4
        
        // 5
        acronymsRoutes.get("search", use: searchHandler)
        // 6
        acronymsRoutes.get("first", use: getFirstHandler)
        // 7
        acronymsRoutes.get("sorted", use: sortedHandler)
        
        acronymsRoutes.get(
            Acronym.parameter, "user",
            use: getUserHandler)
        
    
        
        acronymsRoutes.get(
            Acronym.parameter,
            "categories",
            use: getCategoriesHandler)
        
    
        
        // 1
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        // 2
        let tokenAuthGroup = acronymsRoutes.grouped(
            tokenAuthMiddleware,
            guardAuthMiddleware)
        // 3
        tokenAuthGroup.post(AcronymCreateData.self, use: createHandler)
        
        tokenAuthGroup.delete(Acronym.parameter, use: deleteHandler)
        tokenAuthGroup.put(Acronym.parameter, use: updateHandler)
        tokenAuthGroup.post(
            Acronym.parameter,
            "categories",
            Category.parameter,
            use: addCategoriesHandler)
        tokenAuthGroup.delete(
            Acronym.parameter,
            "categories",
            Category.parameter,
            use: removeCategoriesHandler)
        // 4
        //protected.post(Acronym.self, use: createHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    //func createHandler(
    //    _ req: Request,
    //    acronym: Acronym
    //    ) throws -> Future<Acronym> {
    //    return acronym.save(on: req)
    //}
    
    // 1
    func createHandler(
        _ req: Request,
        data: AcronymCreateData) throws -> Future<Acronym> {
        // 2
        let user = try req.requireAuthenticated(User.self)
        // 3
        let acronym = try Acronym(
            short: data.short, long: data.long,
            userID: user.requireID())
        // 4
        return acronym.save(on: req)
    }
    
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
    
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        // 1
        return try flatMap(
            to: Acronym.self,
            req.parameters.next(Acronym.self),
            req.content.decode(AcronymCreateData.self)
        ) { acronym, updateData in
            acronym.short = updateData.short
            acronym.long = updateData.long
            // 2
            let user = try req.requireAuthenticated(User.self)
            acronym.userID = try user.requireID()
            return acronym.save(on: req)
        } }
    
    func deleteHandler(_ req: Request)
        throws -> Future<HTTPStatus> {
            return try req
                .parameters
                .next(Acronym.self)
                .delete(on: req)
                .transform(to: HTTPStatus.noContent)
    }
    
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req
            .query[String.self, at: "term"] else {
                throw Abort(.badRequest)
        }
        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
            }.all() }
    
    func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym.query(on: req)
            .first()
            .map(to: Acronym.self) { acronym in
                guard let acronym = acronym else {
                    throw Abort(.notFound)
                }
                return acronym
        }
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).sort(\.short, .ascending).all()
    }
    
    // 1
    func getUserHandler(_ req: Request) throws -> Future<User.Public> {
        // 2
        return try req
            .parameters.next(Acronym.self)
            .flatMap(to: User.Public.self) { acronym in
                // 3
                acronym.user.get(on: req).convertToPublic()
        }
    }
    
    // 1
    func addCategoriesHandler(
        _ req: Request
        ) throws -> Future<HTTPStatus> {
        // 2
        return try flatMap(
            to: HTTPStatus.self,
            req.parameters.next(Acronym.self),
            req.parameters.next(Category.self)) { acronym, category in
                // 3
                return acronym.categories
                    .attach(category, on: req)
                    .transform(to: .created)
        }
    }
    
    // 1
    func getCategoriesHandler(
        _ req: Request
        ) throws -> Future<[Category]> {
        // 2
        return try req.parameters.next(Acronym.self)
            .flatMap(to: [Category].self) { acronym in
                // 3
                try acronym.categories.query(on: req).all()
        }
    }
    
    // 1
    func removeCategoriesHandler(
        _ req: Request) throws -> Future<HTTPStatus> {
        // 2
        return try flatMap(
            to: HTTPStatus.self,
            req.parameters.next(Acronym.self),
            req.parameters.next(Category.self)
        ) { acronym, category in
            //3
            return acronym.categories
                .detach(category, on: req)
                .transform(to: .noContent)
        }
    }
}

struct AcronymCreateData: Content {
    let short: String
    let long: String
}
