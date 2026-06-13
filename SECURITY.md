# Security Policy

## Environment Setup

Never commit secrets or credentials to version control.

### Quick Start

```bash
# Copy the environment template
cp .env.example .env

# Edit with your actual credentials
nano .env

# Install dependencies and start
npm install
npm start
```

### Environment Variables

| Variable | Description | Example |
|---|---|---|
| `MONGO_URI` | MongoDB connection string | `mongodb://user:pass@host:27017/db` |
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Runtime environment | `development` or `production` |
| `REACT_APP_API_URL` | Frontend API base URL | `http://localhost:3000/api` |
| `LOG_LEVEL` | Logging verbosity | `debug` or `info` |

## MongoDB Connection Security

- Use a dedicated database user with the minimum required permissions.
- Do not use the MongoDB admin user for the application.
- Enable authentication on your MongoDB instance.
- Use TLS/SSL for connections in production (`mongodb+srv://` handles this automatically on Atlas).
- Restrict network access to trusted IP addresses.

### Production Connection String Format

```
MONGO_URI=mongodb+srv://user:password@cluster.mongodb.net/mining_grid
```

See `.env.prod.example` for a full production template.

## Deployment Checklist

- [ ] `.env` is listed in `.gitignore` and never committed
- [ ] Credentials are stored only in `.env` (local) or a secrets manager (production)
- [ ] MongoDB authentication is enabled
- [ ] A least-privilege database user is used
- [ ] TLS/SSL is enforced for MongoDB connections in production
- [ ] `NODE_ENV=production` is set in production
- [ ] Log level is set to `info` or higher in production
- [ ] Access logs are reviewed regularly

## Monitoring Guidelines

- Set `LOG_LEVEL=info` (or `warn`) in production to reduce noise.
- Monitor failed authentication attempts in MongoDB logs.
- Set up alerts for unexpected connection failures or spikes in errors.

## Reporting a Vulnerability

If you discover a security vulnerability, please open a private issue or contact the maintainer directly. Do not disclose vulnerabilities publicly until they have been addressed.
