const express = require('express');
const cors = require('cors');
const pool = require('./config/db');

const app = express();
app.use(cors());
app.use(express.json());

// Import des routes
const authRoutes = require('./routes/auth');
const profilRoutes = require('./routes/profil');
const servicesRoutes = require('./routes/services');
const demandesRoutes = require('./routes/demandes');
const offresRoutes = require('./routes/offres');
const avisRoutes = require('./routes/avis');
const conversationsRoutes = require('./routes/conversations');
const notificationsRoutes = require('./routes/notifications');
const adminRoutes = require('./routes/admin');
const signalementsRoutes = require('./routes/signalements');

// Utilisation des routes
app.use('/api/auth', authRoutes);
app.use('/api/utilisateurs', profilRoutes);
app.use('/api/services', servicesRoutes);
app.use('/api/demandes', demandesRoutes);
app.use('/api/offres', offresRoutes);
app.use('/api/avis', avisRoutes);
app.use('/api/conversations', conversationsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api', signalementsRoutes); // pour /signalements et /admin/signalements

const PORT = 3000;
app.listen(PORT, () => console.log(`Backend démarré sur http://localhost:${PORT}`));