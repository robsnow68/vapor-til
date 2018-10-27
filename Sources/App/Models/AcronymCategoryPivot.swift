//
//  AcronymCategoryPivot.swift
//  App
//
//  Created by Rob Snow on 18/10/2018.
//

import FluentPostgreSQL
import Foundation
// 1
final class AcronymCategoryPivot: PostgreSQLUUIDPivot,ModifiablePivot {
// 2
var id: UUID?
// 3
var acronymID: Acronym.ID
var categoryID: Category.ID
// 4
    typealias Left = Acronym
    typealias Right = Category
    // 5
    static let leftIDKey: LeftIDKey = \.acronymID
    static let rightIDKey: RightIDKey = \.categoryID
    // 6
    init(_ acronym: Acronym, _ category: Category) throws {
        self.acronymID = try acronym.requireID()
        self.categoryID = try category.requireID()
    }
}
// 7
// 1
extension AcronymCategoryPivot: Migration {
    // 2
    static func prepare(
        on connection: PostgreSQLConnection
        ) -> Future<Void> {
        // 3
        return Database.create(self, on: connection) { builder in
            // 4
            try addProperties(to: builder)
            // 5
            builder.reference(
                from: \.acronymID,
                to: \Acronym.id,
                onDelete: .cascade)
            // 6
            builder.reference(
                from: \.categoryID,
                to: \Category.id,
                onDelete: .cascade)
        } }
}
