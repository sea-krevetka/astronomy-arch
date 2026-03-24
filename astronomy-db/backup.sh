#!/bin/bash
# backup.sh
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/backup/backup_${TIMESTAMP}.sql"

echo "Starting backup at $(date)"
pg_dump -h $POSTGRES_HOST -U $POSTGRES_USER $POSTGRES_DB > $BACKUP_FILE
echo "Backup completed: $BACKUP_FILE"

# Удаляем бэкапы старше 7 дней
find /backup -name "backup_*.sql" -mtime +7 -delete