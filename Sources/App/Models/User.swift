import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    var password: String
    
    init(name: String, username: String, password: String) {
        self.name = name
        self.username = username
        self.password = password
    }
    final class Public: Codable {
        var id: UUID?
        var name: String
        var username: String
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        } }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {
    static func prepare(on connection: PostgreSQLConnection)
        -> Future<Void> {
            // 1
            return Database.create(self, on: connection) { builder in
                // 2
                try addProperties(to: builder)
                // 3
                builder.unique(on: \.username)
            } }
}
extension User: Parameter {}
extension User.Public: Content {}
extension User {
    // 1
    var acronyms: Children<User, Acronym> {
        // 2
        return children(\.userID)
    }
}
extension User {
    // 1
    func convertToPublic() -> User.Public {
        // 2
        return User.Public(id: id, name: name, username: username)
    }
}
// 1
extension Future where T: User {
    // 2
    func convertToPublic() -> Future<User.Public> {
        // 3
        return self.map(to: User.Public.self) { user in
            // 4
            return user.convertToPublic()
        }
    } }

// 1
extension User: BasicAuthenticatable {
    // 2
    static let usernameKey: UsernameKey = \User.username
    // 3
    static let passwordKey: PasswordKey = \User.password
}

// 1
extension User: TokenAuthenticatable {
    // 2
    typealias TokenType = Token
}

// 1
struct AdminUser: Migration {
    // 2
    typealias Database = PostgreSQLDatabase
    // 3
    static func prepare(on connection: PostgreSQLConnection)
        -> Future<Void> {
            // 4
            let password = try? BCrypt.hash("password")
            guard let hashedPassword = password else {
                fatalError("Failed to create admin user")
            }
            // 5
            let user = User(
                name: "Admin",
                username: "admin",
                password: hashedPassword)
            // 6
            return user.save(on: connection).transform(to: ())
    }
    // 7
    static func revert(on connection: PostgreSQLConnection)
        -> Future<Void> {
            return .done(on: connection)
    }
}

