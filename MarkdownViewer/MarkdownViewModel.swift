import Foundation
import Observation
import AppKit
import UniformTypeIdentifiers

@Observable
class MarkdownViewModel {
    var fileURL: URL?
    var markdownContent: String = ""
    var isDefaultViewer: Bool = false
    var isSettingsVisible: Bool = false
    var errorMessage: String?

    init() {
        checkDefaultViewerStatus()
    }

    func loadFile(_ url: URL) {
        fileURL = url
        do {
            markdownContent = try String(contentsOf: url, encoding: .utf8)
        } catch {
            errorMessage = "Cannot read file: \(error.localizedDescription)"
            markdownContent = ""
        }
    }

    func openFilePicker() {
        let panel = NSOpenPanel()
        let mdTypes: [UTType] = [
            UTType("net.daringfireball.markdown") ?? .plainText,
            UTType("public.markdown") ?? .plainText,
        ]
        panel.allowedContentTypes = mdTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            loadFile(url)
        }
    }

    func openInEditor(_ url: URL? = nil) {
        let target = url ?? fileURL
        guard let target else { return }

        if let editorURL = defaultEditorURL(for: target) {
            // Open file in a specific editor app (excluding ourselves)
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.open([target], withApplicationAt: editorURL, configuration: config, completionHandler: nil)
        } else {
            // No other editor registered — open with system default (may re-open MarkdownViewer)
            // This is an acceptable edge case: user has no other .md editor installed
            NSWorkspace.shared.open(target)
        }
    }

    private func defaultEditorURL(for url: URL) -> URL? {
        // Find the default handler for .md EXCLUDING MarkdownViewer
        let uti = "net.daringfireball.markdown"
        let selfBundleID = Bundle.main.bundleIdentifier ?? ""
        // Walk registered handlers; pick first that isn't us
        if let apps = LSCopyAllRoleHandlersForContentType(uti as CFString, .editor)?
            .takeRetainedValue() as? [String] {
            for bundleID in apps where bundleID != selfBundleID {
                if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                    return appURL
                }
            }
        }
        return nil
    }

    func setAsDefaultViewer() {
        let utis = ["net.daringfireball.markdown", "public.markdown"]
        let bundleID = Bundle.main.bundleIdentifier! as CFString
        for uti in utis {
            LSSetDefaultRoleHandlerForContentType(uti as CFString, .editor, bundleID)
        }
        checkDefaultViewerStatus()
    }

    func checkDefaultViewerStatus() {
        let uti = "net.daringfireball.markdown" as CFString
        let current = LSCopyDefaultRoleHandlerForContentType(uti, .editor)?.takeRetainedValue() as? String
        isDefaultViewer = (current == Bundle.main.bundleIdentifier)
    }
}
