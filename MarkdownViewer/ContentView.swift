import SwiftUI
import WebKit

struct ContentView: View {
    var vm: MarkdownViewModel
    @State private var webView = WKWebView()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if vm.markdownContent.isEmpty && vm.fileURL == nil {
                emptyState
            } else if let error = vm.errorMessage {
                errorView(error)
            } else {
                MarkdownWebView(
                    webView: webView,
                    html: MarkdownRenderer.shared.render(vm.markdownContent)
                )
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear(perform: setupKeyboardHandling)
        .onChange(of: vm.markdownContent) { _, _ in
            webView.loadHTMLString(
                MarkdownRenderer.shared.render(vm.markdownContent),
                baseURL: vm.fileURL?.deletingLastPathComponent()
            )
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

// NSViewRepresentable wrapper for WKWebView
struct MarkdownWebView: NSViewRepresentable {
    let webView: WKWebView
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        webView.setValue(false, forKey: "drawsBackground") // Transparent bg
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Reload only handled via .onChange in ContentView
    }
}
