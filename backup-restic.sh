#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/.env"

mkdir -p /home/jlatmi/services/restic/tmp/

# Backup AFFiNE Database
docker exec "$POSTGRES_CONTAINER" pg_dump --format c --file /tmp/affine.backup --username "$DB_USERNAME" --verbose "$DB_DATABASE"
docker cp "$POSTGRES_CONTAINER":/tmp/affine.backup $SCRIPT_DIR/tmp/affine.backup

# Backup AFFiNE Blobs
mkdir -p $SCRIPT_DIR/tmp/storage/
cp -r $AFFINE_DIR/storage/blobs/ $SCRIPT_DIR/tmp/storage/blobs

# Backup AFFiNE Configuration
mkdir -p $SCRIPT_DIR/tmp/config/
cp $AFFINE_DIR/config/private.key $SCRIPT_DIR/tmp/config/
cp $AFFINE_DIR/docker-compose.yml $SCRIPT_DIR/tmp/
cp $AFFINE_DIR/.env $SCRIPT_DIR/tmp/

# Save backup files
restic backup $SCRIPT_DIR/tmp

# Clean
rm -rf $SCRIPT_DIR/tmp/

# Retention
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune

# Checking backups
if [ "$(date +%u)" -eq 7 ]; then
    restic check
fi
