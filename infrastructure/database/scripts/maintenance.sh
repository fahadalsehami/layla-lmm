# infrastructure/database/scripts/maintenance.sh

#!/bin/bash

# Database maintenance script
set -e

# Load environment variables
source .env

# Configuration
DB_NAME="layla_db"

# Functions
vacuum_analyze() {
    echo "Running VACUUM ANALYZE..."
    PGPASSWORD=$DB_PASSWORD psql \
        -h $DB_HOST \
        -U $DB_USER \
        -d $DB_NAME \
        -c "VACUUM ANALYZE;"
}

reindex() {
    echo "Running REINDEX..."
    PGPASSWORD=$DB_PASSWORD psql \
        -h $DB_HOST \
        -U $DB_USER \
        -d $DB_NAME \
        -c "REINDEX DATABASE $DB_NAME;"
}

update_statistics() {
    echo "Updating statistics..."
    PGPASSWORD=$DB_PASSWORD psql \
        -h $DB_HOST \
        -U $DB_USER \
        -d $DB_NAME \
        -c "ANALYZE VERBOSE;"
}

# Run maintenance tasks
vacuum_analyze
reindex
update_statistics

echo "Maintenance completed successfully"