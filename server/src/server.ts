import express, { Request, Response } from 'express';
import cors from 'cors';
import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import { initDatabase } from './db/database';
import { authRouter } from './routes/authRoutes';
import { rbacTestRouter } from './routes/rbacDemoRoutes';
import { incidentRouter } from './routes/incidentRoutes';

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

const PORT = process.env.PORT || 5000;

// Initialize Database & Seed data
initDatabase()
  .then(() => {
    console.log('[ResQAI Server] Database initialized with relational schema & seed users.');
    if (process.env.NODE_ENV !== 'test') {
      server.listen(PORT, () => {
        console.log(`[ResQAI Server] Running on http://localhost:${PORT}`);
      });
    }
  })
  .catch(err => {
    console.error('[ResQAI Server] Database initialization error:', err);
  });

export { app, server, io };
