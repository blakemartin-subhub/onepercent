import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { v4 as uuidv4 } from 'uuid';
import { generateMessages, moderateContent } from '../services/openai';

export const messageRouter = Router();

// Request validation schemas
const userProfileSchema = z.object({
  id: z.string().optional(),
  displayName: z.string(),
  ageRange: z.string().optional(),
  bio: z.string().optional(),
  voiceTone: z.enum(['playful', 'direct', 'witty', 'warm', 'confident', 'casual']),
  hardBoundaries: z.array(z.string()).default([]),
  datingIntent: z.string().optional(),
  emojiStyle: z.enum(['none', 'light', 'heavy']).default('light'),
});

const matchProfileSchema = z.object({
  matchId: z.string().optional(),
  name: z.string().optional(),
  age: z.number().optional(),
  bio: z.string().optional(),
  prompts: z.array(z.object({
    prompt: z.string(),
    answer: z.string(),
  })).default([]),
  interests: z.array(z.string()).default([]),
  job: z.string().optional(),
  school: z.string().optional(),
  location: z.string().optional(),
  hooks: z.array(z.string()).default([]),
});

const generateMessagesSchema = z.object({
  userProfile: userProfileSchema,
  matchProfile: matchProfileSchema,
  tone: z.string().optional(),
  maxChars: z.number().min(50).max(500).optional(),
  conversationContext: z.string().optional(),
});

/**
 * POST /v1/message/generate
 * Generate personalized messages for a match
 */
messageRouter.post('/generate', async (req: Request, res: Response, next: NextFunction) => {
  try {
    // Validate request body
    const validation = generateMessagesSchema.safeParse(req.body);
    if (!validation.success) {
      return res.status(400).json({
        error: 'Invalid request',
        details: validation.error.errors,
      });
    }

    const { userProfile, matchProfile, tone, maxChars, conversationContext } = validation.data;

    // Log request
    console.log(`[message/generate] Generating messages for match: ${matchProfile.name || 'unknown'}`);

    // Generate messages using OpenAI
    const messages = await generateMessages(
      userProfile,
      matchProfile,
      { tone, maxChars, conversationContext }
    );

    // Add IDs to messages
    const messagesWithIds = messages.map(msg => ({
      ...msg,
      id: uuidv4(),
    }));

    // Run moderation on generated messages
    const moderatedMessages = await Promise.all(
      messagesWithIds.map(async (msg) => {
        try {
          const moderation = await moderateContent(msg.text);
          if (moderation.flagged) {
            console.warn(`[message/generate] Message flagged: ${moderation.categories.join(', ')}`);
            return {
              ...msg,
              riskFlags: moderation.categories,
            };
          }
          return msg;
        } catch (error) {
          // If moderation fails, still return the message but log it
          console.error('[message/generate] Moderation error:', error);
          return msg;
        }
      })
    );

    // Filter out severely flagged messages
    const safeMessages = moderatedMessages.filter(msg => {
      const severeFlags = ['sexual', 'hate', 'violence', 'self-harm'];
      const hasSevereFlag = msg.riskFlags?.some(flag => 
        severeFlags.some(severe => flag.toLowerCase().includes(severe))
      );
      return !hasSevereFlag;
    });

    // Ensure we have at least some messages
    if (safeMessages.length === 0) {
      console.warn('[message/generate] All messages were filtered, regenerating...');
      // In production, you might want to regenerate with stricter constraints
      return res.status(500).json({
        error: 'Failed to generate appropriate messages. Please try again.',
      });
    }

    console.log(`[message/generate] Successfully generated ${safeMessages.length} messages`);

    return res.json({ messages: safeMessages });
  } catch (error) {
    console.error('[message/generate] Error:', error);
    next(error);
  }
});
