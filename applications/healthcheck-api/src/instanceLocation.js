const http = require('http');

const METADATA_HOST = '169.254.169.254';
let cachedLocation = null;

function imdsRequest(options, timeoutMs) {
  return new Promise((resolve, reject) => {
    const req = http.request(
      { host: METADATA_HOST, timeout: timeoutMs, ...options },
      (res) => {
        let data = '';
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            resolve(data);
          } else {
            reject(new Error(`IMDS status ${res.statusCode}`));
          }
        });
      },
    );

    req.on('error', reject);
    req.on('timeout', () => req.destroy(new Error('IMDS timeout')));
    req.end();
  });
}

async function getAz(timeoutMs = 500) {
  if (process.env.INSTANCE_AZ) return process.env.INSTANCE_AZ;

  try {
    const token = await imdsRequest(
      {
        method: 'PUT',
        path: '/latest/api/token',
        headers: { 'X-aws-ec2-metadata-token-ttl-seconds': '60' },
      },
      timeoutMs,
    );

    const az = await imdsRequest(
      {
        method: 'GET',
        path: '/latest/meta-data/placement/availability-zone',
        headers: { 'X-aws-ec2-metadata-token': token },
      },
      timeoutMs,
    );

    return az || 'unknown';
  } catch (_) {
    return 'unknown';
  }
}

function deriveRegionFromAz(az) {
  const match = az && az.match(/^([a-z]{2}-[a-z]+-\d)[a-z]$/);
  return match ? match[1] : null;
}

async function getLocation() {
  if (cachedLocation) return cachedLocation;

  const az = await getAz();
  const region = process.env.REGION || deriveRegionFromAz(az) || 'local';
  cachedLocation = { region, az };
  return cachedLocation;
}

module.exports = { getLocation };
