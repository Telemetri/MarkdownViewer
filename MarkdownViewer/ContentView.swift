import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct ContentView: View {
    var vm: MarkdownViewModel
    @State private var isDragTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            ZStack {
                if vm.markdownContent.isEmpty && vm.fileURL == nil {
                    emptyState
                } else if let error = vm.errorMessage {
                    errorView(error)
                } else {
                    MarkdownWebView(markdown: vm.markdownContent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                if isDragTargeted {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .background(Color.accentColor.opacity(0.08))
                        .padding(4)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear(perform: setupKeyboardHandling)
        .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url, url.pathExtension.lowercased() == "md" else { return }
                DispatchQueue.main.async { vm.loadFile(url) }
            }
            return true
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            // File name
            if let url = vm.fileURL {
                Label(url.lastPathComponent, systemImage: "doc.text")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                Text("Markdown Viewer").font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Default viewer status / set button
            if vm.isDefaultViewer {
                Label("Default Viewer", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
            } else {
                Button("Set as Default") { vm.setAsDefaultViewer() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            // Open in editor
            Button {
                vm.openInEditor()
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Open in Editor")
            .disabled(vm.fileURL == nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Open a Markdown file to preview it")
                .foregroundColor(.secondary)
            Button("Open File…") { vm.openFilePicker() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle").foregroundColor(.orange)
            Text(message).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func setupKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // ESC = close window (only if not in a text field)
            if event.keyCode == 53,
               !(NSApp.keyWindow?.firstResponder is NSTextView) {
                NSApp.keyWindow?.close()
                return nil
            }
            return event
        }
    }
}

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String

    class Coordinator: NSObject {
        var loadedMarkdown: String = ""
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        WKWebView(frame: .zero)
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        guard markdown != context.coordinator.loadedMarkdown else { return }
        context.coordinator.loadedMarkdown = markdown
        nsView.loadHTMLString(MarkdownRenderer.shared.render(markdown), baseURL: Bundle.main.resourceURL)
    }
}
