// 1
import FluentPostgreSQL
import Vapor
import Leaf
import Authentication

public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
    ) throws { // 2
    
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)
    
    try services.register(LeafProvider())
    try services.register(AuthenticationProvider())
    
    try services.register(FluentPostgreSQLProvider())
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    var middlewares = MiddlewareConfig()
    middlewares.use(ErrorMiddleware.self)
    middlewares.use(FileMiddleware.self)
    middlewares.use(SessionsMiddleware.self)
    services.register(middlewares)
    // Configure a database
    // 1
    var databases = DatabasesConfig()
    // 2
  //  let hostname = Environment.get("DATABASE_HOSTNAME")
    //    ?? "localhost"
    //let username = Environment.get("DATABASE_USER") ?? "vapor"
    //let databaseName = Environment.get("DATABASE_DB") ?? "vapor"
   
    
    
    //let password = Environment.get("DATABASE_PASSWORD")
    //    ?? "password"
    //let databasePort = 5433
    // 3
   //let databaseConfig = PostgreSQLDatabaseConfig(
   //     hostname: hostname,
   //     port: databasePort,
   //     username: username,
   //     database: databaseName,
   //     password: password)

    // 4
    let databaseConfig: PostgreSQLDatabaseConfig
    if let url = Environment.get("DATABASE_URL") {
        guard let urlConfig = PostgreSQLDatabaseConfig(url: url) else {
            fatalError("Failed to create PostgresConfig")
        }
        databaseConfig = urlConfig
    } else {
        let databaseName: String
        let databasePort: Int
        if (env == .testing) {
            databaseName = "vapor-test"
            if let testPort = Environment.get("DATABASE_PORT") {
                databasePort = Int(testPort) ?? 5433
            } else {
                databasePort = 5433
            }
        }
        else {
            databaseName = Environment.get("DATABASE_DB") ?? "vapor"
            databasePort = 5432
        }
        
        let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
        let username = Environment.get("DATABASE_USER") ?? "vapor"
        let password = Environment.get("DATABASE_PASSWORD") ?? "password"
        databaseConfig = PostgreSQLDatabaseConfig(hostname: hostname, port: databasePort, username: username, database: databaseName, password: password)
    }
    let database = PostgreSQLDatabase(config: databaseConfig)
    
    // 5
    databases.add(database: database, as: .psql)
    // 6
    services.register(databases)
    
    
    var migrations = MigrationConfig()
    // 4
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Acronym.self, database: .psql)
    migrations.add(model: Category.self, database: .psql)
    migrations.add(
        model: AcronymCategoryPivot.self,
        database: .psql)
    
    migrations.add(model: Token.self, database: .psql)
    migrations.add(migration: AdminUser.self, database: .psql)
    services.register(migrations)
    
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}

