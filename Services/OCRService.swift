import Foundation
import Vision
import UIKit

// MARK: - Результат распознавания одной позиции

struct RecognizedMenuItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var price: Double
    var category: MenuCategory
    var isSelected: Bool = true
}

// MARK: - Сервис OCR (Vision framework)

final class OCRService {
    static let shared = OCRService()
    private init() {}

    /// Распознаёт текст на изображении и пытается извлечь пары "название — цена".
    func recognizeMenu(from image: UIImage, completion: @escaping (Result<[RecognizedMenuItem], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.success([]))
                return
            }

            let lines = observations.compactMap { obs -> String? in
                obs.topCandidates(1).first?.string
            }

            let parsed = self.parseMenuLines(lines)
            DispatchQueue.main.async {
                completion(.success(parsed))
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["ru-RU", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    // MARK: - Парсинг строк

    private func parseMenuLines(_ lines: [String]) -> [RecognizedMenuItem] {
        var result: [RecognizedMenuItem] = []
        // Объединяем многострочные названия: строка без цены считается продолжением предыдущей.
        var pendingName: String?

        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }

            if let price = extractPrice(from: line) {
                // Убираем цену из строки, получаем название
                var name = line
                if let range = priceRange(in: line) {
                    name = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                    // убираем разделители
                    name = name.trimmingCharacters(in: CharacterSet(charactersIn: "-–—:. "))
                }
                if name.isEmpty, let pending = pendingName {
                    name = pending
                    pendingName = nil
                }
                if !name.isEmpty {
                    result.append(RecognizedMenuItem(name: name, price: price, category: guessCategory(for: name)))
                }
            } else {
                // Строка без цены — возможно заголовок категории или продолжение названия
                if isCategoryHeader(line) {
                    // пропускаем, категория определится по ключевым словам
                    continue
                }
                pendingName = pendingName.map { $0 + " " + line } ?? line
            }
        }
        return result
    }

    private func extractPrice(from text: String) -> Double? {
        // Ищем числа с разделителями: 450, 450.00, 450,00, 1 450
        let pattern = #"(?<!\d)(\d{1,3}(?:[\s\u00A0]\d{3})*(?:[.,]\d{1,2})?)(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        // Берём последнее число в строке (цена обычно справа)
        guard let last = matches.last,
              let r = Range(last.range, in: text) else { return nil }
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
        let headers = ["закуски", "горячее", "напитки", "десерты", "салаты", "супы", "гарниры", "меню", "прайс"]
        return headers.contains { lower == $0 || lower.hasPrefix($0) } && extractPrice(from: line) == nil
    }

    private func guessCategory(for name: String) -> MenuCategory {
        let lower = name.lowercased()
        let drinks = ["чай", "кофе", "сок", "вода", "лимонад", "кола", "пиво", "вино", "коктейль", "напиток"]
        let desserts = ["торт", "пирог", "мороженое", "десерт", "чизкейк", "тирамису", "выпечка", "круассан"]
        let appetizers = ["салат", "закуска", "суп", "борщ", "солянка", "закус"]
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
