# infrastructure/database/scripts/restore.sh

#!/bin/bash

# Database restore script
set -e

# Load environment variables
source .env

# Configuration
BACKUP_FILE=$1
DB_NAME="layla_db"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

# Download from S3 if needed
if [[ $BACKUP_FILE == s3://* ]]; then
    echo "Downloading backup from S3..."
    aws s3 cp $BACKUP_FILE ./
    BACKUP_FILE=$(basename $BACKUP_FILE)
fi

# Decompress if needed
if [[ $BACKUP_FILE == *.gz ]]; then
    gunzip $BACKUP_FILE
    BACKUP_FILE=${BACKUP_FILE%.gz}
fi

# Restore database
echo "Starting database restore..."
PGPASSWORD=$DB_PASSWORD pg_restore \
    -h $DB_HOST \
    -U $DB_USER \
    -d $DB_NAME \
    -v \
    $BACKUP_FILE

echo "Restore completed successfully"