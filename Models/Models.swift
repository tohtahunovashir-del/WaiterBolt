import Foundation
import GRDB

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

struct MenuItem: Codable, Identifiable, Equatable, FetchableRecord, PersistableRecord {
    var id: UUID = UUID()
    var name: String
    var itemDescription: String = ""
    var price: Double
    var imageName: String? = nil
    var weight: String? = nil
    var categoryRaw: String
    var isAvailable: Bool = true
    var isHit: Bool = false
    var isNewItem: Bool = false
    var modifiers: [String] = []
    var popularity: Int = 0
    var createdAt: Date = Date()

    var category: MenuCategory {
        get { MenuCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    static let databaseTableName = "menuItems"

    enum Columns: String, ColumnExpression {
        case id, name, itemDescription, price, imageName, weight, categoryRaw,
             isAvailable, isHit, isNewItem, modifiers, popularity, createdAt
    }

    init(name: String, itemDescription: String = "", price: Double,
         imageName: String? = nil, weight: String? = nil,
         category: MenuCategory = .other, isAvailable: Bool = true,
         isHit: Bool = false, isNewItem: Bool = false,
         modifiers: [String] = [], popularity: Int = 0) {
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

struct OrderItem: Codable, Identifiable, Equatable, FetchableRecord, PersistableRecord {
    var id: UUID = UUID()
    var menuItemId: UUID?
    var menuItemName: String = ""
    var menuItemPrice: Double = 0
    var quantity: Int = 1
    var selectedModifiers: [String] = []
    var notes: String = ""

    var subtotal: Double { menuItemPrice * Double(quantity) }

    var menuItem: MenuItem? {
        // resolved by repository if needed
        nil
    }

    static let databaseTableName = "orderItems"

    enum Columns: String, ColumnExpression {
        case id, menuItemId, menuItemName, menuItemPrice, quantity, selectedModifiers, notes
    }

    init(menuItem: MenuItem, quantity: Int = 1, selectedModifiers: [String] = [], notes: String = "") {
        self.id = UUID()
        self.menuItemId = menuItem.id
        self.menuItemName = menuItem.name
        self.menuItemPrice = menuItem.price
        self.quantity = quantity
        self.selectedModifiers = selectedModifiers
        self.notes = notes
    }
}

// MARK: - Заказ

struct Order: Codable, Identifiable, Equatable, FetchableRecord, PersistableRecord {
    var id: UUID = UUID()
    var tableNumber: Int
    var guestName: String? = nil
    var items: [OrderItem] = []
    var statusRaw: String
    var notes: String = ""
    var createdAt: Date = Date()
    var closedAt: Date? = nil
    var splitCount: Int = 1

    var status: OrderStatus {
        get { OrderStatus(rawValue: statusRaw) ?? .new }
        set { statusRaw = newValue.rawValue }
    }

    var total: Double { items.reduce(0) { $0 + $1.subtotal } }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }

    static let databaseTableName = "orders"

    enum Columns: String, ColumnExpression {
        case id, tableNumber, guestName, items, statusRaw, notes, createdAt, closedAt, splitCount
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

struct Table: Codable, Identifiable, Equatable, FetchableRecord, PersistableRecord {
    var id: UUID = UUID()
    var number: Int
    var x: Double = 0
    var y: Double = 0
    var statusRaw: String
    var guestCount: Int = 0
    var occupiedSince: Date? = nil

    var status: TableStatus {
        get { TableStatus(rawValue: statusRaw) ?? .free }
        set { statusRaw = newValue.rawValue }
    }

    var elapsedMinutes: Int {
        guard let since = occupiedSince else { return 0 }
        return Int(Date().timeIntervalSince(since) / 60)
    }

    static let databaseTableName = "tables"

    enum Columns: String, ColumnExpression {
        case id, number, x, y, statusRaw, guestCount, occupiedSince
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
