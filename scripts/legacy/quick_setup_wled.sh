#!/bin/bash

# WLED SP530E Quick Setup
# Usage: ./quick_setup_wled.sh [version]
# Example: ./quick_setup_wled.sh v0.16.0

WLED_VERSION=${1:-"main"}
PROJECT_NAME="wled-${WLED_VERSION}-sp530e"

echo "🚀 WLED SP530E Quick Setup"
echo "========================="
echo "Version: $WLED_VERSION"
echo "Directory: $PROJECT_NAME"
echo ""

# Step 1: Clone WLED
echo "📥 Cloning WLED..."
git clone https://github.com/Aircoookie/WLED.git "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Step 2: Checkout version (if specified)
if [ "$WLED_VERSION" != "main" ]; then
    echo "🔄 Switching to $WLED_VERSION..."
    git fetch --all --tags >/dev/null 2>&1
    
    if git checkout "$WLED_VERSION" 2>/dev/null; then
        echo "✅ Checked out $WLED_VERSION"
        git describe --tags 2>/dev/null || echo "On branch: $(git branch --show-current)"
    else
        echo "❌ Version '$WLED_VERSION' not found."
        echo ""
        echo "📋 Available recent versions:"
        echo "Stable releases:"
        git tag | grep -E "^v0\.(1[4-9]|[2-9][0-9])\.[0-9]+$" | sort -V | tail -5
        echo ""
        echo "Beta/RC versions:"
        git tag | grep -E "^v0\.(1[4-9]|[2-9][0-9]).*(-rc|-beta|\.beta)" | sort -V | tail -5
        echo ""
        echo "Branches:"
        git branch -r | grep -E "(main|0_[0-9]+_x)" | sed 's/origin\///' | head -3
        exit 1
    fi
fi

# Step 3: Apply SP530E configuration
echo "🎯 Applying SP530E configuration..."

# Try local package first, fallback to remote
if [ -f "../sp530e_config_package/apply_sp530e.sh" ]; then
    echo "   📦 Using local SP530E package..."
    ../sp530e_config_package/apply_sp530e.sh
elif command -v curl >/dev/null 2>&1; then
    echo "   🌐 Downloading SP530E package..."
    curl -sSL "https://raw.githubusercontent.com/johnvoipguy/wled-sp530e-mods/main/sp530e_config_package/apply_sp530e.sh" | bash
else
    echo "   ❌ Cannot apply SP530E config - no local package or curl"
    echo "   📝 Manual setup required"
    exit 1
fi

echo ""
echo "✅ Setup Complete!"
echo ""
echo "📂 Project: $(pwd)"
echo "🔨 Build: pio run -e sp530e"
echo "📤 Upload: pio run -e sp530e -t upload"
echo ""
echo "🔄 To setup another version:"
echo "   ./quick_setup_wled.sh v0.15.0"
echo "   ./quick_setup_wled.sh main"