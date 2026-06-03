#!/bin/bash

# ==========================================
# SEKOU ASSISTANT - Setup Complet
# Installation & Configuration
# Auteur: Sekou Simballa DouKoure
# ==========================================

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║      🤖 SEKOU ASSISTANT - Installation Setup 🤖         ║
║      Sekou Simballa DouKoure                             ║
║      Plateforme d'Automatisation Intelligente             ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# ==========================================
# 1. VÉRIFICATIONS PRÉALABLES
# ==========================================

echo -e "${YELLOW}[1/10] Vérification des prérequis...${NC}"

if ! command -v node &> /dev/null; then
  echo -e "${RED}✗ Node.js non installé${NC}"
  exit 1
fi

if ! command -v python3 &> /dev/null; then
  echo -e "${RED}✗ Python3 non installé${NC}"
  exit 1
fi

if ! command -v git &> /dev/null; then
  echo -e "${RED}✗ Git non installé${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Tous les prérequis détectés${NC}"

# ==========================================
# 2. CRÉER STRUCTURE PROJET
# ==========================================

echo -e "${YELLOW}[2/10] Création de la structure du projet...${NC}"

SEKOU_HOME="$HOME/sekou-assistant-platform"
mkdir -p $SEKOU_HOME/{backend,mobile,builders,security,automation,docs}

echo -e "${GREEN}✓ Structure créée: $SEKOU_HOME${NC}"

# ==========================================
# 3. BACKEND - Node.js + Express
# ==========================================

echo -e "${YELLOW}[3/10] Installation Backend (Node.js)...${NC}"

cd $SEKOU_HOME/backend

