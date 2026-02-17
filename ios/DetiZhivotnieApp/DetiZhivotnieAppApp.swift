import SwiftUI
import FirebaseCore

@main
struct DetiZhivotnieAppApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
