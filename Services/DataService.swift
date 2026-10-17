import Foundation

private struct Store: Codable {
    var menuItems: [MenuItem] = []
    var orders: [Order] = []
    var tables: [Table] = []
}

@MainActor
final class DataService {
    static let shared = DataService()

    private var store = Store()
    private let fileURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("waiterbolt_data.json")
        load()
        seedDefaultTablesIfNeeded()
        seedDefaultMenuIfNeeded()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Store.self, from: data) {
            store = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(store) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func fetchTables() -> [Table] {
        store.tables.sorted { $0.number < $1.number }
    }

    func addTable(number: Int, x: Double = 0, y: Double = 0) {
        store.tables.append(Table(number: number, x: x, y: y))
        save()
    }

    func updateTableStatus(_ table: Table, status: TableStatus, guestCount: Int = 0) {
        guard let idx = store.tables.firstIndex(where: { $0.id == table.id }) else { return }
        store.tables[idx].status = status
        store.tables[idx].guestCount = guestCount
        if status == .occupied {
            store.tables[idx].occupiedSince = Date()
        } else if status == .free {
            store.tables[idx].occupiedSince = nil
        }
        save()
    }

    func deleteTable(_ table: Table) {
        store.tables.removeAll { $0.id == table.id }
        save()
    }

    func fetchMenuItems(category: MenuCategory? = nil, search: String = "") -> [MenuItem] {
        store.menuItems.filter { item in
            if let category, item.category != category { return false }
            if !search.isEmpty && !item.name.localizedStandardContains(search) { return false }
            return true
        }.sorted { $0.name < $1.name }
    }

    func addMenuItem(_ item: MenuItem) {
        store.menuItems.append(item)
        save()
    }

    func deleteMenuItem(_ item: MenuItem) {
        store.menuItems.removeAll { $0.id == item.id }
        save()
    }

    func toggleAvailability(_ item: MenuItem) {
        if let idx = store.menuItems.firstIndex(where: { $0.id == item.id }) {
            store.menuItems[idx].isAvailable.toggle()
            save()
        }
    }

    func fetchOrders(status: OrderStatus? = nil, tableNumber: Int? = nil, from: Date? = nil, to: Date? = nil) -> [Order] {
        store.orders.filter { order in
            if let status, order.status != status { return false }
            if let tableNumber, order.tableNumber != tableNumber { return false }
            if let from, order.createdAt < from { return false }
            if let to, order.createdAt > to { return false }
            return true
        }.sorted { $0.createdAt > $1.createdAt }
    }

    func createOrder(tableNumber: Int, guestName: String? = nil, notes: String = "") -> Order {
        let order = Order(tableNumber: tableNumber, guestName: guestName, notes: notes)
        store.orders.append(order)
        save()
        return order
    }

    func addItem(to order: Order, menuItem: MenuItem, quantity: Int = 1, modifiers: [String] = [], notes: String = "") {
        guard let idx = store.orders.firstIndex(where: { $0.id == order.id }) else { return }
        let item = OrderItem(menuItem: menuItem, quantity: quantity, selectedModifiers: modifiers, notes: notes)
        if store.orders[idx].items == nil { store.orders[idx].items = [] }
        store.orders[idx].items?.append(item)
        save()
    }

    func removeItem(_ item: OrderItem, from order: Order) {
        guard let idx = store.orders.firstIndex(where: { $0.id == order.id }) else { return }
        store.orders[idx].items?.removeAll { $0.id == item.id }
        save()
    }

    func updateItemQuantity(_ item: OrderItem, quantity: Int) {
        for i in store.orders.indices {
            if let j = store.orders[i].items?.firstIndex(where: { $0.id == item.id }) {
                if quantity <= 0 {
                    store.orders[i].items?.remove(at: j)
                } else {
                    store.orders[i].items?[j].quantity = quantity
                }
                save()
                return
            }
        }
    }

    func updateOrderStatus(_ order: Order, status: OrderStatus) {
        guard let idx = store.orders.firstIndex(where: { $0.id == order.id }) else { return }
        store.orders[idx].status = status
        if status == .closed { store.orders[idx].closedAt = Date() }
        save()
    }

    func closeOrder(_ order: Order) {
        updateOrderStatus(order, status: .closed)
    }

    func splitOrder(_ order: Order, count: Int) {
        guard count > 1 else { return }
        guard let idx = store.orders.firstIndex(where: { $0.id == order.id }) else { return }
        store.orders[idx].splitCount = count
        save()
    }

    func revenue(for period: (Date, Date)) -> Double {
        fetchOrders(status: .closed, from: period.0, to: period.1).reduce(0) { $0 + $1.total }
    }

    func popularItems(limit: Int = 5) -> [(MenuItem, Int)] {
        var counts: [UUID: Int] = [:]
        for order in fetchOrders(status: .closed) {
            for item in order.items ?? [] {
                if let id = item.menuItem?.id {
                    counts[id, default: 0] += item.quantity
                }
            }
        }
        let mapped = fetchMenuItems().map { ($0, counts[$0.id] ?? 0) }
        return Array(mapped.sorted { $0.1 > $1.1 }.prefix(limit))
    }

    private func seedDefaultTablesIfNeeded() {
        if !store.tables.isEmpty { return }
        for i in 1...12 {
            store.tables.append(Table(number: i, x: Double((i - 1) % 4) * 90, y: Double((i - 1) / 4) * 90))
        }
        save()
    }

    private func seedDefaultMenuIfNeeded() {
        if !store.menuItems.isEmpty { return }
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
        for s in samples {
            let item = MenuItem(name: s.0, itemDescription: s.1, price: s.2, category: s.3, isHit: s.0 == "Цезарь")
            store.menuItems.append(item)
        }
        save()
    }
}
