Server Tools - Backup & Shutdown Helpers

Overview

This folder contains safe, server-oriented helper scripts intended as utilities
for administrators of the Aegis project. They are NOT wired into CI/workflows
and are intended as manual tools or to be run by an operator with proper
credentials.

Files

- `BackupManager.swift` - archives specified paths, encrypts the archive
  using GPG symmetric encryption (AES256), and can optionally upload the
  encrypted archive to a configured endpoint. Requires `gpg` and `tar`.

- `ShutdownHelper.swift` - provides a small CLI to stop services via
  `systemctl` (when available), signal processes by name, flush filesystem
  buffers, and send a simple admin notification to a webhook. Intended to
  perform graceful shutdown operations only.

Security & Usage Notes

- These helpers are intentionally conservative: they do NOT delete, hide, or
  irreversibly alter user data.
- Always review scripts and provide strong secrets (passphrases, API tokens)
  via secure secret stores or environment variables. Do NOT embed secrets in
  source control.
- `BackupManager.swift` expects `BACKUP_PASSPHRASE` to be set in the
  environment (or use your GPG agent). For uploads set `BACKUP_UPLOAD_URL`
  and `BACKUP_API_TOKEN`.
- Test these tools in a non-production environment first.

Example usage

Create an encrypted backup of `/var/data`:

```bash
export BACKUP_PASSPHRASE="..."
export BACKUP_UPLOAD_URL="https://backup.example.com/upload"  # optional
export BACKUP_API_TOKEN="..."                                # optional
./server-tools/BackupManager.swift /var/data /etc/aegis
```

Gracefully stop services:

```bash
./server-tools/ShutdownHelper.swift stop aegis-backend aegis-worker
```

If you want me to add a small systemd unit or an example script that runs
these tools under a controlled operator workflow, I can add that next.
