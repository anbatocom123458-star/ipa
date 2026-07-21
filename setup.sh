#!/bin/bash
set -e

echo "=== BatteryManager iOS Project Setup ==="

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "Installing XcodeGen..."
    brew install xcodegen
fi

# Generate Xcode project
echo "Generating Xcode project..."
xcodegen generate

echo "=== Done! Open BatteryManager.xcodeproj in Xcode ==="
echo ""
echo "Next steps:"
echo "1. Update project.yml with your TEAM_ID and BUNDLE_ID"
echo "2. Update ExportOptions.plist with your TEAM_ID"
echo "3. Add your signing certificate to GitHub Secrets"
echo "4. Push to GitHub to trigger GitHub Actions build"
