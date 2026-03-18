// mining-grid/contrôler.js
// Module de contrôle pour la gestion des mineurs (actions CRUD et commandes)

import config from './configuration.js';

const API_BASE = config.api.baseUrl;
const ENDPOINTS = config.api.endpoints;

// Helper pour gérer les réponses fetch
async function handleResponse(response) {
  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.message || `Erreur HTTP ${response.status}`);
  }
  return response.json();
}

// Récupérer la liste de tous les mineurs
export async function getMiners() {
  try {
    const response = await fetch(`${API_BASE}${ENDPOINTS.miners}`);
    return await handleResponse(response);
  } catch (error) {
    console.error('Erreur lors de la récupération des mineurs :', error);
    throw error;
  }
}

// Récupérer un mineur spécifique par son ID
export async function getMinerById(id) {
  try {
    const response = await fetch(`${API_BASE}${ENDPOINTS.miners}/${id}`);
    return await handleResponse(response);
  } catch (error) {
    console.error(`Erreur lors de la récupération du mineur ${id} :`, error);
    throw error;
  }
}

// Mettre à jour les paramètres d'un mineur (ex: puissance, nom, etc.)
export async function updateMiner(id, data) {
  try {
    const response = await fetch(`${API_BASE}${ENDPOINTS.miners}/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return await handleResponse(response);
  } catch (error) {
    console.error(`Erreur lors de la mise à jour du mineur ${id} :`, error);
    throw error;
  }
}

// Redémarrer un mineur
export async function restartMiner(id) {
  try {
    const response = await fetch(`${API_BASE}${ENDPOINTS.miners}/${id}/restart`, {
      method: 'POST',
    });
    return await handleResponse(response);
  } catch (error) {
    console.error(`Erreur lors du redémarrage du mineur ${id} :`, error);
    throw error;
  }
}

// Arrêter un mineur
export async function stopMiner(id) {
  try {
    const response = await fetch(`${API_BASE}${ENDPOINTS.miners}/${id}/stop`, {
      method: 'POST',
    });
    return await handleResponse(response);
  } catch (error) {
    console.error(`Erreur lors de l'arrêt du mineur ${id} :`, error);
    throw error;
  }
}

// Démarrer un mineur
export async function startMiner(id) {
  try {
    const response = await fetch(`${API_BASE}${ENDPOINTS.miners}/${id}/start`, {
      method: 'POST',
    });
    return await handleResponse(response);
  } catch (error) {
    console.error(`Erreur lors du démarrage du mineur ${id} :`, error);
    throw error;
  }
}

// Modifier la puissance cible d'un mineur (en Watts)
export async function setPowerLimit(id, watts) {
  return updateMiner(id, { powerLimit: watts });
}

// Récupérer les statistiques globales (hashrate total, température moyenne, etc.)
export async function getGlobalStats() {
  try {
    const response = await fetch(`${API_BASE}${ENDPOINTS.stats}`);
    return await handleResponse(response);
  } catch (error) {
    console.error('Erreur lors de la récupération des stats globales :', error);
    throw error;
  }
}

// Fonction utilitaire pour rafraîchir périodiquement les données (ex: avec setInterval)
export function startAutoRefresh(callback, interval = config.api.refreshInterval) {
  const intervalId = setInterval(async () => {
    try {
      const miners = await getMiners();
      callback(miners);
    } catch (err) {
      console.warn('Échec du rafraîchissement automatique', err);
    }
  }, interval);
  return () => clearInterval(intervalId); // retourne une fonction de nettoyage
}

// Exemple d'utilisation (si ce fichier est exécuté directement, mais généralement importé)
// (facultatif, peut être supprimé en production)
if (import.meta.url === `file://${process.argv[1]}`) {
  (async () => {
    try {
      const miners = await getMiners();
      console.log('Mineurs chargés :', miners);
    } catch (e) {
      console.error(e);
    }
  })();
}