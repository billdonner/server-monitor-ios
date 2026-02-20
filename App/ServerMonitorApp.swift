import SwiftUI

#if APP_TARGET
@main
struct ServerMonitorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
#endif
