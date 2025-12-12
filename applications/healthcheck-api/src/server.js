const express = require('express');
const { getLocation } = require('./instanceLocation');
const { checkDbHealth } = require('./dbHealth');

const app = express();

const PORT = process.env.PORT || 3000;
const SERVICE_NAME = process.env.SERVICE_NAME || 'ddos-noncore-api';
const APP_ENV = process.env.APP_ENV || 'dev';

app.get('/health', async (req, res) => {
  const dbStatus = await checkDbHealth();
  const location = await getLocation();

  res.json({
    status: dbStatus.status === 'ok' ? 'ok' : 'degraded',
    service: SERVICE_NAME,
    env: APP_ENV,
    location,
    db: dbStatus,
    uptimeMs: Math.round(process.uptime() * 1000),
    timestamp: new Date().toISOString(),
  });
});

app.get('/ping', async (req, res) => {
  const location = await getLocation();

  res.json({
    status: 'ok',
    service: SERVICE_NAME,
    env: APP_ENV,
    location,
    timestamp: new Date().toISOString(),
  });
});

app.get('/stress', async (req, res) => {
  const ALLOW_STRESS = process.env.ALLOW_STRESS === 'true';
  if (!ALLOW_STRESS) {
    return res.status(403).json({ status: 'forbidden', message: 'stress endpoint disabled' });
  }

  const seconds = Number(req.query.seconds || 10);
  if (Number.isNaN(seconds) || seconds <= 0) {
    return res.status(400).json({ status: 'bad_request', message: 'seconds must be > 0' });
  }

  const location = await getLocation();
  const start = Date.now();
  const end = start + seconds * 1000;

  while (Date.now() < end) {
    Math.sqrt(Math.random());
  }

  res.json({
    status: 'ok',
    elapsed_ms: Date.now() - start,
    service: SERVICE_NAME,
    env: APP_ENV,
    location,
  });
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
