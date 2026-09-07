import SwiftUI

/// Role: Spine. Host. Tabs stay mounted; fused margin and Settings arrive as sheets.
struct ContentView: View {
    @StateObject private var watch: SheafWatch
    var handlesLaunch: Bool

    init(watch: SheafWatch = .live(), handlesLaunch: Bool = true) {
        _watch = StateObject(wrappedValue: watch)
        self.handlesLaunch = handlesLaunch
    }

    var body: some View {
        SpineChrome(watch: watch, handlesLaunch: handlesLaunch)
    }
}

#Preview {
    ContentView(watch: .previewPopulated(), handlesLaunch: false)
}
