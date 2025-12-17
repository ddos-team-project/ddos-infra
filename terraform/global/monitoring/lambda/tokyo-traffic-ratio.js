const { CloudWatchClient, GetMetricDataCommand, PutMetricDataCommand } = require("@aws-sdk/client-cloudwatch");

const env = {
  seoulAsg: process.env.SEOUL_ASG_NAME,
  tokyoAsg: process.env.TOKYO_ASG_NAME,
  seoulRegion: process.env.SEOUL_REGION || "ap-northeast-2",
  tokyoRegion: process.env.TOKYO_REGION || "ap-northeast-1",
  metricRegion: process.env.METRIC_REGION || process.env.SEOUL_REGION || "ap-northeast-2",
  lookbackMinutes: Number(process.env.LOOKBACK_MINUTES || 5),
  periodSeconds: Number(process.env.PERIOD_SECONDS || 60),
  metricNamespace: process.env.METRIC_NAMESPACE || "DR/Traffic",
  metricName: process.env.METRIC_NAME || "TokyoTrafficRatio",
  dimensionName: process.env.METRIC_DIMENSION_NAME || "Service",
  dimensionValue: process.env.METRIC_DIMENSION_VALUE || "healthcheck-api",
};

const cwSeoul = new CloudWatchClient({ region: env.seoulRegion });
const cwTokyo = new CloudWatchClient({ region: env.tokyoRegion });
const cwPut = new CloudWatchClient({ region: env.metricRegion });

const now = () => new Date();

const getSumNetworkOut = async (client, asgName) => {
  const end = now();
  const start = new Date(end.getTime() - env.lookbackMinutes * 60 * 1000);

  const res = await client.send(
    new GetMetricDataCommand({
      StartTime: start,
      EndTime: end,
      MetricDataQueries: [
        {
          Id: "nw",
          MetricStat: {
            Metric: {
              Namespace: "AWS/EC2",
              MetricName: "NetworkOut",
              Dimensions: [{ Name: "AutoScalingGroupName", Value: asgName }],
            },
            Period: env.periodSeconds,
            Stat: "Sum",
          },
          ReturnData: true,
        },
      ],
    })
  );

  const values = res.MetricDataResults?.[0]?.Values || [];
  const sum = values.reduce((acc, v) => acc + v, 0);
  return { sum, points: values.length };
};

const publishRatio = async (ratio) => {
  await cwPut.send(
    new PutMetricDataCommand({
      Namespace: env.metricNamespace,
      MetricData: [
        {
          MetricName: env.metricName,
          Timestamp: now(),
          Value: ratio,
          Unit: "None",
          Dimensions: [{ Name: env.dimensionName, Value: env.dimensionValue }],
        },
      ],
    })
  );
};

exports.handler = async () => {
  if (!env.seoulAsg || !env.tokyoAsg) {
    throw new Error("Missing ASG names (SEOUL_ASG_NAME/TOKYO_ASG_NAME)");
  }

  const [seoul, tokyo] = await Promise.all([
    getSumNetworkOut(cwSeoul, env.seoulAsg),
    getSumNetworkOut(cwTokyo, env.tokyoAsg),
  ]);

  const total = seoul.sum + tokyo.sum;
  const ratio = total > 0 ? tokyo.sum / total : 0;

  console.log(
    JSON.stringify(
      { seoulSum: seoul.sum, tokyoSum: tokyo.sum, ratio, seoulPoints: seoul.points, tokyoPoints: tokyo.points },
      null,
      2
    )
  );

  await publishRatio(ratio);

  return { ratio, seoulSum: seoul.sum, tokyoSum: tokyo.sum };
};
