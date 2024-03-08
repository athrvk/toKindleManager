#!/bin/bash


# Settings
toKindle="$TO_KINDLE"
MAX_RETRIES=2

# Function to hit an API with the correlation ID
hit_api() {
    local url=$1
    curl -s -o /dev/null -w "%{http_code}" -H "X-Correlation-ID: github:toKindleManager" "$url"
}

restart_server() {
    curl -s -o /dev/null -w "%{http_code}" \
         --request POST \
         --url "$TO_KINDLE_RESTART_URL" \
         --header 'accept: application/json' \
         --header 'authorization: Bearer $API_TOKEN'
}

# Primary API call
status_code=$(hit_api "$toKindle")

if [ "$status_code" -eq 200 ]; then
    # Success!
    echo "to kindle is up!"
fi

if [ "$status_code" -eq 503 ]; then
    # Primary API failed, try backup with retries
    for (( j=1; j<=$MAX_RETRIES; j++ )); do
        backup_status_code=$(restart_server)

        if [ "$backup_status_code" -eq 200 ]; then
            # Backup succeeded
            echo "restarting to kindle"
            break 
        fi

        if [ "$j" -eq "$MAX_RETRIES" ]; then
            echo "all retries exhausted for restarting to kindle"
        fi
    done
fi
