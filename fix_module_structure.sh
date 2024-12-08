#!/bin/bash

# Directory containing the modules
MODULES_DIR="./odoo/moxogo18"

# Create the directory if it doesn't exist
mkdir -p "$MODULES_DIR"

# Function to fix module structure
fix_module_structure() {
    local module_dir="$1"
    local module_name=$(basename "$module_dir")
    
    # Create static directory structure if it doesn't exist
    mkdir -p "$module_dir/static/description"
    
    # If icon.png doesn't exist, create a default one
    if [ ! -f "$module_dir/static/description/icon.png" ]; then
        # Create a default icon.png if missing
        echo "Creating default icon for $module_name"
        cp "./static/default_icon.png" "$module_dir/static/description/icon.png" 2>/dev/null || true
    fi
    
    # Ensure proper permissions
    chmod -R 755 "$module_dir"
}

# Process each module directory
for module_dir in "$MODULES_DIR"/*/ ; do
    if [ -d "$module_dir" ]; then
        echo "Processing module: $(basename "$module_dir")"
        fix_module_structure "$module_dir"
    fi
done

echo "Module structure check completed"
