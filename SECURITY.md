# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please open a private issue or contact the maintainer directly. Do **not** disclose security issues publicly until they have been addressed.

---

## Setup Instructions

### 1. Configure Environment Variables

Never hardcode credentials in source code. Use environment variables instead.

```bash
# Copy the example file and fill in your own values
cp .env.example .env
```

Edit `.env` with your actual credentials:

```
PORT=3000
NODE_ENV=development
MONGO_URI=mongodb://your_user:your_password@your_host:27017/mining_grid
MONGO_DB=mining_grid
JWT_SECRET=your_jwt_secret_min_32_chars
API_KEY=your_api_key_here
```

> **Important:** Never commit `.env` to version control. It is already listed in `.gitignore`.

---

### 2. Database Connection Security

- Use a dedicated MongoDB user with the minimum required permissions (read/write on the app database only).
- Restrict network access: allow connections only from trusted IP addresses.
- Use TLS/SSL for MongoDB connections in production (`?ssl=true&authSource=admin`).
- Rotate database passwords regularly and update `.env` accordingly.

Example production URI:

```
MONGO_URI=mongodb+srv://user:password@cluster.mongodb.net/mining_grid?retryWrites=true&w=majority
```

---

### 3. Rules for Developers

- **Never** commit `.env` or any file containing real credentials.
- **Never** hardcode passwords, API keys, or secrets in source code.
- Use `.env.example` as the only committed environment template (placeholder values only).
- If a secret is accidentally committed, rotate it immediately and purge it from git history.

---

### 4. Deployment Checklist

Before deploying to production:

- [ ] All secrets are stored in the hosting platform's environment variable system (Heroku Config Vars, Vercel Environment Variables, AWS SSM/Secrets Manager, etc.).
- [ ] `.env` is **not** included in the Docker image or deployment artifact.
- [ ] MongoDB user has the minimum required permissions.
- [ ] TLS/SSL is enabled for the database connection.
- [ ] `NODE_ENV` is set to `production`.
- [ ] `JWT_SECRET` is a cryptographically random string of at least 32 characters.
- [ ] All default or example passwords have been replaced.

---

### 5. Emergency: Exposed Credentials

If credentials have been exposed in a public repository:

1. **Immediately rotate** the affected password or API key.
2. Revoke and regenerate all related tokens.
3. Purge the secret from git history using [`git filter-repo`](https://github.com/newren/git-filter-repo) (recommended):
   ```bash
   pip install git-filter-repo
   git filter-repo --path .env --invert-paths
   git push origin --force --all
   ```
   Alternatively, with the older `git filter-branch`:
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch .env" \
     --prune-empty --tag-name-filter cat -- --all
   git push origin --force --all
   ```
4. Notify affected services and review access logs for unauthorized activity.
