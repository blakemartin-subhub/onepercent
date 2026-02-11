import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { v4 as uuidv4 } from 'uuid';
import { generateMessages, regenerateSingleLine, moderateContent } from '../services/openai';
import type { MessageReasoning } from '../types';

export const messageRouter = Router();

// Request validation schemas
const userProfileSchema = z.object({
  id: z.string().default('unknown'),
  displayName: z.string(),
  ageRange: z.string().optional(),
  bio: z.string().optional(),
  voiceTone: z.enum(['playful', 'direct', 'witty', 'warm', 'confident', 'spicy']),
  voiceTones: z.array(z.enum(['playful', 'direct', 'witty', 'warm', 'confident', 'spicy'])).optional(),
  datingIntent: z.string().optional(),
  emojiStyle: z.enum(['none', 'light', 'heavy']).default('light'),
  activities: z.array(z.string()).optional(),
  nationalities: z.array(z.string()).optional(),
  firstDateGoal: z.enum(['coffee', 'drinks', 'dinner', 'activity', 'cooking', 'walk_park']).optional(),
  // Template-aligned fields
  canCook: z.boolean().optional(),
  cookingLevel: z.enum(['beginner', 'intermediate', 'advanced']).optional(),
  cuisineTypes: z.array(z.string()).optional(),
  playsMusic: z.boolean().optional(),
  instruments: z.array(z.string()).optional(),
  instrumentLevel: z.enum(['learning', 'intermediate', 'advanced']).optional(),
  outdoorActivities: z.array(z.string()).optional(),
  localSpots: z.array(z.string()).optional(),
});

const matchProfileSchema = z.object({
  matchId: z.string().default('unknown'),
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
  direction: z.string().optional(), // MVP: user's direction (e.g. "Funny. get her to grab coffee with me")
  lineMode: z.enum(['one', 'twoThree', 'threePlus']).optional(), // Line count mode: 1 Line / 2-3 Lines / 3+ Lines
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
      console.error(`[message/generate] Validation failed:`, validation.error.errors);
      return res.status(400).json({
        error: 'Invalid request',
        details: validation.error.errors,
      });
    }

    const { userProfile, matchProfile, tone, conversationContext, direction, lineMode } = validation.data;
    console.log(`[message/generate] Generating for: ${matchProfile.name || 'unknown'}, tone: ${userProfile.voiceTone}, direction: ${direction || 'none'}, lineMode: ${lineMode || 'twoThree'}`);

    // Generate messages using template-driven pipeline
    const result = await generateMessages(
      userProfile,
      matchProfile,
      { tone, conversationContext, direction, lineMode }
    );

    // Add IDs to messages
    const messagesWithIds = result.messages.map(msg => ({
      ...msg,
      id: uuidv4(),
    }));
    
    // Convert reasoning to string for backward compatibility with iOS
    let reasoning: string | undefined;
    if (result.reasoning) {
      if (typeof result.reasoning === 'string') {
        reasoning = result.reasoning;
      } else {
        // Serialize object reasoning to readable string
        const r = result.reasoning as MessageReasoning;
        const parts: string[] = [];
        if (r.whoAmI) parts.push(`Who I am: ${r.whoAmI}`);
        if (r.whoIsShe) parts.push(`Who she is: ${r.whoIsShe}`);
        if (r.hookUsed) parts.push(`Hook used: ${r.hookUsed}`);
        if (r.ctaDirection) parts.push(`CTA direction: ${r.ctaDirection}`);
        if (r.whyThisApproach) parts.push(`Approach: ${r.whyThisApproach}`);
        if (r.conversationState) parts.push(`Conversation state: ${r.conversationState}`);
        if (r.approach) parts.push(`Approach: ${r.approach}`);
        if (r.nextMove) parts.push(`Next move: ${r.nextMove}`);
        if (r.templateId) parts.push(`Template: ${r.templateId}`);
        if (r.categoryUsed) parts.push(`Category: ${r.categoryUsed}`);
        reasoning = parts.join(' | ');
      }
    }

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

    return res.json({ messages: safeMessages, reasoning, matchedPrompt: result.matchedPrompt });
  } catch (error) {
    console.error('[message/generate] Error:', error);
    next(error);
  }
});

// Request validation for single-line regen
const regenLineSchema = z.object({
  userProfile: userProfileSchema,
  matchProfile: matchProfileSchema,
  allMessages: z.array(z.string()).min(1),
  lineIndex: z.number().min(0),
  tone: z.string().optional(),
});

/**
 * POST /v1/message/regen-line
 * Regenerate a single line in a message sequence
 */
messageRouter.post('/regen-line', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const validation = regenLineSchema.safeParse(req.body);
    if (!validation.success) {
      console.error(`[message/regen-line] Validation failed:`, validation.error.errors);
      return res.status(400).json({
        error: 'Invalid request',
        details: validation.error.errors,
      });
    }

    const { userProfile, matchProfile, allMessages, lineIndex, tone } = validation.data;
    
    if (lineIndex >= allMessages.length) {
      return res.status(400).json({ error: 'lineIndex out of range' });
    }

    console.log(`[message/regen-line] Regenerating line ${lineIndex + 1} of ${allMessages.length}`);

    const result = await regenerateSingleLine(
      userProfile,
      matchProfile,
      allMessages,
      lineIndex,
      { tone }
    );

    // Moderate the regenerated line
    try {
      const moderation = await moderateContent(result.text);
      if (moderation.flagged) {
        const severeFlags = ['sexual', 'hate', 'violence', 'self-harm'];
        const hasSevere = moderation.categories.some(flag =>
          severeFlags.some(severe => flag.toLowerCase().includes(severe))
        );
        if (hasSevere) {
          return res.status(500).json({ error: 'Generated line was flagged. Try again.' });
        }
      }
    } catch (modError) {
      console.error('[message/regen-line] Moderation error:', modError);
    }

    console.log(`[message/regen-line] Regenerated: "${result.text}"`);
    return res.json({ text: result.text, reasoning: result.reasoning });
  } catch (error) {
    console.error('[message/regen-line] Error:', error);
    next(error);
  }
});
