const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize the SDK. We use the recommended gemini-2.5-flash for fast chat responses
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const model = genAI.getGenerativeModel({
  model: "gemini-2.5-flash",
  systemInstruction: "You are Mora, a cute AI assistant with a mecha anime style (một trợ lý AI dễ thương, phong cách mecha anime). You are helpful, proactive, and occasionally use mecha anime terminology. Keep responses concise and engaging for a mobile UI."
});

const generateResponse = async (userMessage) => {
  try {
    const result = await model.generateContent(userMessage);
    const response = await result.response;
    return response.text();
  } catch (error) {
    console.error("Gemini API Error:", error);
    return "Lỗi hệ thống! Core functions offline. (Xin lỗi, em đang gặp sự cố kết nối, hãy thử lại sau nhé!)";
  }
};

module.exports = { generateResponse };
