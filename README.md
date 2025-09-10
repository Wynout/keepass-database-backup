# KeePass Database Backup Script

A Bash script for creating secure, timestamped backups of KeePass database files with automatic duplicate prevention.

## What It Does

- **Automatic Backups**: Creates timestamped backups of KeePass (.kbdx) files
- **Duplicate Prevention**: Uses MD5 hashing to avoid backing up identical content
- **Flexible Configuration**: Define exact database locations to backup
- **Secure Storage**: Sets backup permissions to 600 (owner read/write only)
- **Error Handling**: Gracefully handles missing files and permission issues
- **Progress Tracking**: Shows detailed backup status with colored output

## Quick Start

### Prerequisites

- Bash shell
- `md5sum` command (pre-installed on most systems)

### Installation

```bash
chmod +x backup.sh
```

### Basic Usage

1. Edit the `KEEPASS_DATABASES` array in `backup.sh` to add your database paths
2. Run the script:

```bash
./backup.sh
```

## Configuration

### Database Paths

Define your KeePass databases in the `KEEPASS_DATABASES` array:

```bash
KEEPASS_DATABASES=(
    "/home/user/documents/keepass-personal.kbdx"
    "~/dropbox/keepass-work.kbdx"
    "/media/external/backup.kbdx"
)
```

### Custom Backup Directory

Set a custom backup directory by modifying the `BACKUP_DIR` variable in the script:

```bash
# In backup.sh, modify this line:
BACKUP_DIR="${BACKUP_DIR:-/path/to/your/custom/backup/directory}"
```

Or set it via environment variable:

```bash
export BACKUP_DIR="/mnt/external-drive/keepass-backups"
./backup.sh
```

**Examples of backup directory locations:**

- Local directory: `~/Documents/KeePass-Backups`
- External drive: `/media/user/USB-Drive/Backups`
- Network share: `/mnt/nas/keepass-backups`
- Cloud sync: `~/Dropbox/Important-Backups`

### Supported Path Formats

- **Database files**: Absolute paths, relative paths, tilde expansion, environment variables
- **Backup directory**: All path formats supported with automatic expansion

## Backup Format

Backups are saved as: `YYYY-mm-dd_keepass-{name}_md5hash.kbdx`

Example: `2025-09-09_keepass-personal_a1b2c3d4e5f6.kbdx`

## Automation on Arch Linux

### Option 1: Cron (using cronie)

1. Install cronie if not already installed:

```bash
sudo pacman -S cronie
sudo systemctl enable --now cronie
```

2. Edit crontab:

```bash
crontab -e
```

3. Add a daily backup at 2 AM:

```bash
0 2 * * * BACKUP_DIR=/path/to/custom/backup/directory /path/to/backup.sh
```

Or set it in your shell profile for all cron jobs:

```bash
# In ~/.bashrc or ~/.zshrc
export BACKUP_DIR="/path/to/custom/backup/directory"
```

### Option 2: Systemd Timer (recommended for Arch)

1. Create a systemd service file `/etc/systemd/system/keepass-backup.service`:

```ini
[Unit]
Description=KeePass Database Backup

[Service]
Type=oneshot
ExecStart=/path/to/backup.sh
User=yourusername
Environment=BACKUP_DIR=/path/to/your/custom/backup/directory
```

2. Create a timer file `/etc/systemd/system/keepass-backup.timer`:

```ini
[Unit]
Description=Run KeePass backup daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

3. Enable and start the timer:

```bash
sudo systemctl enable keepass-backup.timer
sudo systemctl start keepass-backup.timer
```

4. Check status:

```bash
systemctl list-timers --all | grep keepass
```

## Examples

### Basic Run

```bash
$ ./backup.sh
[INFO] Starting KeePass backup process
[INFO] Using backup directory: /home/user/Documents/KeePass-Backups
[INFO] Backup directory ready: /home/user/Documents/KeePass-Backups
[INFO] Processing 2 configured databases
[INFO] Creating backup: 2025-09-09_keepass-personal_a1b2c3d4.kbdx
[INFO] Backup already exists: 2025-09-09_keepass-work_f7g8h9i0.kbdx
[INFO] Processed 2 configured databases
[INFO] Backup process completed
[INFO] Processed: 2, Successful: 2, Failed: 0
```

### Error Handling

```bash
$ ./backup.sh
[ERROR] Database not found: /missing/path/database.kbdx
[INFO] Processing 2 configured databases
[INFO] Backup process completed
[INFO] Processed: 2, Successful: 1, Failed: 1
```

## Troubleshooting

- **Permission denied**: Ensure read access to source files and write access to backup directory
- **Database not found**: Verify paths in `KEEPASS_DATABASES` array
- **No databases configured**: Add paths to the `KEEPASS_DATABASES` array
- **Backup directory issues**: Check write permissions for the configured `BACKUP_DIR`
- **Custom backup directory not working**: Ensure the path exists or can be created, and you have write permissions
- **Path expansion issues**: Use absolute paths if tilde expansion fails

## Security Notes

- KeePass files are already encrypted
- Backups are created with restricted permissions (600)
- Store backups in secure locations
- Consider additional encryption for backup storage

---

## Legal Disclaimer

This KeePass backup script is provided "as is" without warranty of any kind, express or implied. While we strive to make it as reliable as a well-trained squirrel gathering nuts, we can't guarantee it will work flawlessly in every scenario – computers can be finicky, and so can users.

By using this software, you acknowledge that we're not liable for any data loss, corruption, or the mild panic that ensues when you can't remember your master password. Backups are your safety net, but they're not a magic spell against human error.

Use at your own risk, keep multiple backups, and remember: with great password power comes great responsibility. If in doubt, consult a professional (or your favorite search engine).
