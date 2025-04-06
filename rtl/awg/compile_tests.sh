
#!/bin/bash
# Run the test and highlight errors and warnings in red/yellow while preserving all output
make sim 2>&1 | tee /tmp/test_output | while IFS= read -r line; do
    if [[ $line == *ERROR* ]]; then
        echo -e "\e[31m$line\e[0m"  # Red for errors
    elif [[ $line == *warning* ]]; then
        echo -e "\e[33m$line\e[0m"  # Yellow for warnings
    else
        echo "$line"
    fi
done

echo -e "\n=== Test Summary ===\n"

# Check for errors or warnings in the saved output
if grep -iq 'warning' /tmp/test_output; then
	echo -e "\e[33mWarnings found during synthesis ❌\e[0m"
    rm /tmp/test_output
    exit 1
else
    echo -e "\e[32mSynthesised without warnings. ✓\e[0m"
    rm /tmp/test_output
    exit 0
fi
