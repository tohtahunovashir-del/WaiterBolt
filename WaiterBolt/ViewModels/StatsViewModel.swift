import Foundation
import SwiftData
import Combine

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var todayRevenue: Double = 0
    @Published var weekRevenue: Double = 0
    @Published var monthRevenue: Double = 0
    @Published var popular: [(MenuItem, Int)] = []
    @Published var ordersCount: Int = 0

    private let data = DataService.shared

    func load() {
        let now = Date()
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: now)
        let startOfWeek = cal.date(byAdding: .day, value: -7, to: startOfDay) ?? startOfDay
        let startOfMonth = cal.date(byAdding: .month, value: -1, to: startOfDay) ?? startOfDay

        todayRevenue = data.revenue(for: (startOfDay, now))
        weekRevenue = data.revenue(for: (startOfWeek, now))
        monthRevenue = data.revenue(for: (startOfMonth, now))
        popular = data.popularItems(limit: 5)
        ordersCount = data.fetchOrders(status: .closed, from: startOfDay, to: now).count
    }
}
