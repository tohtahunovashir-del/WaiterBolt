import Foundation
import Combine

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var todayRevenue: Double = 0
    @Published var weekRevenue: Double = 0
    @Published var monthRevenue: Double = 0
    @Published var popular: [(String, Int)] = []
    @Published var ordersCount: Int = 0

    func load() {
        let now = Date()
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: now)
        let startOfWeek = cal.date(byAdding: .day, value: -7, to: startOfDay) ?? startOfDay
        let startOfMonth = cal.date(byAdding: .month, value: -1, to: startOfDay) ?? startOfDay
        do {
            todayRevenue = try OrderRepository.shared.revenue(from: startOfDay, to: now)
            weekRevenue = try OrderRepository.shared.revenue(from: startOfWeek, to: now)
            monthRevenue = try OrderRepository.shared.revenue(from: startOfMonth, to: now)
            popular = try OrderRepository.shared.popularItems(limit: 5)
            ordersCount = try OrderRepository.shared.fetchAll(status: .closed, from: startOfDay, to: now).count
        } catch {}
    }
}
