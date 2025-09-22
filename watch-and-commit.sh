#!/bin/bash

# Watch file changes dan auto commit
echo "👀 Starting file watcher for auto commit..."
echo "Press Ctrl+C to stop"

while true; do
    # Tunggu perubahan file (5 detik)
    sleep 5
    
    # Cek perubahan
    if [ ! -z "$(git status --porcelain)" ]; then
        echo "🔄 Changes detected, auto committing..."
        ./auto-commit.sh
        echo "⏰ Waiting for next changes..."
    fi
done