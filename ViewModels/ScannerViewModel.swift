import Foundation
import UIKit
import Combine

@MainActor
final class ScannerViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var recognized: [RecognizedMenuItem] = []
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?

    private let ocr = OCRService.shared
    private let data = DataService.shared

    func process(image: UIImage) {
        selectedImage = image
        isProcessing = true
        errorMessage = nil
        ocr.recognizeMenu(from: image) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isProcessing = false
                switch result {
                case .success(let items):
                    self.recognized = items
                    if items.isEmpty {
                        self.errorMessage = "Не удалось распознать позиции. Попробуйте другое фото."
                    }
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                }
            }
        }
    }

    func toggleSelection(_ item: RecognizedMenuItem) {
        if let idx = recognized.firstIndex(where: { $0.id == item.id }) {
            recognized[idx].isSelected.toggle()
        }
    }

    func updateName(_ item: RecognizedMenuItem, name: String) {
        if let idx = recognized.firstIndex(where: { $0.id == item.id }) {
            recognized[idx].name = name
        }
    }

    func updatePrice(_ item: RecognizedMenuItem, price: Double) {
        if let idx = recognized.firstIndex(where: { $0.id == item.id }) {
            recognized[idx].price = price
        }
    }

    func updateCategory(_ item: RecognizedMenuItem, category: MenuCategory) {
        if let idx = recognized.firstIndex(where: { $0.id == item.id }) {
            recognized[idx].category = category
        }
    }

    func importSelected() {
        let selected = recognized.filter { $0.isSelected }
        for r in selected {
            let item = MenuItem(name: r.name, price: r.price, category: r.category)
            data.addMenuItem(item)
        }
        recognized.removeAll()
    }
}
