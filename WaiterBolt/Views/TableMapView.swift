import SwiftUI

struct TableMapView: View {
    @EnvironmentObject var tableVM: TableMapViewModel
    @EnvironmentObject var orderVM: OrderViewModel
    @State private var showStatusSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 12) {
                    ForEach(tableVM.tables) { table in
                        TableCard(table: table)
                            .onTapGesture {
                                tableVM.select(table)
                                showStatusSheet = true
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Карта зала")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { tableVM.addTable(number: (tableVM.tables.map(\.number).max() ?? 0) + 1) } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showStatusSheet) {
                if let t = tableVM.selectedTable {
                    TableStatusSheet(table: t)
                }
            }
            .onAppear { tableVM.load() }
        }
    }
}

struct TableCard: View {
    let table: Table
    var body: some View {
        VStack(spacing: 6) {
            Text("Стол \(table.number)").font(.headline)
            Circle()
                .fill(Color(rgb: table.status.color))
                .frame(width: 14, height: 14)
            Text(table.status.rawValue).font(.caption2).foregroundColor(.secondary)
            if table.status != .free {
                Text("\(table.elapsedMinutes) мин").font(.caption2).foregroundColor(.secondary)
            }
        }
        .frame(width: 90, height: 90)
        .background(Color.appSecondary)
        .cornerRadius(14)
    }
}

struct TableStatusSheet: View {
    @EnvironmentObject var tableVM: TableMapViewModel
    @EnvironmentObject var orderVM: OrderViewModel
    let table: Table
    @Environment(\.dismiss) private var dismiss
    @State private var guestCount = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("Статус") {
                    ForEach(TableStatus.allCases, id: \.self) { st in
                        Button {
                            tableVM.updateStatus(table, status: st, guestCount: guestCount)
                            if st == .occupied {
                                orderVM.createOrder(tableNumber: table.number)
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Circle().fill(Color(rgb: st.color)).frame(width: 12, height: 12)
                                Text(st.rawValue)
                                Spacer()
                                if table.status == st { Image(systemName: "checkmark").foregroundColor(.appPrimary) }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                Section("Гостей") {
                    Stepper("\(guestCount)", value: $guestCount, in: 1...20)
                }
                Section {
                    Button(role: .destructive) {
                        tableVM.deleteTable(table)
                        dismiss()
                    } label: { Text("Удалить стол") }
                }
            }
            .navigationTitle("Стол \(table.number)")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
    }
}
