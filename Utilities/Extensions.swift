import SwiftUI

extension Color {
    static let appPrimary = Color(red: 0.12, green: 0.47, blue: 0.95)
    static let appAccent = Color(red: 0.95, green: 0.35, blue: 0.25)
    static let appSurface = Color(.systemBackground)
    static let appSecondary = Color(.secondarySystemBackground)
    static let appSuccess = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let appWarning = Color(red: 0.95, green: 0.7, blue: 0.15)

    init(rgb: (Double, Double, Double)) {
        self.init(red: rgb.0, green: rgb.1, blue: rgb.2)
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Color.appSecondary)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

extension Double {
    var currencyString: String {
        String(format: "%.0f ₽", self)
    }
}

extension Date {
    var shortString: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: self)
    }
}
