import express, { Request, Response } from 'express';
import cors from 'cors';
import http from 'http';
import { Server as SocketIOServer } from 'socket.io';

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

// FR-9 Persistent emergency status & system health
app.get('/api/v1/health', (req: Request, res: Response) => {
  res.json({
    status: 'ONLINE',
    service: 'ResQAI Disaster Management API',
    version: '1.0.0',
    phase: 'Phase 0 Complete',
    timestamp: new Date().toISOString(),
    truthDisclaimers: {
      emergencyCall: 'If life is in immediate danger, call 112 directly.',
      mlGating: 'ML predictions require human-in-the-loop verification.',
      demoWatermark: 'Running with watermarked synthetic seed data.'
    }
  });
});

const PORT = process.env.PORT || 5000;

if (process.env.NODE_ENV !== 'test') {
  server.listen(PORT, () => {
    console.log(`[ResQAI Server] Running on http://localhost:${PORT}`);
  });
}

export { app, server, io };
