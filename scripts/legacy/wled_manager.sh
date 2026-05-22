#!/bin/bash

# WLED SP530E Multi-Version Manager
# Manages multiple WLED versions with SP530E configurations

WORKSPACE_DIR="/workspace"

show_help() {
    echo "🚀 WLED SP530E Multi-Version Manager"
    echo "===================================="
    echo ""
    echo "Commands:"
    echo "  setup <version>     Setup new WLED version with SP530E"
    echo "  list                List all WLED-SP530E installations"
    echo "  available           Show available WLED versions"
    echo "  switch <version>    Switch to specific version directory"
    echo "  build <version>     Build specific version"
    echo "  clean <version>     Remove specific version"
    echo "  update-package      Update SP530E configuration package"
    echo ""
    echo "Version Examples:"
    echo "  v0.15.1             Latest stable release"
    echo "  v0.15.1-rc1         Release candidate"
    echo "  v0.15.1.beta1       Beta version"
    echo "  v0.14.4             Older stable"
    echo "  main                Latest development (bleeding edge)"
    echo "  0_15_x              Branch name"
    echo ""
    echo "Usage Examples:"
    echo "  ./wled_manager.sh setup v0.15.1"
    echo "  ./wled_manager.sh setup v0.15.1.beta2"
    echo "  ./wled_manager.sh setup main"
    echo "  ./wled_manager.sh available | grep v0.15"
    echo "  ./wled_manager.sh list"
    echo "  ./wled_manager.sh build v0.15.1"
}

list_versions() {
    echo "📋 Installed WLED-SP530E versions:"
    echo "================================="
    
    for dir in "$WORKSPACE_DIR"/wled-*-sp530e; do
        if [ -d "$dir" ]; then
            local version_name=$(basename "$dir")
            echo "📁 $version_name"
            if [ -f "$dir/platformio.ini" ] && grep -q "env:sp530e" "$dir/platformio.ini"; then
                echo "   ✅ SP530E configured"
            else
                echo "   ⚠️  SP530E not configured"
            fi
            
            # Show actual Git version if available
            if [ -d "$dir/.git" ]; then
                cd "$dir"
                local git_version=$(git describe --tags 2>/dev/null || git branch --show-current 2>/dev/null || echo "unknown")
                echo "   📌 Git: $git_version"
                cd "$WORKSPACE_DIR"
            fi
            echo ""
        fi
    done
}

available_versions() {
    echo "🌐 Available WLED versions (last 15):"
    echo "===================================="
    echo ""
    echo "📌 Stable Releases:"
    git ls-remote --tags upstream 2>/dev/null | \
        grep -E "refs/tags/v0\.(1[4-9]|[2-9][0-9])\.[0-9]+$" | \
        sed 's/.*refs\/tags\///' | \
        sort -V | tail -10
    
    echo ""
    echo "🧪 Beta/RC Versions:"  
    git ls-remote --tags upstream 2>/dev/null | \
        grep -E "refs/tags/v0\.(1[4-9]|[2-9][0-9]).*(-rc|-beta|\.beta)" | \
        sed 's/.*refs\/tags\///' | \
        sort -V | tail -10
        
    echo ""
    echo "🌿 Development Branches:"
    git ls-remote --heads upstream 2>/dev/null | \
        grep -E "(main|0_[0-9]+_x)" | \
        sed 's/.*refs\/heads\///' | \
        sort
        
    echo ""
    echo "💡 Usage: ./wled_manager.sh setup <version>"
    echo "   Example: ./wled_manager.sh setup v0.15.1"
}

setup_version() {
    local version=$1
    if [ -z "$version" ]; then
        echo "❌ Please specify a version"
        echo "Example: ./wled_manager.sh setup v0.16.0"
        exit 1
    fi
    
    cd "$WORKSPACE_DIR"
    ./quick_setup_wled.sh "$version"
}

switch_version() {
    local version=$1
    local target_dir="$WORKSPACE_DIR/wled-$version-sp530e"
    
    if [ ! -d "$target_dir" ]; then
        echo "❌ Version $version not found"
        echo "Available versions:"
        list_versions
        exit 1
    fi
    
    echo "🔄 Switching to WLED $version SP530E"
    cd "$target_dir"
    pwd
}

build_version() {
    local version=$1
    local target_dir="$WORKSPACE_DIR/wled-$version-sp530e"
    
    if [ ! -d "$target_dir" ]; then
        echo "❌ Version $version not found"
        exit 1
    fi
    
    echo "🔨 Building WLED $version SP530E..."
    cd "$target_dir"
    pio run -e sp530e
}

clean_version() {
    local version=$1
    local target_dir="$WORKSPACE_DIR/wled-$version-sp530e"
    
    if [ ! -d "$target_dir" ]; then
        echo "❌ Version $version not found"
        exit 1
    fi
    
    echo "🗑️  Remove $target_dir? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf "$target_dir"
        echo "✅ Removed $version"
    else
        echo "❌ Cancelled"
    fi
}

update_package() {
    echo "📦 Updating SP530E configuration package..."
    # This would sync the package from the current working version
    cd "$WORKSPACE_DIR"
    
    if [ -d "sp530e_config_package" ]; then
        echo "   🔄 Updating package from current configuration..."
        
        # Update platformio config
        grep -A 50 "\[env:sp530e\]" platformio.ini > sp530e_config_package/platformio_sp530e.ini
        
        # Update tools
        cp -r tools/* sp530e_config_package/tools/ 2>/dev/null || true
        
        # Update workflows  
        cp -r .github/* sp530e_config_package/.github/ 2>/dev/null || true
        
        echo "   ✅ Package updated"
    else
        echo "   ❌ Package directory not found"
    fi
}

# Main command dispatcher
case "$1" in
    "setup")
        setup_version "$2"
        ;;
    "list")
        list_versions
        ;;
    "available"|"avail")
        available_versions
        ;;
    "switch")
        switch_version "$2"
        ;;
    "build")
        build_version "$2"
        ;;
    "clean")
        clean_version "$2"
        ;;
    "update-package")
        update_package
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        show_help
        exit 1
        ;;
esac