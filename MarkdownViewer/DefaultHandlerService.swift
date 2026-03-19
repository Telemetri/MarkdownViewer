import Foundation
import CoreServices
import AppKit

// Standalone namespace for Launch Services calls.
// Extracted for testability and to keep MarkdownViewModel clean.
enum DefaultHandlerService {
    static let markdownUTIs = ["net.daringfireball.markdown", "public.markdown"]

    static func setAsDefault(bundleIdentifier: String) {
        for uti in markdownUTIs {
            LSSetDefaultRoleHandlerForContentType(uti as CFString, .editor, bundleIdentifier as CFString)
        }
    }

    static func isCurrentDefault(bundleIdentifier: String) -> Bool {
        let uti = markdownUTIs[0] as CFString
        let current = LSCopyDefaultRoleHandlerForContentType(uti, .editor)?.takeRetainedValue() as? String
        return current == bundleIdentifier
    }
}
