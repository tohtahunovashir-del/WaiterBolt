import Foundation
import Combine

@MainActor
final class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var currentOrder: Order?
    @Published var filterStatus: OrderStatus? = nil
    @Published var filterTable: Int? = nil
    @Published var fromDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var toDate: Date = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() {
        isLoading = true
        defer { isLoading = false }
        do {
            orders = try OrderRepository.shared.fetchAll(status: filterStatus, tableNumber: filterTable, from: fromDate, to: toDate)
        } catch { errorMessage = error.localizedDescription }
    }

    func createOrder(tableNumber: Int, guestName: String? = nil) {
        let order = Order(tableNumber: tableNumber, guestName: guestName)
        do {
            try OrderRepository.shared.create(order)
            currentOrder = order
            load()
            NotificationService.shared.notifyNewOrder(table: tableNumber, itemsCount: 0)
        } catch { errorMessage = error.localizedDescription }
    }

    func addItem(menuItem: MenuItem, quantity: Int = 1, modifiers: [String] = [], notes: String = "") {
        guard let order = currentOrder else { return }
        var updated = order
        let item = OrderItem(menuItem: menuItem, quantity: quantity, selectedModifiers: modifiers, notes: notes)
        updated.items.append(item)
        do {
            try OrderRepository.shared.update(updated)
            currentOrder = updated
            load()
        } catch { errorMessage = error.localizedDescription }
    }

    func removeItem(_ item: OrderItem) {
        guard let order = currentOrder else { return }
        var updated = order
        updated.items.removeAll { $0.id == item.id }
        do {
            try OrderRepository.shared.update(updated)
            currentOrder = updated
            load()
        } catch { errorMessage = error.localizedDescription }
    }

    func updateQuantity(_ item: OrderItem, quantity: Int) {
        guard let order = currentOrder else { return }
        var updated = order
        if let idx = updated.items.firstIndex(where: { $0.id == item.id }) {
            if quantity <= 0 {
                updated.items.remove(at: idx)
            } else {
                updated.items[idx].quantity = quantity
            }
        }
        do {
            try OrderRepository.shared.update(updated)
            currentOrder = updated
            load()
        } catch { errorMessage = error.localizedDescription }
    }

    func setStatus(_ status: OrderStatus) {
        guard let order = currentOrder else { return }
        var updated = order
        updated.status = status
        if status == .closed { updated.closedAt = Date() }
        do {
            try OrderRepository.shared.update(updated)
            currentOrder = updated
            if status == .ready { NotificationService.shared.notifyOrderReady(table: updated.tableNumber) }
            load()
        } catch { errorMessage = error.localizedDescription }
    }

    func closeOrder() {
        setStatus(.closed)
        currentOrder = nil
    }

    func splitBill(count: Int) {
        guard let order = currentOrder, count > 1 else { return }
        var updated = order
        updated.splitCount = count
        do {
            try OrderRepository.shared.update(updated)
            currentOrder = updated
            load()
        } catch { errorMessage = error.localizedDescription }
    }
}
