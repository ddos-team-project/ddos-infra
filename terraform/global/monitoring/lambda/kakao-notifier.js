exports.handler = async (event) => {
  console.log("Received SNS event:", JSON.stringify(event, null, 2));

  // TODO: 카카오 API 호출 로직 추가 (Access Token/Template ID 등 필요)
  // const apiUrl = process.env.KAKAO_API_URL;
  // const apiKey = process.env.KAKAO_API_KEY;
  // const channelId = process.env.KAKAO_CHANNEL_ID;
  // const templateId = process.env.KAKAO_TEMPLATE_ID;

  return {
    statusCode: 200,
    body: "ok",
  };
};
