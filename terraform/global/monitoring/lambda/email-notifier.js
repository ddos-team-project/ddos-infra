const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");

const ses = new SESClient({});

const getRegion = (payload) =>
  payload.Region ||
  payload.Trigger?.Dimensions?.find((d) => d.name === "Region")?.value ||
  "Unknown";

const getMetricLine = (payload) => {
  const metric =
    payload.Trigger?.MetricName ||
    payload.Trigger?.Metrics?.[0]?.MetricStat?.Metric?.MetricName ||
    "";
  if (!metric) return "";
  const cmp = payload.Trigger?.ComparisonOperator || ">";
  const threshold =
    payload.Trigger?.Threshold ?? payload.Trigger?.Metrics?.[0]?.ReturnData
      ? payload.Trigger?.Metrics?.[0]?.Threshold
      : "";
  if (threshold === "" || threshold === undefined) return metric;
  return `${metric} ${cmp} ${threshold}`;
};

exports.handler = async (event) => {
  console.log("SNS event:", JSON.stringify(event, null, 2));

  const sender = process.env.SES_SENDER;
  const recipients = (process.env.SES_RECIPIENTS || "")
    .split(",")
    .map((s) => s.trim())
    .filter((s) => s);
  const writerHint = process.env.WRITER_HINT || "Unknown";
  const actionHint = process.env.ACTION_HINT || "Failover 검토 필요";

  if (!sender || recipients.length === 0) {
    console.error("Missing SES config (sender/recipients)");
    return;
  }

  const records = event.Records || [];
  for (const r of records) {
    const msg = r.Sns ? r.Sns.Message : "{}";
    let payload = {};
    try {
      payload = JSON.parse(msg);
    } catch {
      payload = { RawMessage: msg };
    }

    const alarmName = payload.AlarmName || "DR Alert";
    const region = getRegion(payload);
    const metricLine = getMetricLine(payload);
    const reason = payload.NewStateReason || payload.AlarmDescription || "N/A";

    const bodyLines = [
      "🚨 [CRITICAL] DR Alert",
      `Region: ${region}`,
      metricLine ? `Metric: ${metricLine}` : null,
      `Writer: ${writerHint}`,
      `Action: ${actionHint}`,
      `Reason: ${reason}`,
    ].filter(Boolean);

    const cmd = new SendEmailCommand({
      Source: sender,
      Destination: { ToAddresses: recipients },
      Message: {
        Subject: { Data: `[CRITICAL] DR Alert - ${alarmName}`, Charset: "UTF-8" },
        Body: {
          Text: { Data: bodyLines.join("\n"), Charset: "UTF-8" },
        },
      },
    });

    await ses.send(cmd);
    console.log("Sent email to", recipients);
  }

  return { statusCode: 200 };
};
