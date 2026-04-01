const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const generateResponseWithHistory = async (userMessage, dbHistory, lang = 'en') => {
  try {
    const sysInst = lang === 'vi' 
      ? "You are Shizuki, a cute AI assistant with a mecha anime style (một trợ lý AI dễ thương, phong cách mecha anime). Hãy luôn phản hồi bằng TIẾNG VIỆT, giữ phong cách thân thiện, dễ thương, hữu ích và thỉnh thoảng dùng thuật ngữ mecha anime. Trả lời ngắn gọn."
      : "You are Shizuki, a cute AI assistant with a mecha anime style. You MUST ALWAYS respond in ENGLISH. Be proactive, helpful, and occasionally use mecha anime terminology. Keep responses concise.";

    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash", 
      systemInstruction: sysInst
    });

    // 1. Transform DB history into Gemini's format
    let structuredHistory = dbHistory.map(msg => ({
      role: msg.role, 
      parts:[{ text: msg.content }]
    }));

    // 2. SANITIZE: Ensure the first message is ALWAYS a 'user' message.
    // If it starts with 'model', we drop it.
    while (structuredHistory.length > 0 && structuredHistory[0].role !== 'user') {
      structuredHistory.shift(); 
    }

    // 3. SANITIZE: Ensure roles strictly alternate (user -> model -> user)
    let validHistory =[];
    let expectedRole = 'user';
    
    for (const msg of structuredHistory) {
      if (msg.role === expectedRole) {
        validHistory.push(msg);
        expectedRole = expectedRole === 'user' ? 'model' : 'user';
      } else {
        // If we get two 'user' or two 'model' messages in a row, 
        // we merge them together to prevent Gemini from crashing.
        if (validHistory.length > 0) {
          validHistory[validHistory.length - 1].parts[0].text += `\n[Bổ sung]: ${msg.parts[0].text}`;
        }
      }
    }

    // 4. Start a continuous chat session populated with the SAFE history
    const chat = model.startChat({
      history: validHistory,
    });

    // 5. Send the newest logic into the contextual session
    const result = await chat.sendMessage(userMessage);
    const response = await result.response;
    return response.text();
  } catch (error) {
    console.error("Gemini API Error:", error);
    return "Lỗi hệ thống! Memory core offline. (Xin lỗi, module trí nhớ đang gặp sự cố, hãy thử lại sau nhé!)";
  }
};

const parseReminderIntent = async (userMessage) => {
  try {
    // Get the current real date dynamically or hardcode the project date.
    const prompt = `You are a time-parsing system. The current time is Friday, March 27, 2026, timezone Asia/Saigon (UTC+7). Does the user's message contain a request to set a reminder or schedule a task? If yes, extract the task and calculate the future local time. Then, YOU MUST convert it to strict UTC by subtracting 7 hours. Return EXACTLY this JSON format: { "isReminder": true/false, "task": "string", "time": "ISO 8601 Date string ending in Z" }. For example, if the user asks for 8:00 PM local time today, you return "2026-03-27T13:00:00.000Z". Do not wrap in markdown tags.`;
    
    // Use responseMimeType config to strictly enforce JSON
    const jsonModel = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      generationConfig: { responseMimeType: "application/json" }
    });

    const result = await jsonModel.generateContent([prompt, userMessage]);
    const responseText = await result.response.text();
    return JSON.parse(responseText);
  } catch (error) {
    console.error("Gemini Intent Parsing Error:", error);
    return { isReminder: false };
  }
};

module.exports = { generateResponseWithHistory, parseReminderIntent };