# Package.json
cat > package.json << 'ENDPACKAGE'
{
  "name": "sekou-assistant-backend",
  "version": "1.0.0",
  "description": "SEKOU Assistant - Backend Server",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.2",
    "jsonwebtoken": "^9.0.0",
    "axios": "^1.4.0",
    "dotenv": "^16.0.3",
    "bcrypt": "^5.1.0",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "node-cron": "^3.0.2",
    "pg": "^8.9.0",
    "redis": "^4.6.5",
    "crypto": "^1.0.1"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
ENDPACKAGE

npm install

echo -e "${GREEN}✓ Backend dépendances installées${NC}"

# ==========================================
# 4. ENVIRONNEMENT (.env)
# ==========================================

echo -e "${YELLOW}[4/10] Configuration environnement...${NC}"

cat > .env << 'ENDENV'
# SEKOU ASSISTANT CONFIGURATION

# Server
PORT=3000
NODE_ENV=development
API_URL=http://localhost:3000

# JWT Security
JWT_SECRET=sekou-secret-key-2024-$(openssl rand -hex 32)
JWT_EXPIRES_IN=24h

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=sekou_db
DB_USER=sekou_user
DB_PASSWORD=sekou_pass

# Redis
REDIS_URL=redis://localhost:6379

# Payment APIs
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_secret
STRIPE_API_KEY=your_stripe_key

# Security
ENCRYPTION_KEY=$(openssl rand -hex 32)
VAULT_URL=http://localhost:8200
VAULT_TOKEN=your_vault_token

# ADB (Android)
ADB_PATH=/usr/bin/adb

# AI/ML
OPENAI_API_KEY=your_openai_key
HUGGING_FACE_API_KEY=your_hf_key

# Logging
LOG_LEVEL=info
LOG_FILE=$HOME/sekou-assistant-platform/logs/server.log
ENDENV

echo -e "${GREEN}✓ Configuration .env créée${NC}"

# ==========================================
# 5. DATABASE SETUP (PostgreSQL)
# ==========================================

echo -e "${YELLOW}[5/10] Configuration base de données...${NC}"

# Créer script d'initialisation DB
cat > init_database.sql << 'ENDSQL'
-- SEKOU ASSISTANT DATABASE

CREATE DATABASE IF NOT EXISTS sekou_db;

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  full_name VARCHAR(255),
  password_hash VARCHAR(255),
  biometric_data JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Devices table
CREATE TABLE IF NOT EXISTS devices (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  device_id VARCHAR(255) UNIQUE NOT NULL,
  device_name VARCHAR(255),
  os VARCHAR(50),
  fingerprint VARCHAR(512),
  is_trusted BOOLEAN DEFAULT false,
  last_seen TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Earnings table
CREATE TABLE IF NOT EXISTS earnings (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  source VARCHAR(100),
  amount DECIMAL(10,2),
  currency VARCHAR(3),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(50)
);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  task_name VARCHAR(255),
  task_type VARCHAR(100),
  scheduled_time TIMESTAMP,
  completed_at TIMESTAMP,
  status VARCHAR(50),
  result JSONB
);

-- Apps table
CREATE TABLE IF NOT EXISTS apps (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  app_name VARCHAR(255),
  package_id VARCHAR(255),
  version VARCHAR(50),
  apk_path VARCHAR(512),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(50)
);
ENDSQL

echo -e "${GREEN}✓ Schéma base de données préparé${NC}"

# ==========================================
# 6. DOCKER SETUP
# ==========================================

echo -e "${YELLOW}[6/10] Configuration Docker...${NC}"

cat > Dockerfile << 'ENDDOCKER'
FROM node:20-alpine

WORKDIR /app

# Installer dépendances système
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    postgresql-client

# Copier files
COPY package.json package-lock.json ./
RUN npm install

COPY . .

# Exposer port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start
CMD ["npm", "start"]
ENDDOCKER

cat > docker-compose.yml << 'ENDDOCKER_COMPOSE'
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: sekou-postgres
    environment:
      POSTGRES_DB: sekou_db
      POSTGRES_USER: sekou_user
      POSTGRES_PASSWORD: sekou_pass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init_database.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - sekou-network

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: sekou-redis
    ports:
      - "6379:6379"
    networks:
      - sekou-network

  # Backend Server
  backend:
    build: .
    container_name: sekou-backend
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: sekou_db
      DB_USER: sekou_user
      DB_PASSWORD: sekou_pass
      REDIS_URL: redis://redis:6379
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
    networks:
      - sekou-network
    volumes:
      - ./:/app
    restart: unless-stopped

volumes:
  postgres_data:

networks:
  sekou-network:
    driver: bridge
ENDDOCKER_COMPOSE

echo -e "${GREEN}✓ Docker configuré${NC}"

# ==========================================
# 7. ANDROID ADB SETUP
# ==========================================

echo -e "${YELLOW}[7/10] Configuration Android (ADB)...${NC}"

sudo apt-get update
sudo apt-get install -y android-tools-adb android-tools-fastboot

echo -e "${GREEN}✓ ADB installé${NC}"

# ==========================================
# 8. SECURITY - Vault Setup
# ==========================================

echo -e "${YELLOW}[8/10] Configuration Vault (Sécurité)...${NC}"

mkdir -p $SEKOU_HOME/security/vault

cat > $SEKOU_HOME/security/vault/init.sh << 'ENDVAULT'
#!/bin/bash

# Télécharger Vault
VAULT_VERSION="1.15.0"
wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip
unzip vault_${VAULT_VERSION}_linux_amd64.zip
sudo mv vault /usr/local/bin/

# Initialiser Vault dev server
vault server -dev

# Dans un autre terminal:
# export VAULT_ADDR='http://127.0.0.1:8200'
# export VAULT_TOKEN="your_token"
# vault secrets enable -version=2 kv
# vault kv put secret/sekou/keys bitcoin_key="..." ethereum_key="..."
ENDVAULT

chmod +x $SEKOU_HOME/security/vault/init.sh

echo -e "${GREEN}✓ Vault configuré${NC}"

# ==========================================
# 9. CRON JOBS AUTOMATISATION
# ==========================================

echo -e "${YELLOW}[9/10] Configuration Automatisation (Cron)...${NC}"

mkdir -p $SEKOU_HOME/automation

cat > $SEKOU_HOME/automation/sekou-cron.sh << 'ENDCRON'
#!/bin/bash

SEKOU_API="http://localhost:3000/api/v1"

# 08:00 - Google Play Points
0 8 * * * curl -s -X POST $SEKOU_API/automation/google-play/claim

# 10:00 - Sondages
0 10 * * * curl -s -X POST $SEKOU_API/automation/survey/complete

# 14:00 - Autres tâches
0 14 * * * curl -s -X POST $SEKOU_API/automation/tasks/execute

# 18:00 vendredi - Envoyer gains
0 18 * * 5 curl -s -X POST $SEKOU_API/finance/transfer

# 19:00 dimanche - Rapport hebdomadaire
0 19 * * 0 curl -s -X GET $SEKOU_API/finance/report > $HOME/sekou-rapport-$(date +\%Y\%m\%d).json

# Tous les jours à 23:00 - Sync cloud
0 23 * * * curl -s -X POST $SEKOU_API/sync/backup
ENDCRON

chmod +x $SEKOU_HOME/automation/sekou-cron.sh

# Ajouter à crontab
(crontab -l 2>/dev/null; cat $SEKOU_HOME/automation/sekou-cron.sh) | crontab -

echo -e "${GREEN}✓ Cron jobs configurés${NC}"

# ==========================================
# 10. DÉMARRAGE SERVICES
# ==========================================

echo -e "${YELLOW}[10/10] Démarrage des services...${NC}"

cd $SEKOU_HOME

# Démarrer Docker Compose
docker-compose up -d

echo -e "${GREEN}✓ Services lancés${NC}"

# ==========================================
# FIN INSTALLATION
# ==========================================

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗"
echo -e "║  ✅ SEKOU ASSISTANT INSTALLÉ AVEC SUCCÈS! 🎉              ║"
echo -e "╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📍 Localisation:${NC} $SEKOU_HOME"
echo ""
echo -e "${BLUE}🚀 Commandes utiles:${NC}"
echo "  • Démarrer: cd $SEKOU_HOME && docker-compose up"
echo "  • Logs: docker-compose logs -f backend"
echo "  • Tests: npm test"
echo "  • CLI: sekou-cli status"
echo ""
echo -e "${BLUE}🌐 Services:${NC}"
echo "  • Backend API: http://localhost:3000"
echo "  • PostgreSQL: localhost:5432"
echo "  • Redis: localhost:6379"
echo "  • Swagger: http://localhost:3000/api-docs"
echo ""
echo -e "${BLUE}📱 Android Setup:${NC}"
echo "  • Connecter téléphone via USB"
echo "  • adb devices (voir list)"
echo "  • npm run mobile:start"
echo ""
echo -e "${BLUE}🔑 Prochaines étapes:${NC}"
echo "  1. Configurer .env avec vos clés API"
echo "  2. Initialiser la base de données"
echo "  3. Déployer sur Android"
echo "  4. Configurer biométrie"
echo "  5. Lancer automatisation"
echo ""
echo -e "${YELLOW}Pour support/questions: sdoukoure12@gmail.com${NC}"
echo ""
