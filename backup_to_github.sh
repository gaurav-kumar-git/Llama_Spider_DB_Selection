#!/bin/bash

# Script to add all changes, commit, and push to origin master.

# --- Configuration ---
# You can change the default commit message here if you like.
DEFAULT_COMMIT_MESSAGE="Automated backup commit"

# Determine the branch name: use 'main' if it exists, otherwise default to 'master'.
# This is a common modern practice.
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
TARGET_BRANCH=""

if git show-ref --verify --quiet refs/heads/main; then
    TARGET_BRANCH="main"
elif git show-ref --verify --quiet refs/heads/master; then
    TARGET_BRANCH="master"
else
    # If neither main nor master exists locally, try to find the current branch or default to main
    if [ -n "$CURRENT_BRANCH" ]; then
        TARGET_BRANCH="$CURRENT_BRANCH"
        echo "Warning: Neither 'main' nor 'master' branch found. Using current branch: '$TARGET_BRANCH'"
    else
        TARGET_BRANCH="main" # Defaulting to 'main' if no branches are found (unlikely in an existing repo)
        echo "Warning: No local branches named 'main' or 'master' found, and couldn't determine current branch. Defaulting to push to 'main'. This might fail if 'main' doesn't exist on remote."
    fi
fi


# --- Optional: Allow a custom commit message from the command line ---
COMMIT_MESSAGE="$DEFAULT_COMMIT_MESSAGE"
if [ -n "$1" ]; then
    COMMIT_MESSAGE="$1"
fi

# --- Git Operations ---

# 1. Check if it's a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not a git repository. Please run this script from within a git repository."
    exit 1
fi

echo "Current Git Status:"
git status -s # Short status

# 2. Add all changes (new files, modified files, deleted files)
echo ""
echo "Adding all changes to staging area (git add .)..."
git add .
if [ $? -ne 0 ]; then
    echo "Error: 'git add .' failed. Please check for issues."
    exit 1
fi

# 3. Check if there are any changes to commit
# `git diff --staged --quiet` exits with 0 if no changes, 1 if there are changes.
# So we expect it to exit with 1 if we should proceed.
if git diff --staged --quiet; then
    echo "No changes staged for commit. Nothing to do."
    exit 0
fi

# 4. Commit the changes
echo ""
echo "Committing changes with message: \"$COMMIT_MESSAGE\""
git commit -m "$COMMIT_MESSAGE"
if [ $? -ne 0 ]; then
    echo "Error: 'git commit' failed. Please check for issues (e.g., git hooks, empty commit)."
    # Attempt to unstage if commit failed to allow user to fix
    git reset > /dev/null 2>&1
    exit 1
fi

# 5. Push the changes to origin (e.g., GitHub) on the target branch
echo ""
echo "Pushing changes to origin $TARGET_BRANCH..."
git push origin "$TARGET_BRANCH"
if [ $? -ne 0 ]; then
    echo "Error: 'git push origin $TARGET_BRANCH' failed."
    echo "Please check your remote configuration, internet connection, or permissions."
    echo "You might need to: "
    echo "  - Ensure 'origin' remote is set up correctly (git remote -v)"
    echo "  - Ensure the branch '$TARGET_BRANCH' exists on the remote or you have permission to create it."
    echo "  - Resolve any merge conflicts if the remote has diverged."
    exit 1
fi

echo ""
echo "Successfully backed up to GitHub (origin $TARGET_BRANCH)!"
exit 0