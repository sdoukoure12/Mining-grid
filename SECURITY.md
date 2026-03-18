# Security Guide

## Overview

This document explains how to configure environment variables securely for the Mining Grid application.

**Never commit `.env` files or real credentials to the repository.**

---

## Setup Instructions

### 1. Clone the repository

```bash
git clone https://github.com/sdoukoure12/Mining-grid.git
cd Mining-grid
```

### 2. Create your local environment file

```bash
cp .env.example .env
```

### 3. Edit `.env` with your own values

```bash
nano .env   # or use your preferred editor
```

### 4. Install dependencies and start the server

```bash
npm install
npm run dev
```

---

## Environment Variables

| Variable        | Description                              | Example                                          |
|-----------------|------------------------------------------|--------------------------------------------------|
| `PORT`          | Port the server listens on               | `3000`                                           |
| `NODE_ENV`      | Runtime environment                      | `development` or `production`                    |
| `MONGO_URI`     | Full MongoDB connection string           | `mongodb://user:password@localhost:27017/mining_grid` |
| `DATABASE_NAME` | Name of the MongoDB database             | `mining_grid`                                    |

---

## Production Deployment

1. Copy the production template and fill in real credentials:
   ```bash
   cp .env.prod.example .env.prod
   nano .env.prod
   ```

2. Load the production environment when starting:
   ```bash
   NODE_ENV=production node server.js
   ```

3. On cloud platforms set environment variables through the platform dashboard:
   - **Heroku**: Settings → Config Vars
   - **Vercel**: Project Settings → Environment Variables
   - **AWS**: Systems Manager Parameter Store or Secrets Manager
   - **Docker**: Use `--env-file` or `-e` flags

---

## Database Backup Procedures

### Manual backup (mongodump)

```bash
mongodump --uri "$MONGO_URI" --out ./backups/$(date +%Y%m%d)
```

### Restore from backup

```bash
mongorestore --uri "$MONGO_URI" ./backups/<date>/
```

### Automated backups

Set up a cron job to run `mongodump` daily and upload the output to secure cloud storage (e.g., AWS S3, Google Cloud Storage).

---

## Credential Rotation

If credentials are ever exposed:

1. Immediately revoke or reset the exposed credentials in MongoDB Atlas (Database Access → Edit User → Reset Password).
2. Generate new credentials and update your local `.env` file.
3. Redeploy with the new credentials on your hosting platform.
4. Check git history to ensure no credentials were committed:
   ```bash
   git log --all --full-history -- ".env"
   ```
5. If credentials were committed, use `git filter-repo` or BFG Repo Cleaner to purge them from history.
