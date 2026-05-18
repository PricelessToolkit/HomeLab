## Backup flow

This setup works in two stages:

1. `clone.sh`
   Performs a simple one-way exact clone from VMs/containers to the central backup server on the local network.

2. `rsync-snapshots.sh`
   Creates timestamped snapshots from the central backup server to the remote backup server.

3. `cloudpanel-hosts-backup.sh`
Connects from the central backup server to a CloudPanel VPS over SSH, downloads locally generated site backups.

```text
+-------------------+
| VMs / Containers  |
| "clone.sh"        |
+-------------------+
          |
          |
          v
+-------------------------------+                       
| Central Backup Server         |                         +----------------------+
| "rsync-snapshots.sh"          | --------------------->  | Remote Backup Server |
| "cloudpanel-hosts-backup.sh"  |                         +----------------------+
+-------------------------------+             
          ^
          |
          |
          |
          |
+------------------------+
|   CloudPanel VPS       | 
+------------------------+

```
# clone.sh

`clone.sh` is a simple rsync-based mirror tool for consolidating data onto a central local server.

Use it when you want to copy folders from other machines into one main storage location without snapshot retention or versioned history.

Typical flow:

`source machines -> clone.sh -> central local server -> rsync-snapshots.sh -> remote backup server`

Unlike `rsync-snapshots.sh`, this script does not create dated snapshots or retention history. It only makes the destination match the source.


# rsync-snapshots.sh

Safer snapshot backups over SSH using `rsync` + hard-linking (`--link-dest`).

This script creates timestamped remote snapshots like:

```text
2026-03-07_231512
2026-03-07_232741
2026-03-08_030000
latest -> 2026-03-08_030000
```

Each successful run creates a new snapshot directory. Unchanged files are hard-linked from the previous snapshot, so they do not get copied again in full.

## Features

- Timestamped snapshots: `YYYY-MM-DD_HHMMSS`
- Uses `rsync --link-dest` for efficient snapshot storage
- Creates `.incomplete-*` temp snapshots first, then atomically renames on success
- Keeps only the last `N` completed snapshots
- Remote lock directory to prevent concurrent runs
- Optional Telegram notifications on failure and/or success
- Safety check for required source paths before backup starts
- Optional excludes by file extension and directory name
- Optional remote free-space preflight check
- Optional auto-cleanup of stale `.incomplete-*` folders from previous failed runs
- Optional cleanup of same-name temp folder for the current run
- Portable remote finalize logic using `bash`
- Works well for unattended cron jobs

## How it works

### Snapshot flow

Each run:

1. validates local config and source paths
2. connects to the remote server over SSH
3. checks remote free space if enabled
4. acquires a remote lock
5. handles old `.incomplete-*` folders
6. creates a new remote temp snapshot:
   `.incomplete-YYYY-MM-DD_HHMMSS`
7. runs `rsync` into that temp snapshot
8. if rsync succeeds:
   - renames the temp snapshot to the final snapshot name
   - updates `latest`
   - deletes older snapshots beyond retention
9. releases the lock
10. sends Telegram notification if enabled

### Important behavior

A **new snapshot folder is created on every successful run**, even if no files changed.

This is intentional. It gives you:

- a record that the backup actually ran successfully at that time
- a clean restore point for that timestamp
- predictable retention behavior
- easier monitoring of scheduled backups

Because the script uses `--link-dest`, unchanged files are usually hard-linked from the previous snapshot, so they do not take full extra space again.

## Example snapshot layout

```text
/volume1/backup/sync/snapshots/
├── 2026-03-07_231512/
├── 2026-03-07_232741/
├── 2026-03-08_030000/
└── latest -> 2026-03-08_030000
```

If a run fails during transfer, you may see something like:

```text
.incomplete-2026-03-08_150000/
```

That directory contains the partial/incomplete snapshot for that failed run.

## Requirements

### Local machine

- `bash`
- `rsync`
- `ssh`
- `curl` (only if using Telegram)

### Remote machine

- `bash`
- `rsync`
- `mkdir`
- `mv`
- `ln`
- `rm`
- `df`
- `awk`
- `ls`
- `sed`
- `head`
- `wc`
- `readlink`

## Example config

