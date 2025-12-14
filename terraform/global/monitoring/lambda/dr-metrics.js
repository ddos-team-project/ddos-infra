const { RDSClient, DescribeDBClustersCommand } = require("@aws-sdk/client-rds");
const { Route53Client, ListResourceRecordSetsCommand } = require("@aws-sdk/client-route-53");
const { CloudWatchClient, PutMetricDataCommand } = require("@aws-sdk/client-cloudwatch");

const cloudwatch = new CloudWatchClient({});

const env = {
  namespace: process.env.METRIC_NAMESPACE || "DR/Health",
  dimension: process.env.METRIC_DIMENSION || "dr",
  primaryClusterId: process.env.PRIMARY_CLUSTER_ID,
  secondaryClusterId: process.env.SECONDARY_CLUSTER_ID,
  primaryRegion: process.env.PRIMARY_REGION,
  secondaryRegion: process.env.SECONDARY_REGION,
  primaryValue: Number(process.env.PRIMARY_VALUE ?? 0),
  secondaryValue: Number(process.env.SECONDARY_VALUE ?? 1),
  route53ZoneId: process.env.ROUTE53_ZONE_ID,
  route53RecordName: process.env.ROUTE53_RECORD_NAME,
};

const putMetrics = async (datapoints) => {
  if (!datapoints.length) return;
  await cloudwatch.send(
    new PutMetricDataCommand({
      Namespace: env.namespace,
      MetricData: datapoints.map((m) => ({
        MetricName: m.name,
        Timestamp: new Date(),
        Value: m.value,
        Unit: "None",
        Dimensions: [{ Name: "System", Value: env.dimension }],
      })),
    })
  );
};

const detectWriterRegion = async () => {
  const clientPrimary = new RDSClient({ region: env.primaryRegion });
  const clientSecondary = new RDSClient({ region: env.secondaryRegion });

  const describe = async (client, id) => {
    if (!id) return null;
    const res = await client.send(new DescribeDBClustersCommand({ DBClusterIdentifier: id }));
    return res?.DBClusters?.[0];
  };

  const primary = await describe(clientPrimary, env.primaryClusterId);
  const secondary = await describe(clientSecondary, env.secondaryClusterId);

  const primaryWriter = primary?.DBClusterMembers?.find((m) => m.IsClusterWriter);
  if (primaryWriter) return { region: env.primaryRegion, value: env.primaryValue };

  const secondaryWriter = secondary?.DBClusterMembers?.find((m) => m.IsClusterWriter);
  if (secondaryWriter) return { region: env.secondaryRegion, value: env.secondaryValue };

  return { region: "unknown", value: -1 };
};

const detectRoute53ActiveRegion = async () => {
  if (!env.route53ZoneId || !env.route53RecordName) return { region: "unknown", value: -1 };
  const client = new Route53Client({});
  const res = await client.send(
    new ListResourceRecordSetsCommand({
      HostedZoneId: env.route53ZoneId,
      StartRecordName: env.route53RecordName,
    })
  );

  const candidates =
    res?.ResourceRecordSets?.filter(
      (rr) => rr.Name?.replace(/\.$/, "") === env.route53RecordName && rr.Type === "A"
    ) || [];

  const failoverPrimary = candidates.find((rr) => rr.Failover === "PRIMARY");
  const failoverSecondary = candidates.find((rr) => rr.Failover === "SECONDARY");

  if (failoverPrimary) return { region: env.primaryRegion, value: env.primaryValue };
  if (failoverSecondary) return { region: env.secondaryRegion, value: env.secondaryValue };

  const weighted = candidates
    .filter((rr) => typeof rr.Weight === "number" && rr.Weight > 0)
    .sort((a, b) => (b.Weight || 0) - (a.Weight || 0));

  if (weighted.length) {
    const top = weighted[0];
    const id = (top.SetIdentifier || "").toLowerCase();
    if (id.includes("seoul") || id.includes("primary")) return { region: env.primaryRegion, value: env.primaryValue };
    if (id.includes("tokyo") || id.includes("secondary")) return { region: env.secondaryRegion, value: env.secondaryValue };
    return { region: "weighted", value: env.primaryValue };
  }

  return { region: "unknown", value: -1 };
};

exports.handler = async () => {
  try {
    const [writer, route53] = await Promise.all([detectWriterRegion(), detectRoute53ActiveRegion()]);

    await putMetrics([
      { name: "AuroraWriterRegion", value: writer.value },
      { name: "Route53ActiveRegion", value: route53.value },
      // Placeholder for DR automation runs; to be updated when automation events are wired.
      { name: "DRAutomationStatus", value: 0 },
    ]);

    return { writerRegion: writer.region, route53Region: route53.region };
  } catch (err) {
    console.error("Failed to publish DR metrics", err);
    await putMetrics([{ name: "DRAutomationStatus", value: -1 }]);
    throw err;
  }
};
