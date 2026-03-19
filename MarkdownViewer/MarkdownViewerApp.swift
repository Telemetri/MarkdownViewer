import SwiftUI
import AppKit

@main
struct MarkdownViewerApp: App {
    @State private var vm = MarkdownViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(vm: vm)
                .background(WindowAccessor())
                .onOpenURL { url in
                    handleURL(url)
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 960, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .newItem) {
                Button("Open…") {
                    vm.openFilePicker()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    vm.isSettingsVisible = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }

    private func handleURL(_ url: URL) {
        // Handle markdownviewer://open?path=...
        if url.scheme == "markdownviewer",
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let pathItem = components.queryItems?.first(where: { $0.name == "path" }),
           let path = pathItem.value {
            let fileURL = URL(fileURLWithPath: path)
            if components.queryItems?.contains(where: { $0.name == "action" && $0.value == "openInEditor" }) == true {
                vm.openInEditor(fileURL)
            } else {
                vm.loadFile(fileURL)
            }
        } else if url.isFileURL {
            // Direct file URL (e.g., opened from Finder or iTerm)
            vm.loadFile(url)
        }
    }
}

// Persists window position and size across launches
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.setFrameAutosaveName("MarkdownViewerMainWindow")
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
