#!/bin/bash

# Auto commit dan push perubahan
echo "🔄 Checking for changes..."

# Cek apakah ada perubahan
if [ -z "$(git status --porcelain)" ]; then
    echo "✅ No changes to commit"
    exit 0
fi

# Tampilkan perubahan
echo "📝 Changes detected:"
git status --short

# Auto commit dengan timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
COMMIT_MSG="Auto commit: $TIMESTAMP"

echo "💾 Committing changes..."
git add .
git commit -m "$COMMIT_MSG"

echo "🚀 Pushing to GitHub..."
git push

echo "✅ Auto commit completed!"