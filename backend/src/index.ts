import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

import { profileRouter } from './routes/profile';
import { messageRouter } from './routes/message';
import { errorHandler } from './middleware/errorHandler';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: '*', // In production, restrict to your app's bundle ID
  methods: ['POST', 'GET'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000'),
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'),
  message: { error: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Body parsing
app.use(express.json({ limit: '1mb' }));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Backend info endpoint (used by iOS Settings → Backend Info)
app.get('/info', (req, res) => {
  res.json({
    version: '1.0.0',
    model: 'gpt-5.2',
    environment: process.env.NODE_ENV || 'development',
  });
});

// API routes
app.use('/v1/profile', profileRouter);
app.use('/v1/message', messageRouter);

// Error handling
app.use(errorHandler);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.listen(Number(PORT), '0.0.0.0', () => {
  console.log(`🚀 OnePercent API running on port ${PORT}`);
  console.log(`   Health check: http://localhost:${PORT}/health`);
  
  // Log all network interfaces so you know what IP to use on your phone
  try {
    const os = require('os');
    const interfaces = os.networkInterfaces();
    console.log(`\n📱 Use one of these URLs in the app's Settings → Server:`);
    for (const [name, addrs] of Object.entries(interfaces)) {
      for (const addr of (addrs as any[])) {
        if (addr.family === 'IPv4' && !addr.internal) {
          console.log(`   ${name}: http://${addr.address}:${PORT}`);
        }
      }
    }
    console.log('');
  } catch {
    console.log(`\n📱 Use http://<your-local-ip>:${PORT} in the app's Settings → Server\n`);
  }
});

export default app;
