const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');

const targetUrl = process.env.TARGET_URL;

exports.handler = async () => {
  if (!targetUrl) {
    throw new Error('TARGET_URL is not set');
  }

  const requestOptions = {
    method: 'GET',
    uri: targetUrl,
    headers: {
      'User-Agent': 'cloudwatch-synthetics-healthcheck'
    },
    timeout: 10000
  };

  log.info(`Checking ${targetUrl}`);

  await synthetics.executeHttpStep('healthcheck', requestOptions, async (response) => {
    const statusCode = response.statusCode;
    if (statusCode < 200 || statusCode >= 400) {
      throw new Error(`Unexpected status code ${statusCode}`);
    }
  });
};
