import Foundation

final class MarkdownRenderer {
    static let shared = MarkdownRenderer()
    private init() {}

    // Bundle whose Resources contain marked.min.js and highlight.min.js.
    // In the main app, Bundle.main is the app bundle.
    // In the QL extension, Bundle.main is the extension bundle.
    // Both contain the JS files in their own Resources build phase.
    var resourceBundle: Bundle { Bundle.main }

    // Base URL for WKWebView so <script src="..."> resolves from the right bundle.
    var resourceURL: URL? { resourceBundle.resourceURL }

    // marked.js content loaded from bundle (one-time)
    private lazy var markedJS: String = {
        guard let url = Bundle.main.url(forResource: "marked.min", withExtension: "js"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return "console.error('marked.js not found in bundle');"
        }
        return content
    }()

    // highlight.js content loaded from bundle (one-time)
    private lazy var highlightJS: String = {
        guard let url = Bundle.main.url(forResource: "highlight.min", withExtension: "js"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return "console.error('highlight.js not found in bundle');"
        }
        return content
    }()

    // CSS-only page shell — JS injected via WKUserScript, content via evaluateJavaScript
    var pageHTML: String {
        """
        <!DOCTYPE html><html><head>
        <meta charset="utf-8">
        <style>\(css)</style>
        </head><body><div id="content"></div></body></html>
        """
    }

