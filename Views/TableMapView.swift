import SwiftUI

struct TableMapView: View {
    @EnvironmentObject var tableVM: TableMapViewModel
    @EnvironmentObject var orderVM: OrderViewModel
    @State private var showStatusSheet = false
    @State private var columns = [GridItem(.adaptive(minimum: 100), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(tableVM.tables) { table in
                        TableCard(table: table)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                tableVM.select(table)
                                showStatusSheet = true
                            }
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(16)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: tableVM.tables.map(\.statusRaw))
            }
            .navigationTitle("Карта зала")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        tableVM.addTable(number: (tableVM.tables.map(\.number).max() ?? 0) + 1)
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
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
        VStack(spacing: 8) {
            Text("Стол \(table.number)")
                .font(.system(size: 16, weight: .bold))
            Circle()
                .fill(Color(rgb: table.status.color))
                .frame(width: 16, height: 16)
                .shadow(color: Color(rgb: table.status.color).opacity(0.5), radius: 4)
            Text(table.status.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            if table.status != .free {
                Text("\(table.elapsedMinutes) мин")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            if table.guestCount > 0 {
                Text("\(table.guestCount) гостей")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .background(Color.appSecondary)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(rgb: table.status.color).opacity(0.3), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
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
                Section("Статус стола") {
                    ForEach(TableStatus.allCases, id: \.self) { st in
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            tableVM.updateStatus(table, status: st, guestCount: guestCount)
                            if st == .occupied {
                                orderVM.createOrder(tableNumber: table.number)
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Circle().fill(Color(rgb: st.color)).frame(width: 14, height: 14)
                                Text(st.rawValue).font(.system(size: 16))
                                Spacer()
                                if table.status == st {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.appPrimary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                Section("Количество гостей") {
                    Stepper("\(guestCount) гостей", value: $guestCount, in: 1...20)
                }
                Section {
                    Button(role: .destructive) {
                        tableVM.deleteTable(table)
                        dismiss()
                    } label: {
                        Label("Удалить стол", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Стол \(table.number)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}
