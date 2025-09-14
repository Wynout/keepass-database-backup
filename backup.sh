#!/bin/bash

# KeePass Database Backup Script
# Creates timestamped backups with MD5 hashes to prevent duplicates

set -uo pipefail

# Configuration
# Set custom backup directory via environment variable or modify here
BACKUP_DIR="${BACKUP_DIR:-backups}"
SCRIPT_NAME="$(basename "$0")"

# KeePass databases to backup - add your database paths here
KEEPASS_DATABASES=(
    # Example entries - replace with your actual database paths
    "./example-keepass-bob.kbdx"                      # Bob's database
    "./example-keepass-kevin.kbdx"                    # Kevin's database
    "./example-keepass-stuart.kbdx"                   # Stuart's database
    # "/home/user/documents/keepass-personal.kbdx"    # Personal database
    # "/home/user/dropbox/keepass-work.kbdx"          # Work database
    # "/media/external/keepass-backup.kbdx"           # External drive
    # "~/keepass-emergency.kbdx"                      # Emergency access
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Create backup directory if it doesn't exist
create_backup_dir() {
    # Expand relative paths and tilde
    local expanded_backup_dir
    expanded_backup_dir=$(eval echo "$BACKUP_DIR" 2>/dev/null || echo "$BACKUP_DIR")

    # Convert to absolute path if relative
    if [[ "$expanded_backup_dir" != /* ]]; then
        expanded_backup_dir="$(cd "$(dirname "$expanded_backup_dir")" 2>/dev/null && pwd)/$(basename "$expanded_backup_dir")" 2>/dev/null || expanded_backup_dir
    fi

    # Update BACKUP_DIR with expanded path
    BACKUP_DIR="$expanded_backup_dir"

    log_info "Using backup directory: $BACKUP_DIR"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_info "Creating backup directory: $BACKUP_DIR"
        if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
            log_error "Failed to create backup directory: $BACKUP_DIR"
            exit 1
        fi
        chmod 755 "$BACKUP_DIR"
    fi

    # Verify we can write to the backup directory
    if [[ ! -w "$BACKUP_DIR" ]]; then
        log_error "Cannot write to backup directory: $BACKUP_DIR"
        log_error "Please check permissions or choose a different location"
        exit 1
    fi

    log_info "Backup directory ready: $BACKUP_DIR"
}

# Extract name from KeePass filename
# keepass-bob.kbdx -> bob
extract_name() {
    local filename="$1"
    local basename=$(basename "$filename" .kbdx)

    # Remove keepass- prefix if present
    if [[ "$basename" == keepass-* ]]; then
        echo "${basename#keepass-}"
    else
        echo "$basename"
    fi
}

# Calculate MD5 hash with error handling
calculate_md5() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    if [[ ! -r "$file" ]]; then
        log_error "Cannot read file: $file"
        return 1
    fi

    local hash
    if ! hash=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1); then
        log_error "Failed to calculate MD5 for: $file"
        return 1
    fi

    # Validate hash format (should be 32 hex characters)
    if [[ ! "$hash" =~ ^[a-f0-9]{32}$ ]]; then
        log_error "Invalid MD5 hash format for: $file"
        return 1
    fi

    echo "$hash"
    return 0
}

# Get file modification date in YYYY-mm-dd format
get_mod_date() {
    local file="$1"
    local date

    if ! date=$(date -r "$file" +"%Y-%m-%d_%H-%M-%S" 2>/dev/null); then
        log_error "Failed to get modification date for: $file"
        return 1
    fi

    echo "$date"
}

# Create backup for a single file
create_backup() {
    local source_file="$1"
    local name
    local mod_date
    local hash
    local backup_filename
    local backup_path

    log_info "Processing: $source_file"

    # Extract name from filename
    name=$(extract_name "$source_file")
    if [[ -z "$name" ]]; then
        log_error "Could not extract name from: $source_file"
        return 1
    fi

    # Get modification date
    if ! mod_date=$(get_mod_date "$source_file"); then
        return 1
    fi

    # Calculate MD5 hash
    if ! hash=$(calculate_md5 "$source_file"); then
        return 1
    fi

    # Create backup filename
    backup_filename="${mod_date}_keepass-${name}_${hash}.kbdx"
    backup_path="${BACKUP_DIR}/${backup_filename}"

    # Check if backup already exists
    if [[ -f "$backup_path" ]]; then
        log_info "Backup already exists: $backup_filename"
        return 0
    fi

    # Create the backup
    log_info "Creating backup: $backup_filename"
    if cp "$source_file" "$backup_path"; then
        # Set secure permissions on backup file
        chmod 600 "$backup_path"
        log_info "Backup created successfully: $backup_filename"
    else
        log_error "Failed to create backup: $backup_filename"
        return 1
    fi
}

# Main function
main() {
    local kdbx_files
    local processed=0
    local successful=0
    local failed=0

    log_info "Starting KeePass backup process"

    # Create backup directory
    create_backup_dir

    # Process configured KeePass databases
    local db_count=0

    if [[ ${#KEEPASS_DATABASES[@]} -eq 0 ]]; then
        log_error "No KeePass databases configured in KEEPASS_DATABASES array"
        log_info "Please add your database paths to the KEEPASS_DATABASES array in the script"
        exit 1
    fi

    log_info "Processing ${#KEEPASS_DATABASES[@]} configured databases"

    # Process each configured database
    for db_path in "${KEEPASS_DATABASES[@]}"; do
        ((db_count++))
        ((processed++))

        # Skip empty entries
        [[ -z "$db_path" ]] && continue

        # Skip comments (lines starting with #)
        [[ "$db_path" =~ ^[[:space:]]*# ]] && continue

        # Expand path (handle ~ and relative paths)
        expanded_path=$(eval echo "$db_path" 2>/dev/null || echo "$db_path")

        # Validate file exists
        if [[ ! -f "$expanded_path" ]]; then
            log_error "Database not found: $expanded_path"
            ((failed++))
            continue
        fi

        # Validate file is readable
        if [[ ! -r "$expanded_path" ]]; then
            log_error "Cannot read database: $expanded_path"
            ((failed++))
            continue
        fi

        # Process the backup
        if create_backup "$expanded_path"; then
            ((successful++))
        else
            ((failed++))
        fi
    done

    if [[ $db_count -eq 0 ]]; then
        log_warn "No valid databases found in configuration"
        exit 1
    fi

    log_info "Processed $db_count configured database(s)"

    # Summary
    log_info "Backup process completed"
    log_info "Processed: $processed, Successful: $successful, Failed: $failed"

    if [[ $failed -gt 0 ]]; then
        exit 1
    fi
}

# Run main function
main "$@"


