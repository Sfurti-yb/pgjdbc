#!/bin/bash
# Auto-continue rebase, resolving version conflicts automatically
while true; do
  git add -A
  output=$(git rebase --continue 2>&1)
  echo "$output"

  if echo "$output" | grep -q "Successfully rebased"; then
    echo "Rebase completed successfully!"
    exit 0
  fi

  if echo "$output" | grep -q "CONFLICT.*gradle.properties"; then
    # Version conflict - keep upstream version
    sed -i '/^<<<<<<< HEAD$/,/^>>>>>>> /{
      /^<<<<<<< HEAD$/{ n; s/.*/pgjdbc.version=42.7.13/; b done }
      /^=======$/,/^>>>>>>> /d
      :done
    }' gradle.properties
    echo "Auto-resolved version conflict in gradle.properties"
  else
    echo "Non-version conflict detected, exiting"
    exit 1
  fi
done
