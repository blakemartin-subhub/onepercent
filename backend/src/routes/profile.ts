import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { parseProfile } from '../services/openai';

export const profileRouter = Router();

// Request validation schema
const parseProfileSchema = z.object({
  ocrText: z.string().min(10, 'OCR text must be at least 10 characters').max(10000),
});

/**
 * POST /v1/profile/parse
 * Parse OCR text into structured profile data
 */
profileRouter.post('/parse', async (req: Request, res: Response, next: NextFunction) => {
  try {
    // Validate request body
    const validation = parseProfileSchema.safeParse(req.body);
    if (!validation.success) {
      return res.status(400).json({
        error: 'Invalid request',
        details: validation.error.errors,
      });
    }

    const { ocrText } = validation.data;

    // Log request (without sensitive data)
    console.log(`[profile/parse] Processing ${ocrText.length} chars of OCR text`);

    // Parse profile using OpenAI
    const parsedProfile = await parseProfile(ocrText);

    // Log success
    console.log(`[profile/parse] Successfully parsed profile: ${parsedProfile.name || 'unknown'}, contentType: ${parsedProfile.contentType || 'unknown'}`);

    return res.json(parsedProfile);
  } catch (error) {
    console.error('[profile/parse] Error:', error);
    next(error);
  }
});
