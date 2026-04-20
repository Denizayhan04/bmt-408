#!/bin/bash
BACKUP_DIR="/home/gazi/proje/backup"
TIMESTAMP=$(date +"%F")
BACKUP_FILE="$BACKUP_DIR/db_backup_$TIMESTAMP.sql.gz"

docker exec proje-db-1 pg_dump -U user projedb | gzip > $BACKUP_FILE

find $BACKUP_DIR -type f -name "*.sql.gz" -mtime +7 -exec rm {} \;
