#!/bin/bash

# Run plain make, capturing all output
make 2>&1 | tee /tmp/make_output

# Print a summary header
echo -e "\n=== Build Warnings/Errors ===\n"

# Highlight any lines that contain ERROR or warning
grep -i "error\|warning" /tmp/make_output | while IFS= read -r line; do
    if [[ $line == *ERROR* ]]; then
        echo -e "\e[31m$line\e[0m"  # Red for errors
    else
        echo -e "\e[33m$line\e[0m"  # Yellow for warnings
    fi
done

# Finally, check for warnings and exit accordingly
if grep -iq 'warning' /tmp/make_output; then
    echo -e "\n\e[33mWarnings found during build ❌\e[0m"
    rm /tmp/make_output
    exit 1
else
    echo -e "\n\e[32mSynthesized without warnings. ✓\e[0m"
    rm /tmp/make_output
    exit 0
fi