    // Render script called via evaluateJavaScript after WKUserScript injects the libs
    func renderJS(_ markdown: String) -> String {
        let escaped = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "${", with: "\\${")
        return renderScript(escaped)
    }

    func render(_ markdown: String) -> String {
        let escaped = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "${", with: "\\${")

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        \(css)
        </style>
        </head>
        <body>
        <div id="content"></div>
        <script>\(markedJS)</script>
        <script>\(highlightJS)</script>
        <script>
        \(renderScript(escaped))
        </script>
        </body>
        </html>
        """
    }

    private func renderScript(_ escapedMarkdown: String) -> String {
        return """
        (function() {
          marked.use({ gfm: true, breaks: false });
          hljs.configure({ ignoreUnescapedHTML: true });

          const md = `\(escapedMarkdown)`;
          document.getElementById('content').innerHTML = marked.parse(md);

          // Syntax highlight all code blocks
          document.querySelectorAll('pre code').forEach(block => {
            hljs.highlightElement(block);
          });

          // Inject copy buttons into each pre block
          document.querySelectorAll('pre').forEach(pre => {
            const code = pre.querySelector('code');
            if (!code) return;

            // Language label
            const lang = (code.className.match(/language-(\\w+)/) || [])[1] || '';

            const header = document.createElement('div');
            header.className = 'code-header';

            const langLabel = document.createElement('span');
            langLabel.className = 'code-lang';
            langLabel.textContent = lang;
            header.appendChild(langLabel);

            const copyBtn = document.createElement('button');
            copyBtn.className = 'copy-btn';
            copyBtn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>`;
            copyBtn.title = 'Copy code';
            copyBtn.onclick = function() {
              const text = code.innerText;
              navigator.clipboard.writeText(text).then(() => {
                copyBtn.innerHTML = '✓';
                copyBtn.classList.add('copied');
                setTimeout(() => {
                  copyBtn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>`;
                  copyBtn.classList.remove('copied');
                }, 1500);
              }).catch(() => {
                // Fallback for QL extension context
                window.webkit?.messageHandlers?.clipboard?.postMessage(text);
              });
            };
            header.appendChild(copyBtn);

            pre.style.position = 'relative';
            pre.insertBefore(header, pre.firstChild);
          });
        })();
        """
    }

    private var css: String {
        return """
        *, *::before, *::after { box-sizing: border-box; }

        :root {
          --bg: #ffffff;
          --fg: #1a1a1a;
          --fg-muted: #6b7280;
          --code-bg: #f7f7f8;
          --code-border: #e5e7eb;
          --code-lang: #9ca3af;
          --link: #1d4ed8;
          --blockquote-border: #d1d5db;
          --blockquote-fg: #6b7280;
          --hr: #e5e7eb;
          --table-border: #e5e7eb;
          --table-header-bg: #f9fafb;
          --copy-btn-bg: transparent;
          --copy-btn-hover: #e5e7eb;
          --copy-btn-fg: #9ca3af;
          --copy-btn-copied: #10b981;
        }

        @media (prefers-color-scheme: dark) {
          :root {
            --bg: #1a1a1a;
            --fg: #e5e7eb;
            --fg-muted: #9ca3af;
            --code-bg: #2d2d2d;
            --code-border: #404040;
            --code-lang: #6b7280;
            --link: #60a5fa;
            --blockquote-border: #4b5563;
            --blockquote-fg: #9ca3af;
            --hr: #374151;
            --table-border: #374151;
            --table-header-bg: #252525;
            --copy-btn-hover: #404040;
            --copy-btn-fg: #6b7280;
          }
        }

        html { font-size: 16px; }

        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          font-size: 1rem;
          line-height: 1.7;
          color: var(--fg);
          background: var(--bg);
          margin: 0;
          padding: 0;
        }

        #content {
          max-width: 800px;
          margin: 0 auto;
          padding: 40px 32px 80px;
        }

        /* Headings */
        h1, h2, h3, h4, h5, h6 {
          font-weight: 600;
          line-height: 1.3;
          margin: 1.5em 0 0.5em;
          color: var(--fg);
        }
        h1 { font-size: 1.875rem; margin-top: 0; }
        h2 { font-size: 1.5rem; padding-bottom: 0.3em; border-bottom: 1px solid var(--hr); }
        h3 { font-size: 1.25rem; }
        h4 { font-size: 1rem; }

        /* Paragraphs, lists */
        p { margin: 0.75em 0; }
        ul, ol { margin: 0.75em 0; padding-left: 1.75em; }
        li { margin: 0.25em 0; }
        li input[type=checkbox] { margin-right: 0.5em; }

        /* Links */
        a { color: var(--link); text-decoration: none; }
        a:hover { text-decoration: underline; }

        /* Inline code */
        code:not(pre code) {
          font-family: "SF Mono", "Fira Code", Menlo, Consolas, monospace;
          font-size: 0.875em;
          background: var(--code-bg);
          border: 1px solid var(--code-border);
          border-radius: 4px;
          padding: 0.15em 0.4em;
          color: var(--fg);
        }

        /* Code blocks */
        pre {
          background: var(--code-bg);
          border: 1px solid var(--code-border);
          border-radius: 8px;
          padding: 0;
          margin: 1em 0;
          overflow: hidden;
        }

        pre code {
          display: block;
          font-family: "SF Mono", "Fira Code", Menlo, Consolas, monospace;
          font-size: 0.875rem;
          line-height: 1.6;
          padding: 16px;
          overflow-x: auto;
          background: transparent;
          border: none;
          border-radius: 0;
        }

        /* Code header (language + copy button) */
        .code-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 8px 12px 0;
          min-height: 32px;
        }

        .code-lang {
          font-family: "SF Mono", Menlo, monospace;
          font-size: 0.75rem;
          color: var(--code-lang);
          text-transform: uppercase;
          letter-spacing: 0.05em;
          user-select: none;
        }

        .copy-btn {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 28px;
          height: 28px;
          border: none;
          border-radius: 5px;
          background: var(--copy-btn-bg);
          color: var(--copy-btn-fg);
          cursor: pointer;
          opacity: 0;
          transition: opacity 0.15s, background 0.15s, color 0.15s;
        }

        pre:hover .copy-btn { opacity: 1; }
        .copy-btn:hover { background: var(--copy-btn-hover); }
        .copy-btn.copied { color: var(--copy-btn-copied); opacity: 1; }

        /* Highlight.js overrides (Gemini-inspired colors, light mode) */
        .hljs-keyword, .hljs-built_in { color: #7c3aed; font-weight: 500; }
        .hljs-string, .hljs-attr { color: #059669; }
        .hljs-number, .hljs-literal { color: #dc2626; }
        .hljs-comment, .hljs-quote { color: #9ca3af; font-style: italic; }
        .hljs-title, .hljs-class .hljs-title { color: #1d4ed8; }
        .hljs-variable, .hljs-template-variable { color: #b45309; }
        .hljs-type { color: #0891b2; }
        .hljs-function .hljs-title { color: #7c3aed; }
        .hljs-meta { color: #6b7280; }
        .hljs-name { color: #1d4ed8; }

        @media (prefers-color-scheme: dark) {
          .hljs-keyword, .hljs-built_in { color: #a78bfa; }
          .hljs-string, .hljs-attr { color: #34d399; }
          .hljs-number, .hljs-literal { color: #f87171; }
          .hljs-comment { color: #6b7280; }
          .hljs-title, .hljs-class .hljs-title { color: #60a5fa; }
          .hljs-variable { color: #fbbf24; }
          .hljs-type { color: #22d3ee; }
        }

        /* Blockquote */
        blockquote {
          margin: 1em 0;
          padding: 0.5em 1em;
          border-left: 3px solid var(--blockquote-border);
          color: var(--blockquote-fg);
        }
        blockquote p { margin: 0; }

        /* Horizontal rule */
        hr {
          border: none;
          border-top: 1px solid var(--hr);
          margin: 2em 0;
        }

        /* Tables */
        table {
          width: 100%;
          border-collapse: collapse;
          margin: 1em 0;
          font-size: 0.9rem;
        }
        th, td {
          border: 1px solid var(--table-border);
          padding: 8px 12px;
          text-align: left;
        }
        th { background: var(--table-header-bg); font-weight: 600; }
        tr:nth-child(even) td { background: rgba(0,0,0,0.02); }

        /* Images */
        img { max-width: 100%; height: auto; border-radius: 4px; }

        /* Task list */
        input[type=checkbox] { pointer-events: none; }
        """
    }
}
