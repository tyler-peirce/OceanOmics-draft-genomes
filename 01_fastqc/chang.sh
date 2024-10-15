#!/bin/bash

# Define the directories pattern and the replacement string
dir_pattern="OG*/fastp/*.json.tsv"
search_string="ilmn"
replace_string="NOVA_240716_AMD"

# Find all .tsv files in the specified directories and perform the replacement
for file in $dir_pattern; do
    if [[ -f "$file" ]]; then
        echo "Processing $file..."
        sed -i "s/$search_string/$replace_string/g" "$file"
    else
        echo "No .tsv files found in the specified pattern: $dir_pattern"
    fi
done

echo "Replacement complete."
