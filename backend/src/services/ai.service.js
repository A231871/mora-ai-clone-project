const { GoogleGenerativeAI } = require('@google/generative-ai');

const DEFAULT_GEMINI_MODELS = ['gemini-2.0-flash', 'gemini-2.5-flash'];

const getGeminiClient = () => {
  const apiKey = process.env.GEMINI_API_KEY?.trim();
  if (!apiKey) {
    return null;
  }

  return new GoogleGenerativeAI(apiKey);
};

const getGeminiModelCandidates = () => {
  const configuredModel = process.env.GEMINI_MODEL?.trim();
  return [...new Set([configuredModel, ...DEFAULT_GEMINI_MODELS].filter(Boolean))];
};

const getAiRuntimeSummary = () => {
  // The server prints a safe runtime summary at boot so we can debug
  // configuration problems without logging the full API key.
  const apiKey = process.env.GEMINI_API_KEY?.trim() ?? '';
  return {
    keyLoaded: apiKey.length > 0,
    keySuffix: apiKey.length >= 6 ? apiKey.slice(-6) : apiKey,
    models: getGeminiModelCandidates(),
  };
};

const isModelCandidateError = (error) => {
  const rawMessage = [
    error?.message,
    error?.statusText,
    error?.stack,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    Number(error?.status) === 404 ||
    /not found|unsupported|not supported|invalid model|unknown model|does not support/i.test(
      rawMessage,
    )
  );
};

const getLocalizedAiFailure = (lang = 'en', error = null, context = {}) => {
  // Instead of exposing raw provider errors to the UI, we convert them into
  // actionable, localized backend diagnostics.
  const rawMessage = [
    error?.message,
    error?.statusText,
    error?.stack,
  ]
    .filter(Boolean)
    .join(' ');

  const keyMissing = !process.env.GEMINI_API_KEY?.trim();
  const leakedKey =
    /reported as leaked|api key was reported as leaked|key was reported as leaked/i.test(
      rawMessage,
    );
  const forbidden =
    Number(error?.status) === 403 || /\b403\b|forbidden/i.test(rawMessage);
  const modelInvalid = isModelCandidateError(error);
  const networkIssue =
    !forbidden &&
    !modelInvalid &&
    /fetch|network|timed out|econnreset|econnrefused|enotfound/i.test(
      rawMessage,
    );

  const modelHint = context.modelName
    ? ` Current model: ${context.modelName}.`
    : '';
  const modelListHint = context.models?.length
    ? ` Candidate models: ${context.models.join(', ')}.`
    : '';

  if (keyMissing) {
    return {
      code: 'gemini_key_missing',
      userMessage:
        '[ SYSTEM ] Chat is offline because GEMINI_API_KEY is missing on the backend.',
      alertMessage:
        'The backend is missing GEMINI_API_KEY. Add a valid Gemini key to the environment and restart the server.',
    };
  }

  if (leakedKey) {
    return {
      code: 'gemini_key_leaked',
      userMessage:
        '[ SYSTEM ] Gemini rejected the backend key because it was marked as leaked.',
      alertMessage:
        'Google revoked the backend Gemini key as leaked. Create a brand new key, update GEMINI_API_KEY, and restart the backend process.' +
        modelHint,
    };
  }

  if (forbidden) {
    return {
      code: 'gemini_forbidden',
      userMessage:
        '[ SYSTEM ] Gemini returned 403 Forbidden for the backend request.',
      alertMessage:
        'Gemini returned 403 Forbidden. Check that the backend really restarted with the new .env, the key is allowed to use the Generative Language API, the API is enabled in Google Cloud, and the key was not already revoked.' +
        modelHint +
        modelListHint,
    };
  }

  if (modelInvalid) {
    return {
      code: 'gemini_model_invalid',
      userMessage:
        '[ SYSTEM ] Gemini rejected the selected chat model on the backend.',
      alertMessage:
        'The configured Gemini model was rejected by the API. Set GEMINI_MODEL to a supported chat model such as gemini-2.0-flash, restart the backend, and try again.' +
        modelHint +
        modelListHint,
    };
  }

  if (networkIssue) {
    return {
      code: 'gemini_network_error',
      userMessage:
        '[ SYSTEM ] The backend could not reach Gemini reliably just now.',
      alertMessage:
        'The backend could not reach Gemini reliably. Check network access or try again in a moment.' +
        modelHint,
    };
  }

  return {
    code: 'gemini_unknown_error',
    userMessage:
      '[ SYSTEM ] The chat core hit a temporary Gemini fault.',
    alertMessage:
      'Gemini returned an unknown backend error. Check the backend logs for more detail.' +
      modelHint +
      modelListHint,
  };
};

