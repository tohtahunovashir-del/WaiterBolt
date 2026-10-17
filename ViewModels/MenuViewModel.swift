import Foundation
import Combine

@MainActor
final class MenuViewModel: ObservableObject {
    @Published var items: [MenuItem] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: MenuCategory? = nil
    @Published var sortOption: SortOption = .name
    @Published var isLoading = false
    @Published var errorMessage: String?

    enum SortOption: String, CaseIterable {
        case name = "По названию"
        case priceAsc = "Цена ↑"
        case priceDesc = "Цена ↓"
        case popularity = "Популярность"
    }

    func load() {
        isLoading = true
        defer { isLoading = false }
        do {
            var list = try MenuRepository.shared.fetchAll(category: selectedCategory, search: searchText)
            switch sortOption {
            case .name: list.sort { $0.name < $1.name }
            case .priceAsc: list.sort { $0.price < $1.price }
            case .priceDesc: list.sort { $0.price > $1.price }
            case .popularity: list.sort { $0.popularity > $1.popularity }
            }
            items = list
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleAvailability(_ item: MenuItem) {
        do {
            try MenuRepository.shared.toggleAvailability(item)
            load()
        } catch { errorMessage = error.localizedDescription }
    }

    func delete(_ item: MenuItem) {
        do {
            try MenuRepository.shared.delete(item)
            load()
        } catch { errorMessage = error.localizedDescription }
    }

    func add(_ item: MenuItem) {
        do {
            try MenuRepository.shared.add(item)
            load()
        } catch { errorMessage = error.localizedDescription }
    }

    func addFromRecognized(_ recognized: [RecognizedMenuItem]) {
        for r in recognized where r.isSelected {
            let item = MenuItem(name: r.name, price: r.price, category: r.category)
            try? MenuRepository.shared.add(item)
        }
        load()
    }
}
