#!/bin/bash

# Directory to scan – adjust if needed
SCRATCH=/scratch/pawsey0964/tpeirce/_DRAFTGENOMES
SCRATCH_DIR="$SCRATCH"

# Days before purge
PURGE_DAYS=21
WARNING_DAYS=18

echo "Scanning $SCRATCH_DIR for files older than $WARNING_DAYS days..."

# Find and print files accessed more than WARNING_DAYS ago
find "$SCRATCH_DIR" -type f -printf '%A@ %p\n' | while read -r line; do
    ACCESS_TIME=$(echo "$line" | awk '{print $1}')
    FILE_PATH=$(echo "$line" | cut -d' ' -f2-)

    # Calculate days since last access
    NOW=$(date +%s)
    DAYS_AGO=$(( (NOW - ${ACCESS_TIME%.*}) / 86400 ))

    if [ "$DAYS_AGO" -ge "$WARNING_DAYS" ]; then
        echo "$DAYS_AGO days ago: $FILE_PATH"
    fi
done
