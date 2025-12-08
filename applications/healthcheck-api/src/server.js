const express = require('express');
const mysql = require('mysql2/promise'); // ✅ 이 줄 추가
const app = express();

// 환경변수에 포트 번호가 있을 경우 해당 포트 사용 (없을 경우 기본포트 3000)
const PORT = process.env.PORT || 3000;

// 환경변수에서 서비스/환경 정보 읽기 (없을 경우 기본값 사용)
const SERVICE_NAME = process.env.SERVICE_NAME || 'ddos-noncore-api';
const REGION = process.env.REGION || 'local';
const APP_ENV = process.env.APP_ENV || 'dev';

// Aurora 연결 정보 (컨테이너 생성시 입력)
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
      await conn.query('SELECT 1'); // 가벼운 쿼리 한 번
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

// /health 엔드포인트
app.get('/health', async (req, res) => {
  const dbStatus = await checkDbHealth(); // ✅ 분리한 함수 사용
  
  res.json({
    status: dbStatus.status === 'ok' ? 'ok' : 'degraded',
    service: SERVICE_NAME,
    region: REGION,
    env: APP_ENV,
    db: dbStatus,
    timestamp: new Date().toISOString(),
  });
});

// 서버 시작
app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});