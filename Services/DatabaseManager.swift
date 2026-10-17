import Foundation
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()
    let dbQueue: DatabaseQueue

    private init() {
        let url = try! FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("waiterbolt.sqlite")
        dbQueue = try! DatabaseQueue(path: url.path)
        try! migrator.migrate(dbQueue)
    }

    private var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1") { db in
            try db.create(table: "menuItems") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("itemDescription", .text).notNull().defaults(to: "")
                t.column("price", .double).notNull()
                t.column("imageName", .text)
                t.column("weight", .text)
                t.column("categoryRaw", .text).notNull()
                t.column("isAvailable", .boolean).notNull().defaults(to: true)
                t.column("isHit", .boolean).notNull().defaults(to: false)
                t.column("isNewItem", .boolean).notNull().defaults(to: false)
                t.column("modifiers", .text).notNull().defaults(to: "[]")
                t.column("popularity", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull()
            }
            try db.create(table: "orders") { t in
                t.column("id", .text).primaryKey()
                t.column("tableNumber", .integer).notNull()
                t.column("guestName", .text)
                t.column("items", .text).notNull().defaults(to: "[]")
                t.column("statusRaw", .text).notNull()
                t.column("notes", .text).notNull().defaults(to: "")
                t.column("createdAt", .datetime).notNull()
                t.column("closedAt", .datetime)
                t.column("splitCount", .integer).notNull().defaults(to: 1)
            }
            try db.create(table: "tables") { t in
                t.column("id", .text).primaryKey()
                t.column("number", .integer).notNull()
                t.column("x", .double).notNull().defaults(to: 0)
                t.column("y", .double).notNull().defaults(to: 0)
                t.column("statusRaw", .text).notNull()
                t.column("guestCount", .integer).notNull().defaults(to: 0)
                t.column("occupiedSince", .datetime)
            }
        }
        return m
    }
}
