# This script is used to back up CloudPanel-hosted sites from a VPS to a
# configurable local folder on a local backup server.
#
# This script is meant to run on the local backup server, not on the
# CloudPanel VPS itself.
#
# It is intended to work together with a custom backup job created inside
# CloudPanel. In CloudPanel, you should create a custom rsync backup job that
# stores backup files inside each site user directory, for example:
#
#   /home/<site-user>/backups
#
# This script connects from the local backup server to the CloudPanel VPS over
# SSH using an SSH key, finds all matching CloudPanel site backup folders, and
# downloads them to the local destination directory defined in LOCAL_DEST.
# It also downloads the matching htdocs folder from the same parent directory,
# so both the generated backup files and the website files are copied locally.
#
# The local folder structure is organized by the parent directory name. Example:
#
#   /home/webhost/backups   ->   <LOCAL_DEST>/webhost/backups
#   /home/webhost/htdocs    ->   <LOCAL_DEST>/webhost/htdocs
#
# Excluded system folders:
#   /home/mysql
#   /home/clp
#   /home/ubuntu
#
# The rsync command uses --delete, which means the local copy is kept in sync
# with the VPS. If a file is removed from the remote backups or htdocs folder,
# it will also be removed from the local copy during the next run.
#
# Configuration:
# - Set REMOTE_HOST to your CloudPanel VPS IP or hostname
# - Set SSH_KEY to the SSH private key used by the local backup server to connect
#   to the VPS
# - Set LOCAL_DEST to any local folder on the backup server where you want
#   backups to be stored
#
# In short:
# 1. Create a custom rsync backup job in CloudPanel that writes site backups
#    locally into /home/<site-user>/backups
# 2. Place this script on your local backup server
# 3. Set LOCAL_DEST in this script to your preferred local backup folder
# 4. Run this script from the local backup server
# 5. The script downloads all detected CloudPanel site backups and htdocs
#    folders into that local destination

#!/usr/bin/env bash
set -euo pipefail

REMOTE_USER="root"
REMOTE_HOST="77.37.125.13"
SSH_KEY="/home/madman/.ssh/id_ed25519"

# Set this to any local folder on the backup server where you want backups stored
LOCAL_DEST="/path/to/your/local/backup-folder"

EXCLUDES=("mysql" "clp" "ubuntu")

mkdir -p "$LOCAL_DEST"

SSH_OPTS=(
  -i "$SSH_KEY"
  -o BatchMode=yes
  -o StrictHostKeyChecking=accept-new
)

EXCLUDE_EXPR=""
for name in "${EXCLUDES[@]}"; do
  EXCLUDE_EXPR="$EXCLUDE_EXPR ! -path /home/$name/backups"
done

REMOTE_FIND_CMD="find /home -mindepth 2 -maxdepth 2 -type d -name backups $EXCLUDE_EXPR | sort"

mapfile -t BACKUP_DIRS < <(
  ssh "${SSH_OPTS[@]}" "${REMOTE_USER}@${REMOTE_HOST}" "$REMOTE_FIND_CMD"
)

if [ ${#BACKUP_DIRS[@]} -eq 0 ]; then
  echo "No backup folders found."
  exit 0
fi

for remote_backup_dir in "${BACKUP_DIRS[@]}"; do
  parent_dir="$(dirname "$remote_backup_dir")"
  parent_name="$(basename "$parent_dir")"
  local_parent_dir="$LOCAL_DEST/$parent_name"

  mkdir -p "$local_parent_dir"

  echo "Syncing $remote_backup_dir -> $local_parent_dir/backups/"
  mkdir -p "$local_parent_dir/backups"
  rsync -avz --delete --progress \
    -e "ssh -i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
    "${REMOTE_USER}@${REMOTE_HOST}:${remote_backup_dir}/" \
    "$local_parent_dir/backups/"

  if ssh "${SSH_OPTS[@]}" "${REMOTE_USER}@${REMOTE_HOST}" "[ -d '$parent_dir/htdocs' ]"; then
    echo "Syncing $parent_dir/htdocs -> $local_parent_dir/htdocs/"
    mkdir -p "$local_parent_dir/htdocs"
    rsync -avz --delete --progress \
      -e "ssh -i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
      "${REMOTE_USER}@${REMOTE_HOST}:${parent_dir}/htdocs/" \
      "$local_parent_dir/htdocs/"
  else
    echo "Skipping $parent_dir/htdocs (not found)"
  fi
done

echo "Done. Saved in $LOCAL_DEST"
