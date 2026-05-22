#!/bin/bash

# WLED SP530E Version Manager
# Usage: ./upgrade_wled_version.sh <new_version>
# Example: ./upgrade_wled_version.sh v0.16.0

set -e

NEW_VERSION=${1:-"main"}
CURRENT_DIR=$(pwd)
BASE_DIR="/workspace"

echo "🚀 SP530E WLED Version Manager"
echo "=================================="
echo "Target Version: $NEW_VERSION"
echo ""

# Step 1: Create version directory
VERSION_DIR="$BASE_DIR/wled-${NEW_VERSION}-sp530e"
echo "📁 Creating directory: $VERSION_DIR"

if [ -d "$VERSION_DIR" ]; then
    echo "⚠️  Directory already exists. Remove it? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf "$VERSION_DIR"
    else
        echo "❌ Aborted"
        exit 1
    fi
fi

# Step 2: Clone fresh WLED
echo "📥 Cloning WLED $NEW_VERSION..."
git clone https://github.com/Aircoookie/WLED.git "$VERSION_DIR"
cd "$VERSION_DIR"

# Step 3: Checkout specific version (if not main)
if [ "$NEW_VERSION" != "main" ]; then
    echo "🔄 Checking out $NEW_VERSION..."
    git checkout "$NEW_VERSION" || {
        echo "❌ Version $NEW_VERSION not found. Available tags:"
        git tag -l | tail -10
        exit 1
    }
fi

echo "📋 Current WLED version info:"
git describe --tags 2>/dev/null || echo "Development branch"

# Step 4: Copy SP530E modifications
echo "🔧 Copying SP530E modifications..."

# Create backup of original files
mkdir -p sp530e_originals

# Copy platformio.ini modifications
if [ -f "$CURRENT_DIR/platformio.ini" ]; then
    echo "  → Copying platformio.ini with sp530e environment"
    cp "$CURRENT_DIR/platformio.ini" ./platformio.ini
fi

# Copy tools and configurations
if [ -d "$CURRENT_DIR/tools" ]; then
    echo "  → Copying tools directory"
    cp -r "$CURRENT_DIR/tools"/* ./tools/
fi

# Copy GitHub Actions
if [ -d "$CURRENT_DIR/.github" ]; then
    echo "  → Copying GitHub Actions workflows"
    mkdir -p .github
    cp -r "$CURRENT_DIR/.github"/* ./.github/
fi

# Copy documentation
echo "  → Copying SP530E documentation"
[ -f "$CURRENT_DIR/README.md" ] && cp "$CURRENT_DIR/README.md" ./README_SP530E.md
[ -f "$CURRENT_DIR/SP530E_UPGRADE_CHECKLIST.md" ] && cp "$CURRENT_DIR/SP530E_UPGRADE_CHECKLIST.md" ./

# Step 5: Initialize build environment
echo "📦 Setting up build environment..."

# Copy any custom usermods
if [ -d "$CURRENT_DIR/usermods/SP530E" ]; then
    echo "  → Copying SP530E usermod"
    mkdir -p usermods/SP530E
    cp -r "$CURRENT_DIR/usermods/SP530E"/* ./usermods/SP530E/
fi

# Step 6: Test build
echo "🔨 Testing SP530E build..."
pio run -e sp530e --dry-run || {
    echo "⚠️  Build test failed. You may need to update platformio.ini for $NEW_VERSION"
    echo "📝 Manual steps required:"
    echo "   1. Update platformio.ini for any new WLED requirements"
    echo "   2. Check for breaking changes in WLED $NEW_VERSION"
    echo "   3. Test build: pio run -e sp530e"
}

# Step 7: Setup Git
echo "🔧 Setting up Git repository..."
git init
git remote add origin https://github.com/johnvoipguy/wled-sp530e-mods.git
git remote add upstream https://github.com/Aircoookie/WLED.git

# Create version-specific branch
BRANCH_NAME="sp530e-${NEW_VERSION}"
git checkout -b "$BRANCH_NAME"

echo ""
echo "✅ SP530E WLED $NEW_VERSION setup complete!"
echo ""
echo "📂 Location: $VERSION_DIR"
echo "🌿 Branch: $BRANCH_NAME"
echo ""
echo "🔧 Next steps:"
echo "   cd $VERSION_DIR"
echo "   pio run -e sp530e        # Test build"
echo "   git add . && git commit -m 'Initial SP530E $NEW_VERSION setup'"
echo "   git push -u origin $BRANCH_NAME"
echo ""
echo "📋 To switch between versions:"
echo "   cd $BASE_DIR/wled-v0.15.x-sp530e    # Old version"
echo "   cd $BASE_DIR/wled-${NEW_VERSION}-sp530e     # New version"