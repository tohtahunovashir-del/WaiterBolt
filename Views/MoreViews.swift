import SwiftUI

struct MoreTabView: View {
    @EnvironmentObject var statsVM: StatsViewModel
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: StatsView()) {
                    Label("Статистика", systemImage: "chart.bar.fill")
                }
                NavigationLink(destination: SettingsView()) {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
                NavigationLink(destination: OrderHistoryView()) {
                    Label("История заказов", systemImage: "clock.arrow.circlepath")
                }
            }
            .navigationTitle("Ещё")
        }
    }
}

struct StatsView: View {
    @EnvironmentObject var statsVM: StatsViewModel
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    StatCard(title: "Сегодня", value: statsVM.todayRevenue.currencyString, color: .appPrimary)
                    StatCard(title: "Неделя", value: statsVM.weekRevenue.currencyString, color: .appAccent)
                }
                HStack(spacing: 12) {
                    StatCard(title: "Месяц", value: statsVM.monthRevenue.currencyString, color: .purple)
                    StatCard(title: "Заказов сегодня", value: "\(statsVM.ordersCount)", color: .green)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Популярные блюда").font(.headline)
                    ForEach(statsVM.popular, id: \.0.id) { item, count in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text("\(count) шт").foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .cardStyle()
            }
            .padding()
        }
        .navigationTitle("Статистика")
        .onAppear { statsVM.load() }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.title3.bold()).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("notifications") private var notifications = true

    var body: some View {
        Form {
            Section("Внешний вид") {
                Toggle("Тёмная тема", isOn: $darkMode)
            }
            Section("Уведомления") {
                Toggle("Уведомления о заказах", isOn: $notifications)
            }
            Section("О приложении") {
                HStack { Text("Версия"); Spacer(); Text("1.0.0").foregroundColor(.secondary) }
            }
        }
        .navigationTitle("Настройки")
    }
}

struct OrderHistoryView: View {
    @EnvironmentObject var orderVM: OrderViewModel
    var body: some View {
        List {
            ForEach(orderVM.orders) { order in
                NavigationLink(destination: OrderDetailView(order: order)) {
                    OrderRow(order: order)
                }
            }
        }
        .navigationTitle("История заказов")
        .onAppear { orderVM.fromDate = .distantPast; orderVM.toDate = .distantFuture; orderVM.load() }
    }
}
