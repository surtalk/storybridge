const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const axios = require("axios");
const cors = require("cors")({ origin: true });

// Define secret
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");



exports.proxyDalleImageGet = onRequest(async (req, res) => {
  cors(req, res, async () => {
  try {
  const imageUrl = req.query.url;
  if (!imageUrl) return res.status(400).send("Missing image URL");
 
    const response = await axios.get(imageUrl, { responseType: "stream" });

    // Set CORS headers
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Content-Type", response.headers["content-type"]);

    response.data.pipe(res);  
  } catch (err) {
    console.error("Image proxy error:", err.message);
    res.status(500).send("Image proxy failed");
  }
});});


exports.proxyDalleImage = onRequest({ secrets: [OPENAI_API_KEY] }, (req, res) => {
    cors(req, res, async () => {
      try {
        const prompt = req.body.prompt;

        const response = await axios.post(
          "https://api.openai.com/v1/images/generations",
          {
            prompt: prompt,
            n: 1,
            size: "512x512",
          },
          {
            headers: {
              Authorization: `Bearer ${OPENAI_API_KEY.value()}`,
              "Content-Type": "application/json",
            },
          }
        );

        const imageUrl = response.data.data[0].url;
        res.set("Access-Control-Allow-Origin", "*");
        res.status(200).send({ imageUrl });
      } catch (error) {
        console.error(error);
        res.status(500).send({ error: "Image generation failed" });
      }
    });
  }
);


exports.proxyOpenAiText = onRequest({ secrets: [OPENAI_API_KEY] }, (req, res) => {
        cors(req, res, async () => {           
  try {
    const prompt = req.body.prompt;
    if (!prompt) {
      return res.status(400).send({ error: "Missing prompt" });
    }  

    const response = await axios.post(
      "https://api.openai.com/v1/chat/completions",
      {
        model: "gpt-3.5-turbo", // You can switch to another model if needed
        messages: [
          { role: "user", content: prompt }
        ],
        max_tokens: 60,
        temperature: 0.7,
      },
      {
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${OPENAI_API_KEY.value()}`,
        },
      }
    );
    

    const aiText = response.data.choices[0].message.content.trim();
    res.json({ text: aiText });
  } catch (error) {
    console.error(error);
    res.status(500).send({ error: "Server error" });
  }
});
});


