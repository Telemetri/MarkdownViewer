import Cocoa
import Quartz
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController {
    private var webView: WKWebView!
    private var currentFileURL: URL?

    override func loadView() {
        // WKWebView setup with message handler for clipboard fallback
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: "clipboard")
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        view = webView
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        currentFileURL = url
        guard let markdown = try? String(contentsOf: url, encoding: .utf8) else {
            handler(PreviewError.cannotReadFile)
            return
        }
        let html = MarkdownRenderer.shared.render(markdown)
        webView.loadHTMLString(html, baseURL: nil)
        addOpenInEditorButton()
        handler(nil)
    }

    private func addOpenInEditorButton() {
        // Floating button overlaid on the QL panel (NSButton, not WKWebView button)
        let button = NSButton(title: "Open in Editor", target: self, action: #selector(openInEditor))
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            button.topAnchor.constraint(equalTo: view.topAnchor, constant: 8)
        ])
    }

    @objc private func openInEditor() {
        guard let url = currentFileURL,
              let encodedPath = url.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let schemeURL = URL(string: "markdownviewer://open?path=\(encodedPath)&action=openInEditor") else { return }
        // NSWorkspace.open() for custom schemes IS allowed from QL extension sandbox
        // (unlike opening application URLs directly, which requires allow lsopen)
        NSWorkspace.shared.open(schemeURL)
    }

    enum PreviewError: Error {
        case cannotReadFile
    }
}

// Clipboard fallback handler (copy button in QL sandbox)
extension PreviewViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "clipboard", let text = message.body as? String {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
    }
}
