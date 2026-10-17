import Foundation
import Combine

@MainActor
final class TableMapViewModel: ObservableObject {
    @Published var tables: [Table] = []
    @Published var selectedTable: Table?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() {
        isLoading = true
        defer { isLoading = false }
        do {
            tables = try TableRepository.shared.fetchAll()
        } catch { errorMessage = error.localizedDescription }
    }

    func select(_ table: Table) { selectedTable = table }

    func updateStatus(_ table: Table, status: TableStatus, guestCount: Int = 0) {
        guard let idx = tables.firstIndex(where: { $0.id == table.id }) else { return }
        var updated = tables[idx]
        updated.status = status
        updated.guestCount = guestCount
        if status == .occupied { updated.occupiedSince = Date() }
        else if status == .free { updated.occupiedSince = nil }
        do {
            try TableRepository.shared.update(updated)
            load()
            if let u = tables.first(where: { $0.id == table.id }) { selectedTable = u }
        } catch { errorMessage = error.localizedDescription }
    }

    func addTable(number: Int) {
        do {
            let t = Table(number: number)
            try TableRepository.shared.add(t)
            load()
        } catch { errorMessage = error.localizedDescription }
    }

    func deleteTable(_ table: Table) {
        do {
            try TableRepository.shared.delete(table)
            if selectedTable?.id == table.id { selectedTable = nil }
            load()
        } catch { errorMessage = error.localizedDescription }
    }
}
