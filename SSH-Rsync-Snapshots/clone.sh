#!/usr/bin/env bash
# clone.sh
#
# Simple rsync clone/mirror job for consolidating data onto a central local server.
#
# Intended use:
# - Pull or push data between machines on the local network
# - Clone folders from different devices/services into one central server
# - Prepare centralized data that is later protected by rsync-snapshots.sh
#
# This script is NOT a snapshot backup tool.
# It does not create retention points, hard-link snapshots, or backup history.
# It simply makes the destination match the source.
#
# Typical workflow:
#   source machine(s) -> clone.sh -> central local server -> rsync-snapshots.sh -> remote backup server
#
# Features:
# - rsync mirror over SSH
# - optional Telegram failure notification
# - SSH key auth for unattended cron use
# - optional ownership/permission controls
#
# SSH key setup:
#   1) Generate a key on the machine running this script:
#      ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519_clone
#
#      For cron usage, leave the passphrase empty.
#
#   2) Copy the public key to the destination server:
#      ssh-copy-id -i ~/.ssh/id_ed25519_clone.pub -p 22 user@destination-host
#
#   3) Test login:
#      ssh -i ~/.ssh/id_ed25519_clone -p 22 user@destination-host
#
#   4) If login works without a password, the script can run unattended.
#
# Trailing slash behavior:
#   LOCAL_PATH="/data/source/"
#     -> copies CONTENTS of source into destination
#
#   LOCAL_PATH="/data/source"
#     -> copies the source directory itself into destination
#
# Cron example:
#   0 2,14 * * * /root/clone.sh >> /var/log/clone.log 2>&1

set -Eeuo pipefail

# Name shown in Telegram error message
JOB_NAME="MY CLONE JOB"

# Local source directory
LOCAL_PATH="/path/to/local/source/"

# Destination SSH settings
REMOTE_USER="user"
REMOTE_HOST="example.com"
REMOTE_PORT="22"

# SSH private key used for login
SSH_KEY="/root/.ssh/id_ed25519_clone"

# Destination directory
REMOTE_PATH="/path/to/remote/destination/"

# Optional extra rsync options
# Examples:
# RSYNC_EXTRA_OPTS=(--chown=user:group --chmod=D2775,F664)
# RSYNC_EXTRA_OPTS=(--numeric-ids)
RSYNC_EXTRA_OPTS=()

# Telegram bot token from BotFather
# Leave empty to disable Telegram notifications
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

send_telegram() {
  local text="$1"

  [[ -n "${TELEGRAM_BOT_TOKEN}" ]] || return 0
  [[ -n "${TELEGRAM_CHAT_ID}" ]] || return 0
  command -v curl >/dev/null 2>&1 || return 0

  curl -fsS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${text}" \
    >/dev/null 2>&1 || true
}

on_error() {
  local exit_code="$?"
  local line_no="$1"

  send_telegram "${JOB_NAME} FAILED
Host: $(hostname)
Line: ${line_no}
Exit code: ${exit_code}
Local: ${LOCAL_PATH}
Destination: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"

  exit "$exit_code"
}

trap 'on_error $LINENO' ERR

# Check required commands exist
command -v rsync >/dev/null 2>&1 || { echo "Missing command: rsync"; exit 1; }
command -v ssh   >/dev/null 2>&1 || { echo "Missing command: ssh"; exit 1; }

# Check local source exists
if [[ ! -e "${LOCAL_PATH}" ]]; then
  echo "Local path does not exist: ${LOCAL_PATH}"
  exit 1
fi

# Check SSH private key exists
if [[ ! -f "${SSH_KEY}" ]]; then
  echo "SSH key does not exist: ${SSH_KEY}"
  exit 1
fi

# Run rsync
#
# -a   archive mode
# -H   preserve hard links
# -A   preserve ACLs
# -X   preserve extended attributes
# --delete remove files on destination that no longer exist locally
# --human-readable show readable sizes
# --info=progress2,stats2 show overall progress and final statistics

rsync \
  -aHAX \
  --delete \
  --human-readable \
  --info=progress2,stats2 \
  "${RSYNC_EXTRA_OPTS[@]}" \
  -e "ssh -i ${SSH_KEY} -p ${REMOTE_PORT} -o BatchMode=yes" \
  "${LOCAL_PATH}" \
  "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"