const buildReminderPrompt = () => {
  // Reminder extraction explicitly tells Gemini to convert the user’s local
  // Asia/Ho_Chi_Minh time into strict UTC for storage consistency.
  const currentLocalTime = new Intl.DateTimeFormat('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
    timeZone: 'Asia/Ho_Chi_Minh',
  }).format(new Date());

  return `You are a time-parsing system. The current local time is ${currentLocalTime} in Asia/Ho_Chi_Minh (UTC+7). Does the user's message contain a request to set a reminder or schedule a task? If yes, extract the task and calculate the future local time. Then YOU MUST convert it to strict UTC by subtracting 7 hours. Return EXACTLY this JSON format: { "isReminder": true/false, "task": "string", "time": "ISO 8601 Date string ending in Z" }. If no reminder is requested, return { "isReminder": false, "task": "", "time": "" }. Do not wrap the JSON in markdown tags.`;
};

const runWithGeminiModel = async (task) => {
  // Model fallback keeps the chat feature resilient if one candidate model
  // becomes unavailable or deprecated.
  const genAI = getGeminiClient();
  if (!genAI) {
    const summary = getAiRuntimeSummary();
    return {
      ok: false,
      failure: getLocalizedAiFailure('en', null, {
        models: summary.models,
      }),
    };
  }

  const models = getGeminiModelCandidates();
  let lastError = null;

  for (const modelName of models) {
    try {
      const result = await task(genAI, modelName);
      return {
        ok: true,
        result,
        modelName,
      };
    } catch (error) {
      lastError = error;
      if (!isModelCandidateError(error)) {
        break;
      }
    }
  }

  return {
    ok: false,
    failure: getLocalizedAiFailure('en', lastError, {
      modelName: models[0],
      models,
    }),
    error: lastError,
  };
};

const generateResponseWithHistory = async (
  userMessage,
  dbHistory,
  lang = 'en',
) => {
  const summary = getAiRuntimeSummary();
  const execution = await runWithGeminiModel(async (genAI, modelName) => {
    const languageName = lang === 'vi' ? 'Vietnamese' : 'English';
    const systemInstruction = `You are Shizuki, a cute AI assistant with a mecha anime style. CRITICAL OVERRIDE: Regardless of what you said in previous messages, you MUST NOW ALWAYS respond strictly in ${languageName}. Do not mention your language protocols, just speak in ${languageName}. Be proactive, helpful, and concise.`;

    const model = genAI.getGenerativeModel({
      model: modelName,
      systemInstruction,
    });

    let structuredHistory = dbHistory.map((msg) => ({
      role: msg.role,
      parts: [{ text: msg.content }],
    }));

    // Gemini expects clean user/model alternation, so we sanitize persisted
    // history before starting the chat session.
    while (
      structuredHistory.length > 0 &&
      structuredHistory[0].role !== 'user'
    ) {
      structuredHistory.shift();
    }

    const validHistory = [];
    let expectedRole = 'user';

    for (const msg of structuredHistory) {
      if (msg.role === expectedRole) {
        validHistory.push(msg);
        expectedRole = expectedRole === 'user' ? 'model' : 'user';
      } else if (validHistory.length > 0) {
        validHistory[validHistory.length - 1].parts[0].text += `\n[Supplement]: ${msg.parts[0].text}`;
      }
    }

    const chat = model.startChat({
      history: validHistory,
    });

    const result = await chat.sendMessage(userMessage);
    const response = await result.response;
    return response.text();
  });

  if (!execution.ok) {
    if (execution.error) {
      console.error('Gemini API Error:', execution.error);
    }
    const failure = getLocalizedAiFailure(lang, execution.error, {
      modelName: execution.failure?.modelName ?? summary.models[0],
      models: summary.models,
    });
    return {
      text: failure.userMessage,
      alertMessage: failure.alertMessage,
      isSystemError: true,
    };
  }

  return {
    text: execution.result,
    alertMessage: null,
    isSystemError: false,
  };
};

const parseReminderIntent = async (userMessage, lang = 'en') => {
  // Reminder detection is separated from normal response generation so the app
  // can turn natural language into a concrete backend record.
  const summary = getAiRuntimeSummary();
  const execution = await runWithGeminiModel(async (genAI, modelName) => {
    const model = genAI.getGenerativeModel({
      model: modelName,
      generationConfig: { responseMimeType: 'application/json' },
    });

    const result = await model.generateContent([
      buildReminderPrompt(),
      userMessage,
    ]);
    const responseText = await result.response.text();
    return JSON.parse(responseText);
  });

  if (!execution.ok) {
    if (execution.error) {
      console.error('Gemini Intent Parsing Error:', execution.error);
    }
    return {
      isReminder: false,
      systemError: getLocalizedAiFailure(lang, execution.error, {
        modelName: execution.failure?.modelName ?? summary.models[0],
        models: summary.models,
      }),
    };
  }

  return execution.result;
};

module.exports = {
  generateResponseWithHistory,
  parseReminderIntent,
  getAiRuntimeSummary,
};
