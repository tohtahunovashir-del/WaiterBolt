import SwiftUI
import SwiftData

@main
struct WaiterBoltApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataService.shared.container)
    }
}