```bash
# Local source base directory
LOCAL_BASE_DIR="/srv/backup/data/sync"

# Require these paths under LOCAL_BASE_DIR
REQUIRED_PATHS="immich"

# Remote SSH target
REMOTE_USER="root"
REMOTE_HOST="10.0.0.4"
REMOTE_PORT="22"

# Remote destination
REMOTE_BASE_DIR="/volume1/backup/sync"
REMOTE_SNAP_DIR="${REMOTE_BASE_DIR}/snapshots"

# Keep last N completed snapshots
SNAPSHOT_KEEP="10"

# Limit maximum deletions per run (0 = disabled)
MAX_DELETE="0"

# Telegram notifications
TELEGRAM_NOTIFY_ON_FAILURE="1"
TELEGRAM_NOTIFY_ON_SUCCESS="1"
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID"

# Excludes
EXCLUDE_EXTENSIONS="mp4 mp3"
EXCLUDE_DIRNAMES="pictures trash"

# Delete excluded files from destination too
DELETE_EXCLUDED="0"

# SSH keepalive
SSH_SERVER_ALIVE_INTERVAL="30"
SSH_SERVER_ALIVE_COUNT_MAX="6"

# Optional flags
ONE_FILE_SYSTEM="0"
PRESERVE_ACL_XATTR="0"
PRESERVE_SOURCE_HARDLINKS="0"
RSYNC_RESUME_PARTIAL="1"
SSH_STRICT_HOST_KEY_CHECKING="yes"

# Remote free-space checks
REMOTE_MIN_FREE_BYTES=0
REMOTE_MIN_FREE_PERCENT=""

# Incomplete snapshot handling
ALLOW_DELETE_OLD_INCOMPLETE="1"
ALLOW_DELETE_EXISTING_TMP_FOR_THIS_RUN="1"
```

## Incomplete snapshot handling

There are two separate controls:

### 1. Delete stale incomplete folders from older failed runs

```bash
ALLOW_DELETE_OLD_INCOMPLETE="1"
```

If enabled, the script automatically removes old `.incomplete-*` directories left behind by previous failed runs.

If disabled, the script refuses to continue when such directories exist.

### 2. Delete the temp folder for this exact run if it already exists

```bash
ALLOW_DELETE_EXISTING_TMP_FOR_THIS_RUN="1"
```

This only applies if the temp folder name for the current run already exists.

That is a separate case from old failed runs.

## Telegram notifications

The script can send Telegram messages on failure and/or success.

### Required settings

```bash
TELEGRAM_NOTIFY_ON_FAILURE="1"
TELEGRAM_NOTIFY_ON_SUCCESS="1"
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID"
```

### Notes

- `curl` must be installed on the local machine
- the bot must be able to message the target chat
- for private chats, start the bot first
- for groups, add the bot to the group
- use the correct numeric chat ID

## Running manually

```bash
chmod +x /home/madman/rsync-snapshots.sh
/home/madman/rsync-snapshots.sh
```

If you added:

```bash
RSYNC_OPTS=(-a --numeric-ids --delete --delete-delay --info=progress2)
```

then manual runs will show rsync progress output.

## Cron example

Run the script twice a day at `03:00` and `15:00`:

```cron
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

0 3,15 * * * /bin/bash /home/madman/rsync-snapshots.sh >/dev/null 2>&1
```

This works well if Telegram is your only alert/notification method.

## What happens if rsync fails

If `rsync` fails:

1. the script prints an error
2. it exits with the same rsync exit code
3. the `EXIT` trap runs
4. the remote lock is released
5. a Telegram failure message is sent if enabled
6. the `.incomplete-*` folder is left in place unless later cleanup removes it

The failed snapshot is **not** finalized, `latest` is **not** updated, and retention cleanup is **not** run.

## Why a new snapshot is created even if nothing changed

This is intentional.

Benefits:

- proves the backup ran successfully at that time
- gives a restore point for each scheduled run
- makes backup history easier to understand
- keeps retention simple and predictable

Because unchanged files are hard-linked from the previous snapshot, this usually costs much less space than a full copy.

## Safety notes

- do not set `LOCAL_BASE_DIR="/"`.
- use `REQUIRED_PATHS` to protect against backing up an empty or wrongly mounted source.
- keep SSH key authentication working for unattended cron jobs.
- use `MAX_DELETE` if you want extra protection against large accidental deletions.
- make sure the remote filesystem supports hard links.

## License / usage

Use, modify, and adapt for your own backup setup.
