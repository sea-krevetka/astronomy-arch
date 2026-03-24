#!/bin/bash

# Настройки
BACKUP_DIR="/var/backups/postgresql"
DATABASE="astronomy_catalog"
USER="astronomy_admin"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DATABASE}_${DATE}.sql.gz"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

echo "Starting backup of database ${DATABASE} at $(date)"

# Создаем бэкап
pg_dump -U ${USER} -d ${DATABASE} -h localhost | gzip > ${BACKUP_FILE}

# Проверяем успешность создания бэкапа
if [ $? -eq 0 ]; then
    echo "Backup created successfully: ${BACKUP_FILE}"
    
    # Удаляем старые бэкапы
    find ${BACKUP_DIR} -name "${DATABASE}_*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete
    echo "Removed backups older than ${RETENTION_DAYS} days"
else
    echo "ERROR: Backup failed!"
    exit 1
fi

echo "Backup completed at $(date)"