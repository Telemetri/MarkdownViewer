#!/bin/bash
# verify-dev.sh — MarkdownViewer acceptance criteria verification
# Run after: ./build.sh && open /Applications/MarkdownViewer.app
# Usage: bash verify-dev.sh

set -uo pipefail
PASS=0
FAIL=0
APP="/Applications/MarkdownViewer.app"

green() { printf '\033[0;32mPASS\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
red()   { printf '\033[0;31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }

check() {
    local desc="$1"; shift
    if "$@" 2>/dev/null; then green "$desc"; else red "$desc"; fi
}

echo "=== MarkdownViewer — Dev Verification ==="
echo ""

# AC1 — Quick Look Extension installed
check "AC1: QL Extension .appex bundle exists" \
    test -d "$APP/Contents/PlugIns/MarkdownViewerQLExtension.appex"

check "AC1: QL Extension principal class plist exists" \
    test -f "$APP/Contents/PlugIns/MarkdownViewerQLExtension.appex/Contents/Info.plist"

check "AC1: QL Extension declares markdown UTI" bash -c \
    "plutil -p '$APP/Contents/PlugIns/MarkdownViewerQLExtension.appex/Contents/Info.plist' 2>/dev/null | grep -q 'markdown'"

# AC2 — Standalone app executable exists
check "AC2: Main app executable exists" \
    test -f "$APP/Contents/MacOS/MarkdownViewer"

check "AC2: App is signed" bash -c \
    "codesign -v '$APP' 2>/dev/null"

# AC3 — File association registered
check "AC3: CFBundleDocumentTypes declares markdown in main Info.plist" bash -c \
    "plutil -p '$APP/Contents/Info.plist' 2>/dev/null | grep -q 'net.daringfireball.markdown'"

check "AC3: CFBundleURLTypes declares markdownviewer:// scheme" bash -c \
    "plutil -p '$APP/Contents/Info.plist' 2>/dev/null | grep -q 'markdownviewer'"

# AC4 — Copy button (requires manual test — automated check confirms JS assets present)
check "AC4: marked.min.js bundled in app resources" \
    test -f "$APP/Contents/Resources/marked.min.js"

check "AC4: marked.min.js in QL extension bundle" \
    test -f "$APP/Contents/PlugIns/MarkdownViewerQLExtension.appex/Contents/Resources/marked.min.js"

check "AC4: highlight.min.js in QL extension bundle" \
    test -f "$APP/Contents/PlugIns/MarkdownViewerQLExtension.appex/Contents/Resources/highlight.min.js"

check "AC4: marked.min.js is non-empty (>10KB)" bash -c \
    "[ \$(wc -c < '$APP/Contents/Resources/marked.min.js') -gt 10000 ]"

check "AC4: highlight.min.js bundled in app resources" \
    test -f "$APP/Contents/Resources/highlight.min.js"

check "AC4: highlight.min.js is non-empty (>10KB)" bash -c \
    "[ \$(wc -c < '$APP/Contents/Resources/highlight.min.js') -gt 10000 ]"

# AC5 — Entitlements
check "AC5: QL Extension has app-sandbox entitlement" bash -c \
    "codesign -d --entitlements :- '$APP/Contents/PlugIns/MarkdownViewerQLExtension.appex' 2>/dev/null | grep -q 'app-sandbox'"

# AC6 — Rendering (checked via JS assets above)
check "AC6: MarkdownRenderer.swift in source repo" \
    test -f "$HOME/Git/Apps/MarkdownViewer/MarkdownViewer/MarkdownRenderer.swift"

# AC7 — Theme.swift exists (aesthetic implementation)
check "AC7: Theme.swift in source repo (Catppuccin colors)" \
    test -f "$HOME/Git/Apps/MarkdownViewer/MarkdownViewer/Theme.swift"

# Functional binary checks (sabotage-resistant — verify code paths exist in binary)
MAIN_BIN="$APP/Contents/MacOS/MarkdownViewer"
EXT_BIN="$APP/Contents/PlugIns/MarkdownViewerQLExtension.appex/Contents/MacOS/MarkdownViewerQLExtension"

check "FUNCTIONAL: URL scheme registered in main Info.plist" bash -c \
    "plutil -p '$APP/Contents/Info.plist' 2>/dev/null | grep -q 'markdownviewer'"

check "FUNCTIONAL: clipboard message handler in main binary" bash -c \
    "strings '$MAIN_BIN' 2>/dev/null | grep -q 'clipboard'"

check "FUNCTIONAL: QL extension uses JavaScriptCore (in-process markdown rendering)" bash -c \
    "strings '$EXT_BIN' 2>/dev/null | grep -q 'JSContext'"

check "FUNCTIONAL: LSSetDefaultRoleHandlerForContentType imported in main binary" bash -c \
    "nm -u '$MAIN_BIN' 2>/dev/null | grep -q '_LSSetDefaultRoleHandlerForContentType'"

echo ""
echo "─────────────────────────────────────"
echo "Automated: $PASS passed, $FAIL failed"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "✓ Automated checks passed."
else
    echo "✗ $FAIL automated check(s) failed — fix before manual testing."
    exit 1
fi

echo ""
echo "=== Manual Checks Required ==="
echo ""
echo "AC4 — Code block copy button:"
echo "  1. Open any Claude work item .md file in MarkdownViewer"
echo "  2. Hover over a code block → copy button (clipboard icon) should appear top-right"
echo "  3. Click it → paste into TextEdit → confirm code content, no backtick delimiters"
echo "  4. Button should show ✓ for ~1.5 seconds after click"
echo ""
echo "AC5 — Open in Editor:"
echo "  1. With a .md file open, click the pencil icon in the toolbar"
echo "  2. Verify it opens in a third-party editor (Typora, TextEdit, etc.) — NOT MarkdownViewer"
echo ""
echo "AC1 — Spacebar in Finder:"
echo "  1. Select a .md file in Finder"
echo "  2. Press Spacebar → Quick Look panel should show rendered markdown (not raw text)"
echo "  3. Press ESC → panel dismisses"
echo ""
echo "AC2 — ESC to close standalone window:"
echo "  1. Open a .md file (double-click or drag to app)"
echo "  2. Press ESC → window should close"
echo ""
echo "AC3 — Set as Default:"
echo "  1. If MarkdownViewer is not already default, click 'Set as Default' in toolbar"
echo "  2. Toolbar should change to show green '✓ Default Viewer'"
echo "  3. Double-click any .md file → should open in MarkdownViewer (not another app)"
echo ""
echo "Test file: ~/Git/Docs/Work/App - Markdown Viewer/01-requirements.md"
echo "(Contains headings, bullet lists, tables, code blocks — good coverage)"
