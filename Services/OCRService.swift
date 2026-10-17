import Foundation
import Vision
import UIKit

struct RecognizedMenuItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var price: Double
    var category: MenuCategory
    var isSelected: Bool = true
}

final class OCRService {
    static let shared = OCRService()
    private init() {}

    func recognizeMenu(from image: UIImage, completion: @escaping (Result<[RecognizedMenuItem], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }
        let request = VNRecognizeTextRequest { request, error in
            if let error { completion(.failure(error)); return }
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.success([])); return
            }
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            let parsed = self.parseMenuLines(lines)
            DispatchQueue.main.async { completion(.success(parsed)) }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["ru-RU", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do { try handler.perform([request]) }
            catch { DispatchQueue.main.async { completion(.failure(error)) } }
        }
    }

    private func parseMenuLines(_ lines: [String]) -> [RecognizedMenuItem] {
        var result: [RecognizedMenuItem] = []
        var pendingName: String?

        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            if isNoise(line) { continue }

            if let price = extractPrice(from: line) {
                var name = line
                if let range = priceRange(in: line) {
                    name = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                    name = name.trimmingCharacters(in: CharacterSet(charactersIn: "-–—:. "))
                }
                if name.isEmpty, let pending = pendingName {
                    name = pending
                    pendingName = nil
                }
                // очистка названия от мусора
                name = cleanName(name)
                if !name.isEmpty && name.count >= 2 {
                    result.append(RecognizedMenuItem(name: name, price: price, category: guessCategory(for: name)))
                }
            } else {
                if isCategoryHeader(line) { continue }
                pendingName = pendingName.map { $0 + " " + line } ?? line
            }
        }
        // дедупликация по названию
        var seen = Set<String>()
        return result.filter { seen.insert($0.name.lowercased()).inserted }
    }

    private func extractPrice(from text: String) -> Double? {
        let pattern = #"(?<!\d)(\d{1,3}(?:[\s\u00A0]\d{3})*(?:[.,]\d{1,2})?)(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        guard let last = matches.last, let r = Range(last.range, in: text) else { return nil }
        let numStr = String(text[r]).replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(numStr)
    }

    private func priceRange(in text: String) -> Range<String.Index>? {
        let pattern = #"(?<!\d)(\d{1,3}(?:[\s\u00A0]\d{3})*(?:[.,]\d{1,2})?)(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        guard let last = matches.last, let r = Range(last.range, in: text) else { return nil }
        return r
    }

    private func isCategoryHeader(_ line: String) -> Bool {
        let lower = line.lowercased()
        let headers = ["закуски", "горячее", "напитки", "десерты", "салаты", "супы", "гарниры", "меню", "прайс", "ассортимент"]
        return headers.contains { lower == $0 || lower.hasPrefix($0) } && extractPrice(from: line) == nil
    }

    private func isNoise(_ line: String) -> Bool {
        let lower = line.lowercased()
        let noise = ["руб", "р.", "стр.", "страница", "меню", "кафе", "ресторан", "бар"]
        if line.count < 2 { return true }
        if noise.contains(where: { lower == $0 }) { return true }
        // строка только из цифр/символов
        if line.rangeOfCharacter(from: .letters) == nil { return true }
        return false
    }

    private func cleanName(_ name: String) -> String {
        var n = name
        // убрать лишние пробелы
        n = n.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        // убрать trailing разделители
        n = n.trimmingCharacters(in: .whitespaces)
        n = n.trimmingCharacters(in: CharacterSet(charactersIn: "-–—:. "))
        return n
    }

    private func guessCategory(for name: String) -> MenuCategory {
        let lower = name.lowercased()
        let drinks = ["чай", "кофе", "сок", "вода", "лимонад", "кола", "пиво", "вино", "коктейль", "напиток", "компот", "морс", "квас"]
        let desserts = ["торт", "пирог", "мороженое", "десерт", "чизкейк", "тирамису", "выпечка", "круассан", "пирожное", "блин"]
        let appetizers = ["салат", "закуска", "суп", "борщ", "солянка", "закус", "окрошка", "заливное"]
        if drinks.contains(where: { lower.contains($0) }) { return .drinks }
        if desserts.contains(where: { lower.contains($0) }) { return .desserts }
        if appetizers.contains(where: { lower.contains($0) }) { return .appetizers }
        return .mains
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Не удалось обработать изображение"
        }
    }
}
