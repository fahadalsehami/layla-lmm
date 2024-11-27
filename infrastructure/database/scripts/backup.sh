# infrastructure/database/scripts/backup.sh

#!/bin/bash

# Database backup script
set -e

# Load environment variables
source .env

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/postgresql"
S3_BUCKET="layla-app-db-backups"
DB_NAME="layla_db"

# Create backup
echo "Starting database backup..."
PGPASSWORD=$DB_PASSWORD pg_dump \
    -h $DB_HOST \
    -U $DB_USER \
    -d $DB_NAME \
    -F c \
    -b \
    -v \
    -f "${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.backup"

# Compress backup
gzip "${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.backup"

# Upload to S3
echo "Uploading backup to S3..."
aws s3 cp \
    "${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.backup.gz" \
    "s3://${S3_BUCKET}/backups/${TIMESTAMP}/"

# Cleanup old backups
find $BACKUP_DIR -type f -mtime +7 -name "*.backup.gz" -delete

echo "Backup completed successfully"