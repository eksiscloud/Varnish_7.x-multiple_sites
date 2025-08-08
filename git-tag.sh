#!/bin/bash

# Yes. I am really, really, really bad at git.

# Be sure you are in the main
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "main" ]; then
  echo "⚠️  You aren't in main branch (now: $current_branch)."
  read -p "Do you still want to continue? (y/n) " continueanyway
  if [[ "$continueanyway" != "y" ]]; then
    echo "⛔ Abort."
    exit 1
  fi
fi

# Show current HEAD commit
echo "🔍 Current HEAD:"
git log -1 --oneline

# Give name and description of a new tag
echo ""
read -p "Give name of the tag (i.e. pre-asn-refactor-20250606): " tagname
read -p "Give short description: " tagdesc

# Create annotate tag
git tag -a "$tagname" -m "$tagdesc"
echo "✅ Tag '$tagname' created."

# Shall it send to GitHub
read -p "Do you want to send the tag to GitHub? (y/n) " pushit
if [[ "$pushit" == "y" ]]; then
  git push origin "$tagname"
  echo "📡 The tag is sended to GitHub."
else
  echo "🚫 The tag stays local."
fi
