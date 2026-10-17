import Foundation
import SwiftData
import Combine

@MainActor
final class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var currentOrder: Order?
    @Published var filterStatus: OrderStatus? = nil
    @Published var filterTable: Int? = nil
    @Published var fromDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var toDate: Date = Date()
    @Published var errorMessage: String?

    private let data = DataService.shared

    func load() {
        orders = data.fetchOrders(status: filterStatus, tableNumber: filterTable, from: fromDate, to: toDate)
    }

    func createOrder(tableNumber: Int, guestName: String? = nil) {
        let order = data.createOrder(tableNumber: tableNumber, guestName: guestName)
        currentOrder = order
        load()
    }

    func addItem(menuItem: MenuItem, quantity: Int = 1, modifiers: [String] = [], notes: String = "") {
        guard let order = currentOrder else { return }
        data.addItem(to: order, menuItem: menuItem, quantity: quantity, modifiers: modifiers, notes: notes)
        // обновляем локальную ссылку
        currentOrder = data.fetchOrders().first { $0.id == order.id }
        load()
    }

    func removeItem(_ item: OrderItem) {
        guard let order = currentOrder else { return }
        data.removeItem(item, from: order)
        currentOrder = data.fetchOrders().first { $0.id == order.id }
        load()
    }

    func updateQuantity(_ item: OrderItem, quantity: Int) {
        data.updateItemQuantity(item, quantity: quantity)
        if let order = currentOrder {
            currentOrder = data.fetchOrders().first { $0.id == order.id }
        }
        load()
    }

    func setStatus(_ status: OrderStatus) {
        guard let order = currentOrder else { return }
        data.updateOrderStatus(order, status: status)
        currentOrder = data.fetchOrders().first { $0.id == order.id }
        if status == .ready {
            NotificationService.shared.notifyOrderReady(table: order.tableNumber)
        }
        load()
    }

    func closeOrder() {
        guard let order = currentOrder else { return }
        data.closeOrder(order)
        currentOrder = nil
        load()
    }

    func splitBill(count: Int) {
        guard let order = currentOrder else { return }
        data.splitOrder(order, count: count)
        currentOrder = data.fetchOrders().first { $0.id == order.id }
        load()
    }
}
