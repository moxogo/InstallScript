#!/bin/bash

MODULES_DIR="./moxogo18"

# Create the directory if it doesn't exist
mkdir -p "$MODULES_DIR"

for module_dir in "$MODULES_DIR"/*/; do
    module_name=$(basename "$module_dir")

    # Create static directory structure if it doesn't exist
    mkdir -p "$module_dir/static/description"

    # Create a default icon.png if missing
    if [ ! -f "$module_dir/static/description/icon.png" ]; then
        echo "Creating default icon for $module_name"
        cp "./static/default_icon.png" "$module_dir/static/description/icon.png" 2>/dev/null || true
    fi

    # Ensure proper permissions
    chmod -R 755 "$module_dir"

    echo "Processed module: $module_name"
done

echo "Module structure check completed"
