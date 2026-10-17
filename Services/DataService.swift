import Foundation
import SwiftData
import Combine

// MARK: - Сервис данных (SwiftData)

@MainActor
final class DataService: ObservableObject {
    static let shared = DataService()

    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    private init() {
        let schema = Schema([
            MenuItem.self,
            Order.self,
            OrderItem.self,
            Table.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Не удалось создать контейнер SwiftData: \(error)")
        }
        seedDefaultTablesIfNeeded()
        seedDefaultMenuIfNeeded()
    }

    // MARK: - Столы

    func fetchTables() -> [Table] {
        let descriptor = FetchDescriptor<Table>(sortBy: [SortDescriptor(\.number)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func addTable(number: Int, x: Double = 0, y: Double = 0) {
        let table = Table(number: number, x: x, y: y)
        context.insert(table)
        save()
    }

    func updateTableStatus(_ table: Table, status: TableStatus, guestCount: Int = 0) {
        table.status = status
        table.guestCount = guestCount
        if status == .occupied {
            table.occupiedSince = Date()
        } else if status == .free {
            table.occupiedSince = nil
        }
        save()
    }

    func deleteTable(_ table: Table) {
        context.delete(table)
        save()
    }

    // MARK: - Меню

    func fetchMenuItems(category: MenuCategory? = nil, search: String = "") -> [MenuItem] {
        let descriptor = FetchDescriptor<MenuItem>(sortBy: [SortDescriptor(\.name)])
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { item in
            if let category, item.category != category { return false }
            if !search.isEmpty && !item.name.localizedStandardContains(search) { return false }
            return true
        }
    }

    func addMenuItem(_ item: MenuItem) {
        context.insert(item)
        save()
    }

    func deleteMenuItem(_ item: MenuItem) {
        context.delete(item)
        save()
    }

    func toggleAvailability(_ item: MenuItem) {
        item.isAvailable.toggle()
        save()
    }

    // MARK: - Заказы

    func fetchOrders(status: OrderStatus? = nil, tableNumber: Int? = nil, from: Date? = nil, to: Date? = nil) -> [Order] {
        let descriptor = FetchDescriptor<Order>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { order in
            if let status, order.status != status { return false }
            if let tableNumber, order.tableNumber != tableNumber { return false }
            if let from, order.createdAt < from { return false }
            if let to, order.createdAt > to { return false }
            return true
        }
    }

    func createOrder(tableNumber: Int, guestName: String? = nil, notes: String = "") -> Order {
        let order = Order(tableNumber: tableNumber, guestName: guestName, notes: notes)
        context.insert(order)
        save()
        return order
    }

    func addItem(to order: Order, menuItem: MenuItem, quantity: Int = 1, modifiers: [String] = [], notes: String = "") {
        let item = OrderItem(menuItem: menuItem, quantity: quantity, selectedModifiers: modifiers, notes: notes)
        if order.items == nil { order.items = [] }
        order.items?.append(item)
        context.insert(item)
        save()
    }

    func removeItem(_ item: OrderItem, from order: Order) {
        order.items?.removeAll { $0.id == item.id }
        context.delete(item)
        save()
    }

    func updateItemQuantity(_ item: OrderItem, quantity: Int) {
        if quantity <= 0 {
            if let order = item.order {
                removeItem(item, from: order)
            } else {
                context.delete(item)
                save()
            }
        } else {
            item.quantity = quantity
            save()
        }
    }

    func updateOrderStatus(_ order: Order, status: OrderStatus) {
        order.status = status
        if status == .closed { order.closedAt = Date() }
        save()
    }

    func closeOrder(_ order: Order) {
        updateOrderStatus(order, status: .closed)
    }

    func splitOrder(_ order: Order, count: Int) {
        guard count > 1 else { return }
        order.splitCount = count
        save()
    }

    // MARK: - Статистика

    func revenue(for period: (Date, Date)) -> Double {
        let orders = fetchOrders(status: .closed, from: period.0, to: period.1)
        return orders.reduce(0) { $0 + $1.total }
    }

    func popularItems(limit: Int = 5) -> [(MenuItem, Int)] {
        let orders = fetchOrders(status: .closed)
        var counts: [UUID: Int] = [:]
        for order in orders {
            for item in order.items ?? [] {
                if let id = item.menuItem?.id {
                    counts[id, default: 0] += item.quantity
                }
            }
        }
        let items = fetchMenuItems()
        let mapped = items.map { ($0, counts[$0.id] ?? 0) }
        return mapped.sorted { $0.1 > $1.1 }.prefix(limit).map { $0 }
    }

    // MARK: - Сохранение

    func save() {
        do {
            try context.save()
        } catch {
            print("Ошибка сохранения: \(error)")
        }
    }

    // MARK: - Начальные данные

    private func seedDefaultTablesIfNeeded() {
        if !fetchTables().isEmpty { return }
        for i in 1...12 {
            addTable(number: i, x: Double((i - 1) % 4) * 90, y: Double((i - 1) / 4) * 90)
        }
    }

    private func seedDefaultMenuIfNeeded() {
        if !fetchMenuItems().isEmpty { return }
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
            context.insert(item)
        }
        save()
    }
}
