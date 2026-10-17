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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Стол \(current.tableNumber)").font(.system(size: 28, weight: .bold))
                        if let name = current.guestName {
                            Text(name).font(.system(size: 15)).foregroundColor(.secondary)
                        }
                        Text(current.createdAt.shortString).font(.system(size: 12)).foregroundColor(.secondary)
                    }
                    Spacer()
                    StatusBadge(text: current.status.rawValue, color: Color(rgb: current.status.color))
                }
                .cardStyle()

                // Позиции
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Позиции").font(.system(size: 18, weight: .bold))
                        Spacer()
                        Text("\(current.itemCount) шт").font(.system(size: 13)).foregroundColor(.secondary)
                        Button { showAddItem = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.appPrimary)
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Заметки (аллергии, пожелания)").font(.system(size: 16, weight: .semibold))
                    TextEditor(text: $notes)
                        .frame(height: 90)
                        .padding(10)
                        .background(Color.appSecondary)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                }
                .cardStyle()

                // Итог
                HStack {
                    Text("Итого").font(.system(size: 20, weight: .bold))
                    Spacer()
                    Text(current.total.currencyString).font(.system(size: 24, weight: .bold)).foregroundColor(.appPrimary)
                }
                .cardStyle()

                // Действия
                VStack(spacing: 12) {
                    if current.status == .new {
                        PrimaryButton("Отправить на кухню", icon: "paperplane.fill", color: .appPrimary) {
                            orderVM.setStatus(.preparing)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                    }
                    if current.status == .preparing {
                        PrimaryButton("Готово", icon: "checkmark.circle.fill", color: .appSuccess) {
                            orderVM.setStatus(.ready)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                    }
                    if current.status == .ready {
                        PrimaryButton("Закрыть счёт", icon: "creditcard.fill", color: .appAccent) {
                            orderVM.closeOrder()
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                    }
                    // Разделение счёта
                    VStack(alignment: .leading, spacing: 8) {
                        Stepper("Разделить на \(splitCount) гостей", value: $splitCount, in: 2...10)
                        if splitCount > 1 {
                            Text("Каждый платит: \((current.total / Double(splitCount)).currencyString)")
                                .font(.system(size: 14)).foregroundColor(.secondary)
                            SecondaryButton("Применить разделение", icon: "person.2.fill") {
                                orderVM.splitBill(count: splitCount)
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            }
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
            try? OrderRepository.shared.update(current)
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
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.menuItem?.name ?? "—").font(.system(size: 15, weight: .semibold))
                if !item.selectedModifiers.isEmpty {
                    Text(item.selectedModifiers.joined(separator: ", ")).font(.system(size: 12)).foregroundColor(.secondary)
                }
            }
            Spacer()
            Stepper("\(qty)", value: $qty, in: 0...20)
                .onChange(of: qty) { new in onQuantityChange(new) }
                .frame(width: 110)
            Text(item.subtotal.currencyString).font(.system(size: 14, weight: .semibold)).frame(width: 70, alignment: .trailing)
            Button(role: .destructive) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onDelete()
            } label: {
                Image(systemName: "trash").foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.appSecondary)
        .cornerRadius(14)
    }
}

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
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name).font(.system(size: 15, weight: .semibold))
                                Text(item.price.currencyString).font(.system(size: 13)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill").foregroundColor(.appPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Поиск блюд")
            .navigationTitle("Добавить блюдо")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } }
        }
        .onAppear { menuVM.load() }
    }
}
