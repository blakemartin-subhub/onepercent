import OpenAI from 'openai';
import { PROFILE_PARSING_PROMPT, MESSAGE_GENERATION_PROMPT, CONVERSATION_FOLLOWUP_PROMPT, SINGLE_LINE_REGEN_PROMPT } from '../prompts/index';
import type { UserProfile, MatchProfile, ParsedProfile, GeneratedMessage, MessageReasoning } from '../types';

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
): Promise<{ messages: GeneratedMessage[]; reasoning?: string | MessageReasoning }> {
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
    model: 'gpt-4o',
    messages: [
      { role: 'system', content: prompt },
      { role: 'user', content: userMessage },
    ],
    response_format: { type: 'json_object' },
    temperature: 0.8,
    max_tokens: 1500,
  });

  const content = response.choices[0]?.message?.content;
  if (!content) {
    throw new Error('No response from OpenAI');
  }

  try {
    const parsed = JSON.parse(content) as { messages: GeneratedMessage[]; reasoning?: string | MessageReasoning };
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
 * This is LAYER 1 - User's personality and identity
 */
function buildUserContext(profile: UserProfile): string {
  const parts: string[] = [];
  
  // Core identity
  if (profile.displayName) {
    parts.push(`Name: ${profile.displayName}`);
  }
  if (profile.bio) {
    parts.push(`Bio: ${profile.bio}`);
  }
  
  // Nationalities with cultural context (USE THIS FOR NATURAL CONVERSATION)
  if (profile.nationalities && profile.nationalities.length > 0) {
    parts.push(`\nCultural Background: ${profile.nationalities.join(', ')}`);
    
    // Add cultural traits that can be used in messages
    const culturalTraits = getCulturalTraits(profile.nationalities);
    if (culturalTraits.length > 0) {
      parts.push(`Cultural conversation hooks (USE THESE NATURALLY):`);
      culturalTraits.forEach(trait => {
        parts.push(`  - ${trait}`);
      });
      parts.push(`Example: If Italian and she likes food → "I'm Italian so I can definitely cook for you"`);
      parts.push(`Example: If Mexican and she mentions family → reference your family-oriented culture`);
    }
  }
  
  // Communication style
  if (profile.voiceTones && profile.voiceTones.length > 0) {
    parts.push(`\nCommunication style: ${profile.voiceTones.join(', ')}`);
  } else if (profile.voiceTone) {
    parts.push(`\nCommunication style: ${profile.voiceTone}`);
  }
  
  if (profile.emojiStyle) {
    parts.push(`Emoji usage: ${profile.emojiStyle}`);
  }
  
  // Activities and interests (important for conversation topics)
  if (profile.activities && profile.activities.length > 0) {
    parts.push(`\nActivities/Interests: ${profile.activities.join(', ')}`);
  }
  
  // First date goal (important for CTA direction)
  if (profile.firstDateGoal) {
    const goalDescriptions: Record<string, string> = {
      'coffee': 'a casual coffee date',
      'drinks': 'grabbing drinks together',
      'dinner': 'dinner together',
      'activity': 'doing an activity together',
      'cooking': 'cooking a meal together',
      'walk_park': 'a walk in the park'
    };
    parts.push(`\nPreferred first date: ${goalDescriptions[profile.firstDateGoal] || profile.firstDateGoal}`);
  }
  
  // Include user's own dating profile context if available
  if (profile.profileContext) {
    parts.push(`\nUser's dating profile details (OCR'd):\n${profile.profileContext}`);
  }
  
  return parts.join('\n') || 'No user profile provided';
}

/**
 * Get cultural traits based on nationalities for conversation hooks
 */
function getCulturalTraits(nationalities: string[]): string[] {
  const traitsMap: Record<string, string[]> = {
    'Italian': ['Great cook - can make authentic Italian food', 'Romantic and passionate', 'Family-oriented', 'Knows good wine'],
    'Mexican': ['Amazing cook - authentic Mexican cuisine', 'Strong family values', 'Fun and festive', 'Warm and welcoming'],
    'Irish': ['Great storyteller', 'Witty sense of humor', 'Fun at pubs', 'Charming'],
    'French': ['Romantic', 'Cultured and sophisticated', 'Knows good wine & cheese', 'Appreciates fine things'],
    'Spanish': ['Passionate', 'Loves to dance', 'Night owl', 'Family-oriented'],
    'Greek': ['Incredible hospitality', 'Great Mediterranean cook', 'Family values', 'Love to celebrate'],
    'Indian': ['Amazing cook with spices', 'Family-oriented', 'Rich culture', 'Foodie'],
    'Japanese': ['Attention to detail', 'Respectful', 'Adventurous eater', 'Cultured'],
    'Korean': ['Great cook', 'Skincare expertise', 'K-culture knowledge', 'Foodie'],
    'Brazilian': ['Fun-loving', 'Great dancer', 'Warm personality', 'Beach vibes'],
    'Lebanese': ['Incredible cook', 'Very hospitable', 'Family-oriented', 'Food lover'],
    'Persian': ['Romantic (Persian poetry)', 'Great cook', 'Cultured', 'Hospitable'],
    'German': ['Efficient and reliable', 'Beer connoisseur', 'Direct communicator'],
    'British': ['Dry wit', 'Tea lover', 'Cultured'],
    'Polish': ['Great cook', 'Strong values', 'Resilient'],
    'Portuguese': ['Great seafood', 'Passionate', 'Love for fado music'],
    'Filipino': ['Incredible hospitality', 'Family-oriented', 'Great cook', 'Fun-loving'],
    'Vietnamese': ['Amazing cook', 'Family values', 'Hard-working'],
    'Chinese': ['Rich culture', 'Great cook', 'Family-oriented'],
    'Colombian': ['Passionate', 'Great dancer', 'Warm', 'Coffee expertise'],
    'Cuban': ['Great cook', 'Music lover', 'Passionate', 'Family values'],
    'Puerto Rican': ['Great cook', 'Music & dance', 'Warm', 'Family-oriented'],
    'Jamaican': ['Great cook', 'Laid-back vibes', 'Music lover'],
    'Nigerian': ['Great cook', 'Strong culture', 'Family values', 'Ambitious'],
    'Ethiopian': ['Amazing coffee culture', 'Great cook', 'Rich traditions'],
    'Russian': ['Cultured', 'Direct', 'Strong values'],
    'Ukrainian': ['Great cook', 'Warm hospitality', 'Strong values'],
    'Swedish': ['Design sense', 'Active lifestyle', 'Progressive'],
    'Norwegian': ['Outdoor lover', 'Active', 'Nature appreciation'],
    'Dutch': ['Direct communicator', 'Tall', 'Bike culture'],
    'Swiss': ['Punctual', 'Quality-focused', 'Multilingual', 'Love for mountains'],
    'Australian': ['Laid-back', 'Outdoor lover', 'Beach culture'],
    'Canadian': ['Polite', 'Hockey lover', 'Multicultural'],
    'American': ['Diverse', 'Ambitious', 'Sports lover']
  };
  
  const traits: string[] = [];
  for (const nationality of nationalities) {
    if (traitsMap[nationality]) {
      traits.push(`${nationality}: ${traitsMap[nationality].join(', ')}`);
    }
  }
  return traits;
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
  
  // Include personality analysis if available
  if (profile.personalityRead) {
    parts.push('\nPersonality Analysis:');
    parts.push(`  Archetype: ${profile.personalityRead.archetype}`);
    parts.push(`  Vibe: ${profile.personalityRead.vibe}`);
    if (profile.personalityRead.respondsTo.length > 0) {
      parts.push(`  Responds well to: ${profile.personalityRead.respondsTo.join(', ')}`);
    }
    if (profile.personalityRead.avoidWith.length > 0) {
      parts.push(`  Avoid: ${profile.personalityRead.avoidWith.join(', ')}`);
    }
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
 * Regenerate a single line in a message sequence
 * Keeps context of other lines, makes the target line sound more human
 */
export async function regenerateSingleLine(
  userProfile: UserProfile,
  matchProfile: MatchProfile,
  allMessages: string[],
  lineIndex: number,
  options: { tone?: string } = {}
): Promise<{ text: string; reasoning?: string }> {
  const { tone = 'playful' } = options;

  const userContext = buildUserContext(userProfile);
  const matchContext = buildMatchContext(matchProfile);

  // Format messages with line numbers for the prompt
  const messagesFormatted = allMessages
    .map((msg, i) => `${i + 1}. "${msg}"${i === lineIndex ? ' ← REWRITE THIS ONE' : ''}`)
    .join('\n');

  const prompt = SINGLE_LINE_REGEN_PROMPT
    .replace('{userProfile}', userContext)
    .replace('{matchProfile}', matchContext)
    .replace('{lineIndex}', (lineIndex + 1).toString())
    .replace('{allMessages}', messagesFormatted)
    .replace('{tone}', tone);

  const response = await getOpenAI().chat.completions.create({
    model: 'gpt-4o',
    messages: [
      { role: 'system', content: prompt },
      { role: 'user', content: `Rewrite line ${lineIndex + 1} to sound more natural and human. It should flow well with the other lines.` },
    ],
    response_format: { type: 'json_object' },
    temperature: 0.9, // Higher temperature for more creative/varied rewrites
    max_tokens: 500,
  });

  const content = response.choices[0]?.message?.content;
  if (!content) {
    throw new Error('No response from OpenAI');
  }

  try {
    const parsed = JSON.parse(content) as { text: string; reasoning?: string };
    return {
      text: parsed.text || allMessages[lineIndex],
      reasoning: parsed.reasoning,
    };
  } catch (error) {
    throw new Error('Failed to parse OpenAI response as JSON');
  }
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
