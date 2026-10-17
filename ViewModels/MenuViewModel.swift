import Foundation
import Combine

@MainActor
final class MenuViewModel: ObservableObject {
    @Published var items: [MenuItem] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: MenuCategory? = nil
    @Published var sortOption: SortOption = .name
    @Published var errorMessage: String?

    enum SortOption: String, CaseIterable {
        case name = "По названию"
        case priceAsc = "Цена ↑"
        case priceDesc = "Цена ↓"
        case popularity = "Популярность"
    }

    private let data = DataService.shared

    func load() {
        var list = data.fetchMenuItems(category: selectedCategory, search: searchText)
        switch sortOption {
        case .name: list.sort { $0.name < $1.name }
        case .priceAsc: list.sort { $0.price < $1.price }
        case .priceDesc: list.sort { $0.price > $1.price }
        case .popularity: list.sort { $0.popularity > $1.popularity }
        }
        items = list
    }

    func toggleAvailability(_ item: MenuItem) {
        data.toggleAvailability(item)
        load()
    }

    func delete(_ item: MenuItem) {
        data.deleteMenuItem(item)
        load()
    }

    func addFromRecognized(_ recognized: [RecognizedMenuItem]) {
        for r in recognized where r.isSelected {
            let item = MenuItem(name: r.name, price: r.price, category: r.category)
            data.addMenuItem(item)
        }
        load()
    }
}
