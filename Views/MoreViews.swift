import SwiftUI
import Charts

struct MoreTabView: View {
    @EnvironmentObject var statsVM: StatsViewModel
    @EnvironmentObject var orderVM: OrderViewModel
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
                    StatCard(title: "Сегодня", value: statsVM.todayRevenue.currencyString, color: .appPrimary, icon: "calendar")
                    StatCard(title: "Неделя", value: statsVM.weekRevenue.currencyString, color: .appAccent, icon: "calendar.badge.clock")
                }
                HStack(spacing: 12) {
                    StatCard(title: "Месяц", value: statsVM.monthRevenue.currencyString, color: .purple, icon: "calendar.circle")
                    StatCard(title: "Заказов сегодня", value: "\(statsVM.ordersCount)", color: .appSuccess, icon: "bag")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Популярные блюда").font(.system(size: 18, weight: .bold))
                    if statsVM.popular.isEmpty {
                        Text("Нет данных").foregroundColor(.secondary)
                    } else {
                        Chart {
                            ForEach(statsVM.popular, id: \.0.id) { item, count in
                                BarMark(
                                    x: .value("Количество", count),
                                    y: .value("Блюдо", item.name)
                                )
                                .foregroundStyle(Color.appPrimary.gradient)
                            }
                        }
                        .frame(height: 220)
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

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("notifications") private var notifications = true
    @State private var exportURL: URL?
    @State private var showShare = false

    var body: some View {
        Form {
            Section("Внешний вид") {
                Toggle("Тёмная тема", isOn: $darkMode)
            }
            Section("Уведомления") {
                Toggle("Уведомления о заказах", isOn: $notifications)
            }
            Section("Экспорт данных") {
                Button {
                    exportURL = ExportService.shared.exportOrdersCSV()
                    showShare = exportURL != nil
                } label: {
                    Label("Экспорт заказов (CSV)", systemImage: "square.and.arrow.up")
                }
                Button {
                    exportURL = ExportService.shared.exportMenuCSV()
                    showShare = exportURL != nil
                } label: {
                    Label("Экспорт меню (CSV)", systemImage: "square.and.arrow.up")
                }
            }
            Section("О приложении") {
                HStack { Text("Версия"); Spacer(); Text("1.0.0").foregroundColor(.secondary) }
                HStack { Text("Разработчик"); Spacer(); Text("WaiterBolt").foregroundColor(.secondary) }
            }
        }
        .navigationTitle("Настройки")
        .sheet(isPresented: $showShare) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
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
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationTitle("История заказов")
        .onAppear { orderVM.fromDate = .distantPast; orderVM.toDate = .distantFuture; orderVM.load() }
    }
}
