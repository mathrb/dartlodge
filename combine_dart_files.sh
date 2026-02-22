#!/bin/bash

# Script to combine all Dart files from lib/ and test/ directories
# Outputs to a single file with file paths as separators

OUTPUT_FILE="all_dart_files_combined.txt"

# Clear the output file if it exists
echo "# Combined Dart Files Content" > "$OUTPUT_FILE"
echo "# Generated: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Find all Dart files in lib/ and test/ directories, sorted alphabetically
find lib/ test/ -name "*.dart" -type f | sort | while read -r file; do
    echo "-- $file --" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

echo "Combined Dart files written to: $OUTPUT_FILE"