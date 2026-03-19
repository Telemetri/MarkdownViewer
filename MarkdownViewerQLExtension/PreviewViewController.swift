import Cocoa
import QuickLookUI
import JavaScriptCore

class PreviewViewController: NSViewController, QLPreviewingController {

    private var textView: NSTextView!

    private lazy var jsContext: JSContext? = {
        guard let ctx = JSContext(),
              let url = Bundle.main.url(forResource: "marked.min", withExtension: "js"),
              let js = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        ctx.evaluateScript(js)
        return ctx
    }()

    override func loadView() {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .white

        let tv = NSTextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.backgroundColor = .white
        tv.textContainerInset = NSSize(width: 40, height: 40)
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = .width
        tv.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView.documentView = tv
        self.textView = tv
        self.view = scrollView
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        guard let markdown = try? String(contentsOf: url, encoding: .utf8) else {
            handler(PreviewError.cannotReadFile)
            return
        }

        let bodyHTML = renderMarkdown(markdown)
        let fullHTML = wrapHTML(bodyHTML)

        DispatchQueue.main.async {
            guard let data = fullHTML.data(using: .utf8),
                  let attrStr = try? NSAttributedString(
                      data: data,
                      options: [.documentType: NSAttributedString.DocumentType.html,
                                .characterEncoding: String.Encoding.utf8.rawValue],
                      documentAttributes: nil)
            else {
                self.textView.string = markdown
                handler(nil)
                return
            }
            self.textView.textStorage?.setAttributedString(self.fixLists(attrStr))
            handler(nil)
        }
    }

    // NSAttributedString(html:) inserts literal •\t markers AND sets NSTextList on the
    // paragraph style, producing double bullets. Remove NSTextList to keep only the
    // text-embedded markers.
    private func fixLists(_ src: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: src)
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length),
                                  options: []) { value, range, _ in
            guard let ps = value as? NSParagraphStyle, !ps.textLists.isEmpty else { return }
            let mps = ps.mutableCopy() as! NSMutableParagraphStyle
            mps.textLists = []
            result.addAttribute(.paragraphStyle, value: mps, range: range)
        }
        return result
    }

    private func renderMarkdown(_ markdown: String) -> String {
        guard let ctx = jsContext else {
            return "<pre>\(escapeHTML(markdown))</pre>"
        }
        let escaped = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "${", with: "\\${")
        let script = "(function(){ marked.use({gfm:true,breaks:false}); return marked.parse(`\(escaped)`); })()"
        return ctx.evaluateScript(script)?.toString() ?? "<pre>\(escapeHTML(markdown))</pre>"
    }

    private func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    private func wrapHTML(_ body: String) -> String {
        """
        <!DOCTYPE html><html><head><meta charset="utf-8"><style>
        body { font-family: -apple-system, sans-serif; font-size: 15px; line-height: 1.7;
               color: #1a1a1a; margin: 0; padding: 0; }
        h1 { font-size: 28px; font-weight: 700; margin: 0 0 8px; }
        h2 { font-size: 22px; font-weight: 600; margin: 24px 0 6px; border-bottom: 1px solid #e5e7eb; padding-bottom: 4px; }
        h3 { font-size: 18px; font-weight: 600; margin: 20px 0 6px; }
        h4 { font-size: 15px; font-weight: 600; margin: 16px 0 4px; }
        p  { margin: 0 0 12px; }
        pre { background: #f7f7f8; border: 1px solid #e5e7eb; border-radius: 6px;
              padding: 14px; margin: 12px 0; }
        code { font-family: Menlo, "SF Mono", monospace; font-size: 13px;
               background: #f0f0f1; padding: 2px 5px; border-radius: 3px; }
        pre code { background: none; padding: 0; font-size: 13px; }
        blockquote { margin: 12px 0; padding: 4px 14px; border-left: 3px solid #d1d5db; color: #6b7280; }
        ul, ol { margin: 8px 0 12px; padding-left: 24px; list-style: none; }
        li { margin: 3px 0; }
        a  { color: #1d4ed8; }
        table { border-collapse: collapse; margin: 12px 0; font-size: 14px; }
        th, td { border: 1px solid #e5e7eb; padding: 6px 12px; }
        th { background: #f9fafb; font-weight: 600; }
        hr { border: none; border-top: 1px solid #e5e7eb; margin: 20px 0; }
        </style></head><body>\(body)</body></html>
        """
    }

    enum PreviewError: Error {
        case cannotReadFile
    }
}
