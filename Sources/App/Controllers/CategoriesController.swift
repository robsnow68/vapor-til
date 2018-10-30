import Vapor
// 1
struct CategoriesController: RouteCollection {
    // 2
    func boot(router: Router) throws {
        // 3
        let categoriesRoute = router.grouped("api", "categories")
        // 4
        
        categoriesRoute.get(use: getAllHandler)
        categoriesRoute.get(Category.parameter, use: getHandler)
        categoriesRoute.get(
            Category.parameter,
            "acronyms",
            use: getAcronymsHandler)
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = categoriesRoute.grouped(
            tokenAuthMiddleware,
            guardAuthMiddleware)
        tokenAuthGroup.post(Category.self, use: createHandler)
    }
    // 5
    func createHandler(
        _ req: Request,
        category: Category
        ) throws -> Future<Category> {
        // 6
        return category.save(on: req)
    }
    // 7
    func getAllHandler(
        _ req: Request
        ) throws -> Future<[Category]> {
        // 8
        return Category.query(on: req).all()
    }
    // 9
    func getHandler(_ req: Request) throws -> Future<Category> {
        // 10
        return try req.parameters.next(Category.self)
    }
    
    // 1
    func getAcronymsHandler(
        _ req: Request) throws -> Future<[Acronym]> {
        // 2
        return try req.parameters.next(Category.self)
            .flatMap(to: [Acronym].self) { category in
                // 3
                try category.acronyms.query(on: req).all()
        }
    }
}
