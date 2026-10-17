import Foundation
import GRDB

final class MenuRepository {
    static let shared = MenuRepository()
    private let db = DatabaseManager.shared.dbQueue
    private init() {}

    func fetchAll(category: MenuCategory? = nil, search: String = "") throws -> [MenuItem] {
        try db.read { db in
            var request = MenuItem.all()
            if let category {
                request = request.filter(MenuItem.Columns.categoryRaw == category.rawValue)
            }
            if !search.isEmpty {
                request = request.filter(MenuItem.Columns.name.like("%\(search)%"))
            }
            return try request.order(MenuItem.Columns.name).fetchAll(db)
        }
    }

    func add(_ item: MenuItem) throws {
        try db.write { db in
            try item.insert(db)
        }
    }

    func delete(_ item: MenuItem) throws {
        try db.write { db in
            _ = try item.delete(db)
        }
    }

    func toggleAvailability(_ item: MenuItem) throws {
        try db.write { db in
            var updated = item
            updated.isAvailable.toggle()
            try updated.update(db)
        }
    }

    func seedIfNeeded() throws {
        let count = try db.read { db in try MenuItem.fetchCount(db) }
        if count > 0 { return }
        let samples: [(String, String, Double, MenuCategory)] = [
            ("Цезарь", "Салат с курицей и пармезаном", 450, .appetizers),
            ("Борщ", "Традиционный сметанный", 320, .mains),
            ("Стейк Рибай", "Мраморная говядина 300г", 1890, .mains),
            ("Паста Карбонара", "С беконом и сливочным соусом", 590, .mains),
            ("Лимонад", "Домашний 0.5л", 250, .drinks),
            ("Чай зелёный", "0.3л", 150, .drinks),
            ("Тирамису", "Классический итальянский", 380, .desserts),
            ("Чизкейк", "Нью-Йорк", 350, .desserts)
        ]
        try db.write { db in
            for s in samples {
                var item = MenuItem(name: s.0, itemDescription: s.1, price: s.2, category: s.3, isHit: s.0 == "Цезарь")
                try item.insert(db)
            }
        }
    }
}
