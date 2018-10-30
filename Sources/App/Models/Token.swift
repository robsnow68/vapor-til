import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class Token: Codable {
    var id: UUID?
    var token: String
    var userID: User.ID
    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}
extension Token: PostgreSQLUUIDModel {}
extension Token: Migration {
    static func prepare(on connection: PostgreSQLConnection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \.userID, to: \User.id)
            }
    } }
extension Token: Content {}
extension Token {
    // 1
    static func generate(for user: User) throws -> Token {
        // 2
        let random = try CryptoRandom().generateData(count: 16)
        // 3
        return try Token(
            token: random.base64EncodedString(),
            userID: user.requireID())
    }
}
// 1
extension Token: Authentication.Token {
    // 2
    static let userIDKey: UserIDKey = \Token.userID
    // 3
    typealias UserType = User
}
// 4
extension Token: BearerAuthenticatable {
    // 5
    static let tokenKey: TokenKey = \Token.token
}
