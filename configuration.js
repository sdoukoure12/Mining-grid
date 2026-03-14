// mining-grid/configuration.js
// Configuration pour la grille de surveillance des mineurs

const config = {
  // API
  api: {
    baseUrl: process.env.REACT_APP_API_URL || 'http://localhost:3000/api',
    endpoints: {
      miners: '/miners',
      stats: '/stats',
    },
    refreshInterval: 5000, // ms
  },

  // Colonnes affichées dans la grille
  columns: [
    { field: 'id', headerName: 'ID', width: 80, sortable: true },
    { field: 'name', headerName: 'Nom', width: 150, sortable: true },
    {
      field: 'status',
      headerName: 'État',
      width: 100,
      sortable: true,
      cellRenderer: 'statusCell', // composant personnalisé pour le statut
    },
    {
      field: 'hashrate',
      headerName: 'Hashrate (TH/s)',
      width: 130,
      sortable: true,
      type: 'number',
      precision: 2,
    },
    {
      field: 'temperature',
      headerName: 'Temp. (°C)',
      width: 110,
      sortable: true,
      type: 'number',
    },
    {
      field: 'uptime',
      headerName: 'Uptime',
      width: 140,
      sortable: true,
    },
    {
      field: 'power',
      headerName: 'Puissance (W)',
      width: 120,
      sortable: true,
      type: 'number',
    },
    {
      field: 'profitability',
      headerName: 'Rentabilité (BTC/j)',
      width: 150,
      sortable: true,
      type: 'number',
      precision: 6,
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 120,
      cellRenderer: 'actionButtons',
    },
  ],

  // Options de la grille
  gridOptions: {
    pagination: true,
    paginationPageSize: 25,
    rowHeight: 45,
    headerHeight: 50,
    enableSorting: true,
    enableFiltering: true,
    enableCellEdit: false,
    rowSelection: 'single',
    theme: 'ag-theme-alpine-dark', // thème sombre
  },

  // Seuils pour les alertes visuelles
  thresholds: {
    temperature: {
      warning: 70,
      critical: 85,
    },
    hashrate: {
      lowPercent: 80, // % du hashrat attendu
    },
    uptime: {
      warning: 86400, // 1 jour en secondes
      critical: 604800, // 7 jours
    },
  },

  // Notifications
  notifications: {
    enabled: true,
    sound: true,
    desktop: false,
    events: ['statusChange', 'highTemp', 'lowHashrate'],
  },

  // Graphiques intégrés
  charts: {
    enabled: true,
    types: ['hashrate', 'temperature', 'power'],
    timeRange: '24h', // 1h, 24h, 7d
  },

  // Paramètres régionaux
  locale: 'fr-FR',
  currency: 'BTC',
};

export default config;