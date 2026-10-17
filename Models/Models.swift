import Foundation
import SwiftData

// MARK: - Категории меню

enum MenuCategory: String, CaseIterable, Codable, Identifiable {
    case appetizers = "Закуски"
    case mains = "Горячее"
    case drinks = "Напитки"
    case desserts = "Десерты"
    case other = "Прочее"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .appetizers: return "leaf.fill"
        case .mains: return "flame.fill"
        case .drinks: return "cup.and.saucer.fill"
        case .desserts: return "birthday.cake.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Статус стола

enum TableStatus: String, CaseIterable, Codable {
    case free = "Свободен"
    case occupied = "Занят"
    case waitingBill = "Ожидает счёт"

    var color: (red: Double, green: Double, blue: Double) {
        switch self {
        case .free: return (0.2, 0.78, 0.35)
        case .occupied: return (0.95, 0.3, 0.25)
        case .waitingBill: return (0.95, 0.7, 0.15)
        }
    }
}

// MARK: - Статус заказа

enum OrderStatus: String, CaseIterable, Codable {
    case new = "Новый"
    case preparing = "Готовится"
    case ready = "Готов"
    case closed = "Закрыт"
    case cancelled = "Отменён"

    var color: (red: Double, green: Double, blue: Double) {
        switch self {
        case .new: return (0.2, 0.5, 0.95)
        case .preparing: return (0.95, 0.7, 0.15)
        case .ready: return (0.2, 0.78, 0.35)
        case .closed: return (0.5, 0.5, 0.5)
        case .cancelled: return (0.95, 0.3, 0.25)
        }
    }
}

// MARK: - Позиция меню

@Model
final class MenuItem {
    var id: UUID
    var name: String
    var itemDescription: String
    var price: Double
    var imageName: String?
    var weight: String?
    var categoryRaw: String
    var isAvailable: Bool
    var isHit: Bool
    var isNewItem: Bool
    var modifiers: [String]
    var popularity: Int
    var createdAt: Date

    var category: MenuCategory {
        get { MenuCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        name: String,
        itemDescription: String = "",
        price: Double,
        imageName: String? = nil,
        weight: String? = nil,
        category: MenuCategory = .other,
        isAvailable: Bool = true,
        isHit: Bool = false,
        isNewItem: Bool = false,
        modifiers: [String] = [],
        popularity: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.itemDescription = itemDescription
        self.price = price
        self.imageName = imageName
        self.weight = weight
        self.categoryRaw = category.rawValue
        self.isAvailable = isAvailable
        self.isHit = isHit
        self.isNewItem = isNewItem
        self.modifiers = modifiers
        self.popularity = popularity
        self.createdAt = Date()
    }
}

// MARK: - Позиция в заказе

@Model
final class OrderItem {
    var id: UUID
    var menuItem: MenuItem?
    var quantity: Int
    var selectedModifiers: [String]
    var notes: String
    var order: Order?

    var subtotal: Double {
        (menuItem?.price ?? 0) * Double(quantity)
    }

    init(
        menuItem: MenuItem,
        quantity: Int = 1,
        selectedModifiers: [String] = [],
        notes: String = ""
    ) {
        self.id = UUID()
        self.menuItem = menuItem
        self.quantity = quantity
        self.selectedModifiers = selectedModifiers
        self.notes = notes
    }
}

// MARK: - Заказ

@Model
final class Order {
    var id: UUID
    var tableNumber: Int
    var guestName: String?
    @Relationship(deleteRule: .cascade, inverse: \OrderItem.order)
    var items: [OrderItem]?
    var statusRaw: String
    var notes: String
    var createdAt: Date
    var closedAt: Date?
    var splitCount: Int

    var status: OrderStatus {
        get { OrderStatus(rawValue: statusRaw) ?? .new }
        set { statusRaw = newValue.rawValue }
    }

    var total: Double {
        (items ?? []).reduce(0) { $0 + $1.subtotal }
    }

    var itemCount: Int {
        (items ?? []).reduce(0) { $0 + $1.quantity }
    }

    init(tableNumber: Int, guestName: String? = nil, notes: String = "") {
        self.id = UUID()
        self.tableNumber = tableNumber
        self.guestName = guestName
        self.items = []
        self.statusRaw = OrderStatus.new.rawValue
        self.notes = notes
        self.createdAt = Date()
        self.splitCount = 1
    }
}

// MARK: - Стол

@Model
final class Table {
    var id: UUID
    var number: Int
    var x: Double
    var y: Double
    var statusRaw: String
    var guestCount: Int
    var occupiedSince: Date?

    var status: TableStatus {
        get { TableStatus(rawValue: statusRaw) ?? .free }
        set { statusRaw = newValue.rawValue }
    }

    var elapsedMinutes: Int {
        guard let since = occupiedSince else { return 0 }
        return Int(Date().timeIntervalSince(since) / 60)
    }

    init(number: Int, x: Double = 0, y: Double = 0) {
        self.id = UUID()
        self.number = number
        self.x = x
        self.y = y
        self.statusRaw = TableStatus.free.rawValue
        self.guestCount = 0
    }
}
