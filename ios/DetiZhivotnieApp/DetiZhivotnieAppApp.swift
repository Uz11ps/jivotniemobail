import SwiftUI
import FirebaseCore

@main
struct DetiZhivotnieAppApp: App {
    init() {
        // Firebase is optional at runtime — the UI falls back to empty
        // content when the backend isn't reachable. So only call
        // FirebaseApp.configure() if a GoogleService-Info.plist is
        // actually bundled, otherwise the SDK throws and crashes launch.
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        } else {
            #if DEBUG
            print("⚠️ GoogleService-Info.plist not bundled — Firebase disabled.")
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
