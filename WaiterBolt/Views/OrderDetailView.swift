import SwiftUI

struct OrderDetailView: View {
    @EnvironmentObject var orderVM: OrderViewModel
    @EnvironmentObject var menuVM: MenuViewModel
    let order: Order
    @State private var showAddItem = false
    @State private var notes = ""
    @State private var splitCount = 2

    private var current: Order { orderVM.currentOrder?.id == order.id ? orderVM.currentOrder! : order }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Шапка
                HStack {
                    VStack(alignment: .leading) {
                        Text("Стол \(current.tableNumber)").font(.title.bold())
                        if let name = current.guestName { Text(name).foregroundColor(.secondary) }
                    }
                    Spacer()
                    StatusBadge(text: current.status.rawValue, color: Color(rgb: current.status.color))
                }
                .cardStyle()

                // Позиции
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Позиции").font(.headline)
                        Spacer()
                        Button { showAddItem = true } label: {
                            Image(systemName: "plus.circle").font(.title3)
                        }
                    }
                    if (current.items ?? []).isEmpty {
                        Text("Нет позиций").foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .center).padding()
                    } else {
                        ForEach(current.items ?? []) { item in
                            OrderItemRow(item: item, onQuantityChange: { q in orderVM.updateQuantity(item, quantity: q) },
                                         onDelete: { orderVM.removeItem(item) })
                        }
                    }
                }
                .cardStyle()

                // Заметки
                VStack(alignment: .leading, spacing: 6) {
                    Text("Заметки (аллергии, пожелания)").font(.headline)
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color.appSecondary)
                        .cornerRadius(10)
                }
                .cardStyle()

                // Итог
                HStack {
                    Text("Итого").font(.title3.bold())
                    Spacer()
                    Text(current.total.currencyString).font(.title2.bold()).foregroundColor(.appPrimary)
                }
                .cardStyle()

                // Действия
                VStack(spacing: 10) {
                    if current.status == .new {
                        PrimaryButton("Отправить на кухню", icon: "paperplane.fill", color: .appPrimary) {
                            orderVM.setStatus(.preparing)
                        }
                    }
                    if current.status == .preparing {
                        PrimaryButton("Готово", icon: "checkmark.circle.fill", color: Color(red: 0.2, green: 0.78, blue: 0.35)) {
                            orderVM.setStatus(.ready)
                        }
                    }
                    if current.status == .ready {
                        PrimaryButton("Закрыть счёт", icon: "creditcard.fill", color: .appAccent) {
                            orderVM.closeOrder()
                        }
                    }
                    // Разделение счёта
                    HStack {
                        Stepper("Разделить на \(splitCount)", value: $splitCount, in: 2...10)
                    }
                    if splitCount > 1 {
                        Text("Каждый платит: \((current.total / Double(splitCount)).currencyString)")
                            .foregroundColor(.secondary)
                        PrimaryButton("Применить разделение", icon: "person.2.fill", color: .gray) {
                            orderVM.splitBill(count: splitCount)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Заказ #\(current.id.uuidString.prefix(6))")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            orderVM.currentOrder = order
            notes = order.notes
        }
        .onChange(of: notes) { newValue in
            current.notes = newValue
            DataService.shared.save()
        }
        .sheet(isPresented: $showAddItem) {
            AddItemToOrderSheet(order: current)
        }
    }
}

struct OrderItemRow: View {
    let item: OrderItem
    let onQuantityChange: (Int) -> Void
    let onDelete: () -> Void
    @State private var qty: Int

    init(item: OrderItem, onQuantityChange: @escaping (Int) -> Void, onDelete: @escaping () -> Void) {
        self.item = item
        self.onQuantityChange = onQuantityChange
        self.onDelete = onDelete
        self._qty = State(initialValue: item.quantity)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.menuItem?.name ?? "—").font(.subheadline.bold())
                if !item.selectedModifiers.isEmpty {
                    Text(item.selectedModifiers.joined(separator: ", ")).font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            Stepper("\(qty)", value: $qty, in: 0...20)
                .onChange(of: qty) { new in onQuantityChange(new) }
            Text(item.subtotal.currencyString).font(.subheadline)
            Button(role: .destructive) { onDelete() } label: {
                Image(systemName: "trash").foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Добавление позиции в заказ

struct AddItemToOrderSheet: View {
    @EnvironmentObject var menuVM: MenuViewModel
    @EnvironmentObject var orderVM: OrderViewModel
    let order: Order
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filtered: [MenuItem] {
        let base = menuVM.items.filter { $0.isAvailable }
        if searchText.isEmpty { return base }
        return base.filter { $0.name.localizedStandardContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { item in
                    Button {
                        orderVM.addItem(menuItem: item, quantity: 1)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name).font(.subheadline.bold())
                                Text(item.price.currencyString).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill").foregroundColor(.appPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Добавить блюдо")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } }
        }
        .onAppear { menuVM.load() }
    }
}
