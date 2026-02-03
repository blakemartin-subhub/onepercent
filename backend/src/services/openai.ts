import OpenAI from 'openai';
import { PROFILE_PARSING_PROMPT, MESSAGE_GENERATION_PROMPT, CONVERSATION_FOLLOWUP_PROMPT } from '../prompts/index';
import type { UserProfile, MatchProfile, ParsedProfile, GeneratedMessage } from '../types';

// Lazy-initialize OpenAI client
let openai: OpenAI | null = null;

function getOpenAI(): OpenAI {
  if (!openai) {
    openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
  }
  return openai;
}

/**
 * Parse OCR text into structured profile data
 */
export async function parseProfile(ocrText: string): Promise<ParsedProfile> {
  const response = await getOpenAI().chat.completions.create({
    model: 'gpt-4o-mini', // Cost-effective for parsing
    messages: [
      {
        role: 'system',
        content: PROFILE_PARSING_PROMPT,
      },
      {
        role: 'user',
        content: `Parse the following dating profile OCR text:\n\n${ocrText}`,
      },
    ],
    response_format: { type: 'json_object' },
    temperature: 0.3, // Lower temperature for more consistent parsing
    max_tokens: 1000,
  });

  const content = response.choices[0]?.message?.content;
  if (!content) {
    throw new Error('No response from OpenAI');
  }

  try {
    const parsed = JSON.parse(content) as ParsedProfile;
    return parsed;
  } catch (error) {
    throw new Error('Failed to parse OpenAI response as JSON');
  }
}

/**
 * Generate personalized messages for a match
 */
export async function generateMessages(
  userProfile: UserProfile,
  matchProfile: MatchProfile,
  options: {
    tone?: string;
    maxChars?: number;
    conversationContext?: string;
  } = {}
): Promise<{ messages: GeneratedMessage[]; reasoning?: string }> {
  const { tone = 'playful', maxChars = 300, conversationContext } = options;

  // Build the prompt with user and match context
  const userContext = buildUserContext(userProfile);
  const matchContext = buildMatchContext(matchProfile);
  const constraints = buildConstraints(userProfile, maxChars);

  // Use conversation prompt if context is provided, otherwise use opener prompt
  let prompt: string;
  let userMessage: string;

  if (conversationContext && conversationContext.length > 50) {
    // Use conversation follow-up prompt
    prompt = CONVERSATION_FOLLOWUP_PROMPT
      .replace('{userProfile}', userContext)
      .replace('{matchProfile}', matchContext)
      .replace('{conversationContext}', conversationContext)
      .replace('{tone}', tone)
      .replace(/\{additionalBoundaries\}/g, constraints);
    
    userMessage = 'Generate follow-up messages based on this conversation.';
  } else {
    // Use opener prompt
    prompt = MESSAGE_GENERATION_PROMPT
      .replace('{userProfile}', userContext)
      .replace('{matchProfile}', matchContext)
      .replace('{tone}', tone)
      .replace('{maxChars}', maxChars.toString())
      .replace('{additionalBoundaries}', constraints);
    
    userMessage = 'Generate opener messages for this match.';
  }

  const response = await getOpenAI().chat.completions.create({
    model: 'gpt-4o', // Better quality for message generation
    messages: [
      {
        role: 'system',
        content: prompt,
      },
      {
        role: 'user',
        content: userMessage,
      },
    ],
    response_format: { type: 'json_object' },
    temperature: 0.8, // Higher temperature for creative variety
    max_tokens: 1500,
  });

  const content = response.choices[0]?.message?.content;
  if (!content) {
    throw new Error('No response from OpenAI');
  }

  try {
    const parsed = JSON.parse(content) as { messages: GeneratedMessage[]; reasoning?: string };
    return {
      messages: parsed.messages || [],
      reasoning: parsed.reasoning
    };
  } catch (error) {
    throw new Error('Failed to parse OpenAI response as JSON');
  }
}

/**
 * Build user context string for the prompt
 */
function buildUserContext(profile: UserProfile): string {
  const parts: string[] = [];
  
  if (profile.displayName) {
    parts.push(`Name: ${profile.displayName}`);
  }
  if (profile.bio) {
    parts.push(`Bio: ${profile.bio}`);
  }
  
  // Handle multiple tones
  if (profile.voiceTones && profile.voiceTones.length > 0) {
    parts.push(`Preferred tones: ${profile.voiceTones.join(', ')}`);
  } else if (profile.voiceTone) {
    parts.push(`Preferred tone: ${profile.voiceTone}`);
  }
  
  if (profile.emojiStyle) {
    parts.push(`Emoji style: ${profile.emojiStyle}`);
  }
  
  // Include user's own dating profile context if available
  if (profile.profileContext) {
    parts.push(`\nUser's dating profile details (OCR'd):\n${profile.profileContext}`);
  }
  
  return parts.join('\n') || 'No user profile provided';
}

/**
 * Build match context string for the prompt
 */
function buildMatchContext(profile: MatchProfile): string {
  const parts: string[] = [];
  
  if (profile.name) {
    parts.push(`Name: ${profile.name}`);
  }
  if (profile.age) {
    parts.push(`Age: ${profile.age}`);
  }
  if (profile.bio) {
    parts.push(`Bio: ${profile.bio}`);
  }
  if (profile.job) {
    parts.push(`Job: ${profile.job}`);
  }
  if (profile.location) {
    parts.push(`Location: ${profile.location}`);
  }
  if (profile.interests && profile.interests.length > 0) {
    parts.push(`Interests: ${profile.interests.join(', ')}`);
  }
  if (profile.prompts && profile.prompts.length > 0) {
    parts.push('Prompts:');
    profile.prompts.forEach(p => {
      parts.push(`  Q: ${p.prompt}`);
      parts.push(`  A: ${p.answer}`);
    });
  }
  if (profile.hooks && profile.hooks.length > 0) {
    parts.push(`Conversation hooks: ${profile.hooks.join(', ')}`);
  }
  
  return parts.join('\n') || 'No match profile provided';
}

/**
 * Build constraints based on user preferences
 */
function buildConstraints(profile: UserProfile, maxChars: number): string {
  const constraints: string[] = [];
  
  if (profile.hardBoundaries && profile.hardBoundaries.length > 0) {
    constraints.push(`User boundaries: ${profile.hardBoundaries.join(', ')}`);
  }
  
  constraints.push(`Maximum ${maxChars} characters per message`);
  
  return constraints.join('. ');
}

/**
 * Moderate content using OpenAI's moderation endpoint
 */
export async function moderateContent(text: string): Promise<{
  flagged: boolean;
  categories: string[];
}> {
  const response = await getOpenAI().moderations.create({
    input: text,
  });

  const result = response.results[0];
  const flaggedCategories = Object.entries(result.categories)
    .filter(([_, flagged]) => flagged)
    .map(([category]) => category);

  return {
    flagged: result.flagged,
    categories: flaggedCategories,
  };
}
