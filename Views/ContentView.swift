import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("darkMode") private var darkMode = false
    @Environment(\.modelContext) private var modelContext
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
                .tabItem { Label("Заказы", systemImage: "list.bullet.rectangle") }

            MenuTabView()
                .environmentObject(menuVM)
                .environmentObject(orderVM)
                .tabItem { Label("Меню", systemImage: "fork.knife") }

            TableMapView()
                .environmentObject(tableVM)
                .environmentObject(orderVM)
                .tabItem { Label("Зал", systemImage: "square.grid.2x2") }

            ScannerView()
                .environmentObject(scannerVM)
                .environmentObject(menuVM)
                .tabItem { Label("Сканер", systemImage: "camera.viewfinder") }

            MoreTabView()
                .environmentObject(statsVM)
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

// MARK: - Вкладка "Заказы"

struct OrdersTabView: View {
    @EnvironmentObject var orderVM: OrderViewModel
    @State private var showNewOrder = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Фильтры
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
                }
                .padding(.vertical, 8)

                if orderVM.orders.isEmpty {
                    EmptyStateView(icon: "tray", title: "Нет заказов", subtitle: "Создайте новый заказ")
                } else {
                    List {
                        ForEach(orderVM.orders) { order in
                            NavigationLink(destination: OrderDetailView(order: order)) {
                                OrderRow(order: order)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Заказы")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewOrder = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showNewOrder) {
                NewOrderSheet()
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color.appPrimary : Color.appSecondary)
                .foregroundColor(selected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct OrderRow: View {
    let order: Order
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Стол \(order.tableNumber)").font(.headline)
                Text(order.createdAt, style: .time).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(text: order.status.rawValue, color: Color(rgb: order.status.color))
                Text(order.total.currencyString).font(.subheadline.bold())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Новый заказ

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
                        orderVM.createOrder(tableNumber: tableNumber, guestName: guestName.isEmpty ? nil : guestName)
                        // помечаем стол занятым
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

// MARK: - Вкладка "Меню"

struct MenuTabView: View {
    @EnvironmentObject var menuVM: MenuViewModel
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Поиск
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Поиск блюд", text: $menuVM.searchText)
                        .onChange(of: menuVM.searchText) { _ in menuVM.load() }
                }
                .padding(10)
                .background(Color.appSecondary)
                .cornerRadius(12)
                .padding(.horizontal)

                // Категории
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
                }
                .padding(.vertical, 8)

                // Сортировка
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
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }
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
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appPrimary.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(Image(systemName: item.category.icon).foregroundColor(.appPrimary))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.name).font(.headline)
                    if item.isHit { Text("ХИТ").font(.caption2.bold()).foregroundColor(.white).padding(4).background(Color.appAccent).cornerRadius(4) }
                    if item.isNewItem { Text("NEW").font(.caption2.bold()).foregroundColor(.white).padding(4).background(Color.appPrimary).cornerRadius(4) }
                }
                Text(item.itemDescription).font(.caption).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(item.price.currencyString).font(.subheadline.bold())
                if !item.isAvailable {
                    Text("Нет в наличии").font(.caption2).foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Детали блюда

struct MenuItemDetailView: View {
    @EnvironmentObject var menuVM: MenuViewModel
    @EnvironmentObject var orderVM: OrderViewModel
    let item: MenuItem
    @State private var quantity: Int = 1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appPrimary.opacity(0.12))
                    .frame(height: 200)
                    .overlay(Image(systemName: item.category.icon).font(.system(size: 60)).foregroundColor(.appPrimary))

                Text(item.name).font(.title.bold())
                HStack {
                    Text(item.price.currencyString).font(.title2.bold()).foregroundColor(.appPrimary)
                    if let w = item.weight { Text("• \(w)").foregroundColor(.secondary) }
                }
                Text(item.itemDescription).foregroundColor(.secondary)

                if !item.modifiers.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Модификаторы").font(.headline)
                        ForEach(item.modifiers, id: \.self) { m in
                            Text("• \(m)").font(.subheadline)
                        }
                    }
                }

                HStack {
                    Stepper("Количество: \(quantity)", value: $quantity, in: 1...20)
                }

                PrimaryButton("Добавить в заказ", icon: "cart.badge.plus") {
                    if orderVM.currentOrder == nil {
                        orderVM.createOrder(tableNumber: 1)
                    }
                    orderVM.addItem(menuItem: item, quantity: quantity)
                }
            }
            .padding()
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Добавление блюда вручную

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
                        menuVM... // placeholder avoided below
                        DataService.shared.addMenuItem(item)
                        menuVM.load()
                        dismiss()
                    }
                }
            }
        }
    }
}
