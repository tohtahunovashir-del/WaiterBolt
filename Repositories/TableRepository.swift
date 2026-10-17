import Foundation
import GRDB

final class TableRepository {
    static let shared = TableRepository()
    private let db = DatabaseManager.shared.dbQueue
    private init() {}

    func fetchAll() throws -> [Table] {
        try db.read { db in
            try Table.order(Table.Columns.number).fetchAll(db)
        }
    }

    func add(_ table: Table) throws {
        try db.write { db in try table.insert(db) }
    }

    func update(_ table: Table) throws {
        try db.write { db in try table.update(db) }
    }

    func delete(_ table: Table) throws {
        try db.write { db in _ = try table.delete(db) }
    }

    func seedIfNeeded() throws {
        let count = try db.read { db in try Table.fetchCount(db) }
        if count > 0 { return }
        try db.write { db in
            for i in 1...12 {
                let t = Table(number: i, x: Double((i - 1) % 4) * 90, y: Double((i - 1) / 4) * 90)
                try t.insert(db)
            }
        }
    }
}
