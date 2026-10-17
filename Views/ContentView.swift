import SwiftUI

struct ContentView: View {
    @AppStorage("darkMode") private var darkMode = false
    @StateObject private var menuVM = MenuViewModel()
    @StateObject private var orderVM = OrderViewModel()
    @StateObject private var tableVM = TableMapViewModel()
    @StateObject private var scannerVM = ScannerViewModel()
    @StateObject private var statsVM = StatsViewModel()

    var body: some View {
        TabView {
            OrdersTabView()
                .environmentObject(orderVM)
                .environmentObject(tableVM)
                .tabItem { Label("Заказы", systemImage: "list.bullet.rectangle.portrait") }

            MenuTabView()
                .environmentObject(menuVM)
                .environmentObject(orderVM)
                .tabItem { Label("Меню", systemImage: "fork.knife") }

            TableMapView()
                .environmentObject(tableVM)
                .environmentObject(orderVM)
                .tabItem { Label("Зал", systemImage: "square.grid.2x2.fill") }

            ScannerView()
                .environmentObject(scannerVM)
                .environmentObject(menuVM)
                .tabItem { Label("Сканер", systemImage: "camera.viewfinder") }

            MoreTabView()
                .environmentObject(statsVM)
                .environmentObject(orderVM)
                .tabItem { Label("Ещё", systemImage: "ellipsis.circle") }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
        .onAppear {
            menuVM.load()
            orderVM.load()
            tableVM.load()
            statsVM.load()
            NotificationService.shared.requestAuthorization()
        }
    }
}

// MARK: - Заказы

struct OrdersTabView: View {
    @EnvironmentObject var orderVM: OrderViewModel
    @State private var showNewOrder = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "Все", selected: orderVM.filterStatus == nil) {
                            orderVM.filterStatus = nil; orderVM.load()
                        }
                        ForEach(OrderStatus.allCases, id: \.self) { st in
                            FilterChip(title: st.rawValue, selected: orderVM.filterStatus == st) {
                                orderVM.filterStatus = st; orderVM.load()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                if orderVM.orders.isEmpty {
                    EmptyStateView(icon: "tray", title: "Нет заказов", subtitle: "Создайте новый заказ кнопкой +")
                } else {
                    List {
                        ForEach(orderVM.orders) { order in
                            NavigationLink(destination: OrderDetailView(order: order)) {
                                OrderRow(order: order)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                        .onDelete { idx in
                            // отмена заказа
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Заказы")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewOrder = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.appPrimary)
                    }
                }
            }
            .sheet(isPresented: $showNewOrder) {
                NewOrderSheet()
            }
        }
    }
}

struct OrderRow: View {
    let order: Order
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Стол \(order.tableNumber)").font(.system(size: 17, weight: .bold))
                Text(order.createdAt.shortString).font(.system(size: 12)).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(text: order.status.rawValue, color: Color(rgb: order.status.color))
                Text(order.total.currencyString).font(.system(size: 15, weight: .semibold)).foregroundColor(.appPrimary)
            }
        }
        .padding(14)
        .background(Color.appSecondary)
        .cornerRadius(16)
    }
}

struct NewOrderSheet: View {
    @EnvironmentObject var orderVM: OrderViewModel
    @EnvironmentObject var tableVM: TableMapViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var tableNumber: Int = 1
    @State private var guestName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Стол") {
                    Picker("Номер стола", selection: $tableNumber) {
                        ForEach(tableVM.tables, id: \.number) { t in
                            Text("Стол \(t.number)").tag(t.number)
                        }
                    }
                }
                Section("Гость (необязательно)") {
                    TextField("Имя гостя", text: $guestName)
                }
            }
            .navigationTitle("Новый заказ")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        orderVM.createOrder(tableNumber: tableNumber, guestName: guestName.isEmpty ? nil : guestName)
                        if let t = tableVM.tables.first(where: { $0.number == tableNumber }) {
                            tableVM.updateStatus(t, status: .occupied, guestCount: 1)
                        }
                        dismiss()
                    }
                }
            }
        }
        .onAppear { tableVM.load() }
    }
}

// MARK: - Меню

