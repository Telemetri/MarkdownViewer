#!/bin/bash
# verify-dev.sh — MarkdownViewer acceptance criteria verification
# Run after: ./build.sh && open /Applications/MarkdownViewer.app
PASS=0; FAIL=0

check() {
    local desc="$1"
    shift
    if "$@" 2>/dev/null; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

# AC1: QL Extension installed
check "QL Extension installed" test -d "/Applications/MarkdownViewer.app/Contents/PlugIns/MarkdownViewerQLExtension.appex"

# AC2: App bundle exists and is launchable
check "App bundle executable present" test -f "/Applications/MarkdownViewer.app/Contents/MacOS/MarkdownViewer"

# AC6: marked.js bundled
check "marked.js bundled" test -f "/Applications/MarkdownViewer.app/Contents/Resources/marked.min.js"

# AC6: highlight.js bundled
check "highlight.js bundled" test -f "/Applications/MarkdownViewer.app/Contents/Resources/highlight.min.js"

# AC6: JS files are not empty stubs
check "marked.js > 10KB" bash -c 'test $(wc -c < /Applications/MarkdownViewer.app/Contents/Resources/marked.min.js) -gt 10240'
check "highlight.js > 10KB" bash -c 'test $(wc -c < /Applications/MarkdownViewer.app/Contents/Resources/highlight.min.js) -gt 10240'

# AC7: Extension entitlements include sandbox
check "QL Extension has sandbox entitlement" bash -c 'codesign -d --entitlements - /Applications/MarkdownViewer.app/Contents/PlugIns/MarkdownViewerQLExtension.appex 2>/dev/null | grep -q "app-sandbox"'

# QL Extension bundle structure
check "QL Extension executable present" test -f "/Applications/MarkdownViewer.app/Contents/PlugIns/MarkdownViewerQLExtension.appex/Contents/MacOS/MarkdownViewerQLExtension"

# Bundle identifier
check "Main app bundle ID correct" bash -c '/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" /Applications/MarkdownViewer.app/Contents/Info.plist 2>/dev/null | grep -q "com.xeroint.MarkdownViewer"'

# URL scheme registered
check "markdownviewer:// URL scheme declared" bash -c '/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" /Applications/MarkdownViewer.app/Contents/Info.plist 2>/dev/null | grep -q "markdownviewer"'

# Document types
check "Markdown document type declared" bash -c '/usr/libexec/PlistBuddy -c "Print :CFBundleDocumentTypes:0:CFBundleTypeName" /Applications/MarkdownViewer.app/Contents/Info.plist 2>/dev/null | grep -q "Markdown"'

echo ""
echo "Results: $PASS passed, $FAIL failed"
test $FAIL -eq 0
