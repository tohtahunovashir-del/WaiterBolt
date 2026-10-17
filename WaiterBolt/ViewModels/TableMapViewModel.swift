import Foundation
import SwiftData
import Combine

@MainActor
final class TableMapViewModel: ObservableObject {
    @Published var tables: [Table] = []
    @Published var selectedTable: Table?

    private let data = DataService.shared

    func load() {
        tables = data.fetchTables()
    }

    func select(_ table: Table) {
        selectedTable = table
    }

    func updateStatus(_ table: Table, status: TableStatus, guestCount: Int = 0) {
        data.updateTableStatus(table, status: status, guestCount: guestCount)
        load()
        if let updated = tables.first(where: { $0.id == table.id }) {
            selectedTable = updated
        }
    }

    func addTable(number: Int) {
        data.addTable(number: number)
        load()
    }

    func deleteTable(_ table: Table) {
        data.deleteTable(table)
        if selectedTable?.id == table.id { selectedTable = nil }
        load()
    }
}
