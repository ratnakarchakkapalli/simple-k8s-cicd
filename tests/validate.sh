#!/bin/bash

# Simple HTML validation test script
# This runs during GitHub Actions CI phase

set -e

echo "🧪 Running Tests..."
echo "==================="

# Check if HTML file exists
if [ ! -f "src/index.html" ]; then
    echo "❌ FAIL: src/index.html not found"
    exit 1
fi

echo "✅ HTML file exists"

# Check if HTML is valid (basic checks)
if ! grep -q "<!DOCTYPE html>" src/index.html; then
    echo "❌ FAIL: Missing DOCTYPE declaration"
    exit 1
fi

echo "✅ DOCTYPE declaration found"

if ! grep -q "<title>" src/index.html; then
    echo "❌ FAIL: Missing title tag"
    exit 1
fi

echo "✅ Title tag found"

if ! grep -q "<h1>" src/index.html; then
    echo "❌ FAIL: Missing h1 heading"
    exit 1
fi

echo "✅ H1 heading found"

# Check for common closing tags
if ! grep -q "</html>" src/index.html; then
    echo "❌ FAIL: Missing closing html tag"
    exit 1
fi

echo "✅ Closing tags present"

# Check file size (should be > 500 bytes)
file_size=$(wc -c < src/index.html)
if [ "$file_size" -lt 500 ]; then
    echo "⚠️  WARNING: HTML file seems small (${file_size} bytes)"
else
    echo "✅ HTML file size OK (${file_size} bytes)"
fi

echo "==================="
echo "✅ All tests passed!"
echo "==================="
