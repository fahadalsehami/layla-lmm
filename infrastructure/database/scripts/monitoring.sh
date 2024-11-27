# infrastructure/database/scripts/monitoring.sh

#!/bin/bash

# Database monitoring script
set -e

# Load environment variables
source .env

# Configuration
DB_NAME="layla_db"
ALERT_EMAIL="dba@yourdomain.com"

# Check connection count
check_connections() {
    local count=$(PGPASSWORD=$DB_PASSWORD psql \
        -h $DB_HOST \
        -U $DB_USER \
        -d $DB_NAME \
        -t \
        -c "SELECT count(*) FROM pg_stat_activity;")
    
    if [ $count -gt 100 ]; then
        echo "High connection count: $count" | mail -s "DB Alert: High Connections" $ALERT_EMAIL
    fi
}

# Check long-running queries
check_long_queries() {
    PGPASSWORD=$DB_PASSWORD psql \
        -h $DB_HOST \
        -U $DB_USER \
        -d $DB_NAME \
        -c "SELECT pid, now() - query_start as duration, query 
            FROM pg_stat_activity 
            WHERE state = 'active' 
            AND now() - query_start > interval '5 minutes';"
}

# Run checks
check_connections
check_long_queries
