import Foundation
import GRDB

final class OrderRepository {
    static let shared = OrderRepository()
    private let db = DatabaseManager.shared.dbQueue
    private init() {}

    func fetchAll(status: OrderStatus? = nil, tableNumber: Int? = nil, from: Date? = nil, to: Date? = nil) throws -> [Order] {
        try db.read { db in
            var request = Order.all()
            if let status { request = request.filter(Order.Columns.statusRaw == status.rawValue) }
            if let tableNumber { request = request.filter(Order.Columns.tableNumber == tableNumber) }
            if let from { request = request.filter(Order.Columns.createdAt >= from) }
            if let to { request = request.filter(Order.Columns.createdAt <= to) }
            return try request.order(Order.Columns.createdAt.desc).fetchAll(db)
        }
    }

    func create(_ order: Order) throws {
        try db.write { db in try order.insert(db) }
    }

    func update(_ order: Order) throws {
        try db.write { db in try order.update(db) }
    }

    func delete(_ order: Order) throws {
        try db.write { db in _ = try order.delete(db) }
    }

    func revenue(from: Date, to: Date) throws -> Double {
        let orders = try fetchAll(status: .closed, from: from, to: to)
        return orders.reduce(0) { $0 + $1.total }
    }

    func popularItems(limit: Int = 5) throws -> [(String, Int)] {
        let orders = try fetchAll(status: .closed)
        var counts: [String: Int] = [:]
        for o in orders {
            for item in o.items {
                counts[item.menuItemName, default: 0] += item.quantity
            }
        }
        return counts.sorted { $0.value > $1.value }.prefix(limit).map { ($0.key, $0.value) }
    }
}
