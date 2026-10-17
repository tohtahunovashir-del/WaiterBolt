import SwiftUI

extension Color {
    static let appPrimary = Color(red: 0.12, green: 0.47, blue: 0.95)
    static let appAccent = Color(red: 0.95, green: 0.35, blue: 0.25)
    static let appSurface = Color(.systemBackground)
    static let appSecondary = Color(.secondarySystemBackground)

    init(rgb: (Double, Double, Double)) {
        self.init(red: rgb.0, green: rgb.1, blue: rgb.2)
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.appSecondary)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

extension Double {
    var currencyString: String {
        String(format: "%.0f ₽", self)
    }
}
