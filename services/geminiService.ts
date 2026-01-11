import { GoogleGenAI } from "@google/genai";

// Use process.env.API_KEY directly and create instance as needed as per guidelines
export const getGeminiTicketAssistant = async (subject: string, description: string) => {
  try {
    const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
    const response = await ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: `You are a technical support assistant for a manufacturing company. 
      Analyze this ticket and provide:
      1. A very short summary (1 sentence).
      2. Suggested immediate troubleshooting steps or next questions to ask.
      3. Potential root cause based on manufacturing context.

      Subject: ${subject}
      Description: ${description}`,
      config: {
        thinkingConfig: { thinkingBudget: 0 }
      }
    });

    return response.text;
  } catch (error) {
    console.error("Gemini assistant error:", error);
    return null;
  }
};