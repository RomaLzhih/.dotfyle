#!/bin/bash

executable=$1
required_version=$2

# Check if the executable is available
if ! command -v "$executable" &>/dev/null; then
    echo ">>>>> Executable $executable not found..."
    exit 1
fi

# Get the version of the executable
current_version=$("$executable" --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
if [ -z "$current_version" ]; then
    current_version=$("$executable" --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+')
    if [ -z "$current_version" ]; then
        echo ">>>>> Could not determine the version of $executable..."
        exit 2
    fi
fi

# Compare the versions
if [ "$(printf '%s\n' "$required_version" "$current_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo ">>>>> Version $required_version of $executable required, but found $current_version..."
    exit 1
fi

echo ">>>>> Executable $executable found with version $current_version..."
exit 0
