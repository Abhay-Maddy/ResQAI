import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
const envPath = fs.existsSync(path.resolve(process.cwd(), '.env'))
  ? path.resolve(process.cwd(), '.env')
  : path.resolve(process.cwd(), 'server/.env');
dotenv.config({ path: envPath });
if (!process.env.JWT_SECRET) {
  process.env.JWT_SECRET = 'resqai-dev-jwt-secret-key-2026-secure-32chars!';
}
import express, { Request, Response } from 'express';
import cors from 'cors';
import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import { initDatabase } from './db/database';
import { authRouter } from './routes/authRoutes';
import { rbacTestRouter } from './routes/rbacDemoRoutes';
import { incidentRouter } from './routes/incidentRoutes';
import { gisRouter, responderRouter } from './routes/gisRoutes';
import { reliefRouter } from './routes/reliefRoutes';
import { mlRouter } from './routes/mlRoutes';
import ngoRouter from './routes/ngoRoutes';
import campaignRouter from './routes/campaignRoutes';
import donationRouter from './routes/donationRoutes';
import caseRouter from './routes/caseRoutes';
import missingPersonRouter from './routes/missingPersonRoutes';
import smsRouter from './routes/smsRoutes';
import drillRouter from './routes/drillRoutes';
import { sitrepRouter } from './routes/sitrepRoutes';
import { alertRouter } from './routes/alertRoutes';
import { rumourRouter } from './routes/rumourRoutes';
import { evacuationRouter } from './routes/evacuationRoutes';
import { systemRouter } from './routes/systemRoutes';
import { claimRouter } from './routes/claimRoutes';
import { transparencyRouter } from './routes/transparencyRoutes';
import { volunteerRouter } from './routes/volunteerRoutes';
import { governmentRouter } from './routes/governmentRoutes';
import { researchRouter } from './routes/researchRoutes';
import { weatherRouter } from './routes/weatherRoutes';
import { notificationRouter } from './routes/notificationRoutes';

const app = express();
const server = http.createServer(app);
const io = new SocketIOServer(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

app.use(cors());
app.use(express.json());

// Mount API v1 Routes
app.use('/api/v1/auth', authRouter);
app.use('/api/v1/rbac', rbacTestRouter);
app.use('/api/v1/incidents', incidentRouter);
app.use('/api/v1/gis', gisRouter);
app.use('/api/v1/responder', responderRouter);
app.use('/api/v1/relief', reliefRouter);
app.use('/api/v1/ml', mlRouter);
app.use('/api/v1/ngos', ngoRouter);
app.use('/api/v1/campaigns', campaignRouter);
app.use('/api/v1/donations', donationRouter);
app.use('/api/v1/cases', caseRouter);
app.use('/api/v1/missing-persons', missingPersonRouter);
app.use('/api/v1/sms', smsRouter);
app.use('/api/v1/drills', drillRouter);
app.use('/api/v1/sitrep', sitrepRouter);
app.use('/api/v1/alerts', alertRouter);
app.use('/api/v1/rumours', rumourRouter);
app.use('/api/v1/evacuation', evacuationRouter);
app.use('/api/v1/system', systemRouter);
app.use('/api/v1/claims', claimRouter);
app.use('/api/v1/transparency', transparencyRouter);
app.use('/api/v1/volunteer', volunteerRouter);
app.use('/api/v1/government', governmentRouter);
app.use('/api/v1/research', researchRouter);
app.use('/api/v1/weather', weatherRouter);
app.use('/api/v1/notifications', notificationRouter);

// FR-9 Persistent emergency status & system health
app.get('/api/v1/health', (req: Request, res: Response) => {
  res.json({
    status: 'ONLINE',
    service: 'ResQAI Disaster Management API',
    version: '1.0.0',
    phase: 'Phase 1 - Auth, RBAC & DB Active',
    timestamp: new Date().toISOString(),
    truthDisclaimers: {
      emergencyCall: 'If life is in immediate danger, call 112 directly.',
      mlGating: 'ML predictions require human-in-the-loop verification.',
      demoWatermark: 'Running with watermarked synthetic seed data.'
    }
  });
});


// Serve Flutter Web frontend if build exists
const flutterWebDir = path.resolve(process.cwd(), '../build/web');
const altWebDir = path.resolve(process.cwd(), 'build/web');
const webDir = fs.existsSync(flutterWebDir) ? flutterWebDir : (fs.existsSync(altWebDir) ? altWebDir : null);

if (webDir) {
  console.log(`[ResQAI Server] Serving Flutter Web from: ${webDir}`);
  app.use(express.static(webDir));
  app.get('*', (req: Request, res: Response, next) => {
    if (req.path.startsWith('/api/') || req.path.startsWith('/socket.io/')) return next();
    res.sendFile(path.join(webDir, 'index.html'));
  });
}

const PORT = Number(process.env.PORT) || 5000;
const HOST = '0.0.0.0';

// Initialize Database & Seed data
initDatabase()
  .then(() => {
    console.log('[ResQAI Server] Database initialized with relational schema & seed users.');
    if (process.env.NODE_ENV !== 'test') {
      server.listen(PORT, HOST, () => {
        console.log(`[ResQAI Server] Running on http://${HOST}:${PORT}`);
      });
    }
  })
  .catch(err => {
    console.error('[ResQAI Server] Database initialization error:', err);
  });

export { app, server, io };
