import Foundation
import UIKit

final class ExportService {
    static let shared = ExportService()
    private init() {}

    func exportOrdersCSV() -> URL? {
        let orders = (try? OrderRepository.shared.fetchAll()) ?? []
        var csv = "Номер заказа,Стол,Статус,Дата,Позиции,Сумма\n"
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        for o in orders {
            let items = o.items.map { "\($0.menuItemName) x\($0.quantity)" }.joined(separator: "; ")
            let row = "\"\(o.id.uuidString.prefix(8))\",\"\(o.tableNumber)\",\"\(o.status.rawValue)\",\"\(df.string(from: o.createdAt))\",\" \(items)\",\"\(o.total)\"\n"
            csv.append(row)
        }
        return writeToFile(csv, name: "orders.csv")
    }

    func exportMenuCSV() -> URL? {
        let items = (try? MenuRepository.shared.fetchAll()) ?? []
        var csv = "Название,Категория,Цена,В наличии,Хит,Новинка\n"
        for i in items {
            csv.append("\"\(i.name)\",\"\(i.category.rawValue)\",\"\(i.price)\",\"\(i.isAvailable)\",\"\(i.isHit)\",\"\(i.isNewItem)\"\n")
        }
        return writeToFile(csv, name: "menu.csv")
    }

    private func writeToFile(_ content: String, name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
