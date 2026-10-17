import SwiftUI

@main
struct WaiterBoltApp: App {
    init() {
        do {
            try MenuRepository.shared.seedIfNeeded()
            try TableRepository.shared.seedIfNeeded()
        } catch {}
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
