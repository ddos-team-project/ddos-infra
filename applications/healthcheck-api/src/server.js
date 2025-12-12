const express = require('express');
const mysql = require('mysql2/promise');
const app = express();

// 환경변수에 포트 번호가 있으면 해당 포트를 사용 (없으면 기본 포트 3000)
const PORT = process.env.PORT || 3000;

// 서비스 메타 정보
const SERVICE_NAME = process.env.SERVICE_NAME || 'ddos-noncore-api';
const APP_ENV = process.env.APP_ENV || 'dev';

// Aurora 연결 정보 (컨테이너 환경변수로 주입)
const DB_HOST = process.env.DB_HOST;
const DB_PORT = Number(process.env.DB_PORT || 3306);
const DB_NAME = process.env.DB_NAME;
const DB_USER = process.env.DB_USER;
const DB_PASSWORD = process.env.DB_PASSWORD;

const pool = mysql.createPool({
  host: DB_HOST,
  port: DB_PORT,
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
  waitForConnections: true,
  connectionLimit: 5,
  queueLimit: 0,
});

async function checkDbHealth() {
  try {
    const conn = await pool.getConnection();
    try {
      await conn.query('SELECT 1'); // 가벼운 쿼리로 상태 확인
      return { status: 'ok' };
    } finally {
      conn.release();
    }
  } catch (err) {
    return {
      status: 'error',
      message: err.code || err.message,
    };
  }
}

// /health 엔드포인트 (DB 상태 포함)
app.get('/health', async (req, res) => {
  const dbStatus = await checkDbHealth(); // DB 상태도 함께 확인

  res.json({
    status,
    service: SERVICE_NAME,
    env: APP_ENV,
    location,
    db: dbStatus,
    uptimeMs: Math.round(process.uptime() * 1000),
    timestamp: new Date().toISOString(),
  });
});

// DB를 거치지 않는 가벼운 핑 엔드포인트 (트래픽/라우팅 테스트용)
app.get('/ping', (req, res) => {
  res.json({
    status: 'ok',
    service: SERVICE_NAME,
    region: REGION,
    env: APP_ENV,
    timestamp: new Date().toISOString(),
  });
});

// 부하 테스트용 엔드포인트 (CPU 바운드)
// 예) GET /stress?seconds=30
app.get('/stress', (req, res) => {
  // 기본은 비활성화. ALLOW_STRESS=true 설정 시에만 사용 가능.
  const ALLOW_STRESS = process.env.ALLOW_STRESS === 'true';
  if (!ALLOW_STRESS) {
    return res.status(403).json({ status: 'forbidden', message: 'stress endpoint disabled' });
  }

  const seconds = Number(req.query.seconds || 10);
  if (Number.isNaN(seconds) || seconds <= 0) {
    return res.status(400).json({ status: 'bad_request', message: 'seconds must be > 0' });
  }

  const start = Date.now();
  const end = start + seconds * 1000;

  // CPU 바운드 연산으로 부하 발생
  while (Date.now() < end) {
    Math.sqrt(Math.random());
  }

  res.json({
    status: 'ok',
    elapsed_ms: Date.now() - start,
    service: SERVICE_NAME,
    region: REGION,
    env: APP_ENV,
  });
});

// 서버 동작
app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
