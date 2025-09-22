#!/bin/bash

echo "💾 Database Backup"
echo "=================="

# Load environment variables
source .env

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/tms_backup_$TIMESTAMP.sql"

# Create backup directory
mkdir -p $BACKUP_DIR

# Create database backup
echo "Creating backup: $BACKUP_FILE"
docker exec tms-postgres pg_dump -U $DB_USER -d $DB_NAME > $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "✅ Backup created successfully"
    
    # Compress backup
    gzip $BACKUP_FILE
    echo "✅ Backup compressed: $BACKUP_FILE.gz"
    
    # Clean old backups (keep last 30 days)
    find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete
    echo "✅ Old backups cleaned"
else
    echo "❌ Backup failed"
    exit 1
fi