struct MenuTabView: View {
    @EnvironmentObject var menuVM: MenuViewModel
    @EnvironmentObject var orderVM: OrderViewModel
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Поиск блюд", text: $menuVM.searchText)
                        .onChange(of: menuVM.searchText) { _ in menuVM.load() }
                }
                .padding(12)
                .background(Color.appSecondary)
                .cornerRadius(14)
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "Все", selected: menuVM.selectedCategory == nil) {
                            menuVM.selectedCategory = nil; menuVM.load()
                        }
                        ForEach(MenuCategory.allCases) { cat in
                            FilterChip(title: cat.rawValue, selected: menuVM.selectedCategory == cat) {
                                menuVM.selectedCategory = cat; menuVM.load()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                HStack {
                    Picker("Сортировка", selection: $menuVM.sortOption) {
                        ForEach(MenuViewModel.SortOption.allCases, id: \.self) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: menuVM.sortOption) { _ in menuVM.load() }
                    Spacer()
                }
                .padding(.horizontal)

                if menuVM.items.isEmpty {
                    EmptyStateView(icon: "fork.knife", title: "Меню пусто", subtitle: "Добавьте блюда через сканер или вручную")
                } else {
                    List {
                        ForEach(menuVM.items) { item in
                            NavigationLink(destination: MenuItemDetailView(item: item)) {
                                MenuItemRow(item: item)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onDelete { idx in
                            for i in idx { menuVM.delete(menuVM.items[i]) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Меню")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.appPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddMenuItemSheet()
            }
        }
    }
}

struct MenuItemRow: View {
    let item: MenuItem
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appPrimary.opacity(0.12))
                .frame(width: 54, height: 54)
                .overlay(Image(systemName: item.category.icon).font(.title2).foregroundColor(.appPrimary))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name).font(.system(size: 16, weight: .semibold))
                    if item.isHit { Text("ХИТ").font(.caption2.bold()).foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 2).background(Color.appAccent).cornerRadius(4) }
                    if item.isNewItem { Text("NEW").font(.caption2.bold()).foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 2).background(Color.appPrimary).cornerRadius(4) }
                }
                Text(item.itemDescription).font(.system(size: 13)).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.price.currencyString).font(.system(size: 15, weight: .bold)).foregroundColor(.appPrimary)
                if !item.isAvailable {
                    Text("Нет в наличии").font(.system(size: 11)).foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(Color.appSecondary)
        .cornerRadius(16)
    }
}

struct MenuItemDetailView: View {
    @EnvironmentObject var menuVM: MenuViewModel
    @EnvironmentObject var orderVM: OrderViewModel
    let item: MenuItem
    @State private var quantity: Int = 1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(colors: [Color.appPrimary.opacity(0.15), Color.appPrimary.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 220)
                    .overlay(Image(systemName: item.category.icon).font(.system(size: 70)).foregroundColor(.appPrimary))

                Text(item.name).font(.system(size: 26, weight: .bold))
                HStack {
                    Text(item.price.currencyString).font(.system(size: 22, weight: .bold)).foregroundColor(.appPrimary)
                    if let w = item.weight { Text("• \(w)").foregroundColor(.secondary) }
                }
                Text(item.itemDescription).foregroundColor(.secondary)

                if !item.modifiers.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Модификаторы").font(.system(size: 16, weight: .semibold))
                        ForEach(item.modifiers, id: \.self) { m in
                            Text("• \(m)").font(.system(size: 14))
                        }
                    }
                    .cardStyle()
                }

                Stepper("Количество: \(quantity)", value: $quantity, in: 1...20)

                PrimaryButton("Добавить в заказ", icon: "cart.badge.plus") {
                    if orderVM.currentOrder == nil {
                        orderVM.createOrder(tableNumber: 1)
                    }
                    orderVM.addItem(menuItem: item, quantity: quantity)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
            .padding()
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddMenuItemSheet: View {
    @EnvironmentObject var menuVM: MenuViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var desc = ""
    @State private var price = ""
    @State private var weight = ""
    @State private var category: MenuCategory = .mains
    @State private var isHit = false
    @State private var isNew = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название", text: $name)
                    TextField("Описание", text: $desc)
                    TextField("Цена", text: $price).keyboardType(.decimalPad)
                    TextField("Вес/объём", text: $weight)
                }
                Section("Категория") {
                    Picker("Категория", selection: $category) {
                        ForEach(MenuCategory.allCases) { c in Text(c.rawValue).tag(c) }
                    }
                }
                Section("Пометки") {
                    Toggle("Хит", isOn: $isHit)
                    Toggle("Новинка", isOn: $isNew)
                }
            }
            .navigationTitle("Новое блюдо")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        guard let p = Double(price.replacingOccurrences(of: ",", with: ".")), !name.isEmpty else { return }
                        let item = MenuItem(name: name, itemDescription: desc, price: p, weight: weight.isEmpty ? nil : weight, category: category, isHit: isHit, isNewItem: isNew)
                        try? MenuRepository.shared.add(item)
                        menuVM.load()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                }
            }
        }
    }
}
