#!/bin/bash

# Script to merge TTL files in assets/ttl into two batches: ontology and taxonomy
# Usage: ./scripts/merge_ttl.sh [output_dir]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TTL_DIR="$PROJECT_ROOT/assets/ttl"
OUTPUT_DIR="${1:-$PROJECT_ROOT/assets/ttl}"

# Function to merge TTL files
# Extracts prefixes first (deduplicated), then combines the rest
merge_ttl_files() {
    local pattern="$1"
    local output_file="$2"
    local temp_prefixes=$(mktemp)
    local temp_content=$(mktemp)
    
    echo "Merging $pattern files into $output_file..."
    
    # Find all matching files
    local files=($TTL_DIR/$pattern)
    
    if [ ${#files[@]} -eq 0 ] || [ ! -f "${files[0]}" ]; then
        echo "No files found matching pattern: $pattern"
        rm -f "$temp_prefixes" "$temp_content"
        return 1
    fi
    
    echo "Found ${#files[@]} files to merge:"
    printf '  - %s\n' "${files[@]##*/}"
    
    # Extract and deduplicate prefixes, then extract content
    for file in "${files[@]}"; do
        # Extract @prefix and @base declarations
        grep -E '^@(prefix|base)' "$file" >> "$temp_prefixes" 2>/dev/null || true
        
        # Extract everything except prefix/base declarations and empty lines at the start
        grep -vE '^@(prefix|base)' "$file" | sed '/./,$!d' >> "$temp_content"
        echo "" >> "$temp_content"  # Add newline between files
    done
    
    # Create output file with deduplicated prefixes followed by content
    {
        # Sort and deduplicate prefixes
        sort -u "$temp_prefixes"
        echo ""
        # Add content (remove leading blank lines)
        sed '/./,$!d' "$temp_content"
    } > "$output_file"
    
    # Cleanup
    rm -f "$temp_prefixes" "$temp_content"
    
    echo "Created: $output_file"
    echo ""
}

# Create output directory if needed
mkdir -p "$OUTPUT_DIR"

# Merge ontology files
merge_ttl_files "ontology*.ttl" "$OUTPUT_DIR/ontology_merged.ttl"

# Merge taxonomy files  
merge_ttl_files "taxonomy_*.ttl" "$OUTPUT_DIR/taxonomy_merged.ttl"

echo "Done! Merged files created in: $OUTPUT_DIR"
