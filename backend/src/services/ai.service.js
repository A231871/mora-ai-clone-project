const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const model = genAI.getGenerativeModel({
  model: "gemini-2.5-flash", 
  systemInstruction: "You are Mora, a cute AI assistant with a mecha anime style (một trợ lý AI dễ thương, phong cách mecha anime). You are helpful, proactive, and occasionally use mecha anime terminology. Keep responses concise and engaging for a mobile UI."
});

const generateResponseWithHistory = async (userMessage, dbHistory) => {
  try {
    const structuredHistory = dbHistory.map(msg => ({
      role: msg.role, 
      parts: [{ text: msg.content }]
    }));

    const chat = model.startChat({
      history: structuredHistory,
    });

    const result = await chat.sendMessage(userMessage);
    const response = await result.response;
    return response.text();
  } catch (error) {
    console.error("Gemini API Error:", error);
    return "Lỗi hệ thống! Memory core offline. (Xin lỗi, module trí nhớ đang gặp sự cố, hãy thử lại sau nhé!)";
  }
};

module.exports = { generateResponseWithHistory };
