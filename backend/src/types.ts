/**
 * Shared types for the OnePercent backend
 */

export interface PromptAnswer {
  prompt: string;
  answer: string;
}

export interface PersonalityRead {
  archetype: string;
  vibe: string;
  respondsTo: string[];
  avoidWith: string[];
}

export interface UserProfile {
  id: string;
  displayName: string;
  ageRange?: string;
  bio?: string;
  voiceTone: 'playful' | 'direct' | 'witty' | 'warm' | 'confident' | 'spicy';
  voiceTones?: ('playful' | 'direct' | 'witty' | 'warm' | 'confident' | 'spicy')[];
  hardBoundaries: string[];
  datingIntent?: string;
  emojiStyle: 'none' | 'light' | 'heavy';
  profileContext?: string;  // OCR'd user's own dating profile
  activities?: string[];  // What they like to do
  nationalities?: string[];  // User's cultural background (Italian, Mexican, etc.)
  firstDateGoal?: 'coffee' | 'drinks' | 'dinner' | 'activity' | 'cooking' | 'walk_park';
}

export interface MatchProfile {
  matchId: string;
  name?: string;
  age?: number;
  bio?: string;
  prompts: PromptAnswer[];
  interests: string[];
  job?: string;
  school?: string;
  location?: string;
  hooks: string[];
  rawOcrText?: string;
  personalityRead?: PersonalityRead;
}

export interface ParsedProfile {
  name: string | null;
  nameCandidates?: string[];
  age: number | null;
  bio: string | null;
  prompts: PromptAnswer[] | null;
  interests: string[] | null;
  job: string | null;
  school: string | null;
  location: string | null;
  hooks: string[];
  confidence: number;
  personalityRead?: PersonalityRead;
  contentType?: 'profile' | 'conversation'; // auto-detected: is this a dating profile or a conversation?
}

export interface MessageReasoning {
  whoAmI?: string;
  whoIsShe?: string;
  hookUsed?: string;
  ctaDirection?: string;
  whyThisApproach?: string;
  conversationState?: string;
  approach?: string;
  nextMove?: string;
}

export interface GeneratedMessage {
  id?: string;
  type: 'opener' | 'followup' | 'hook' | 'question' | 'reply';
  text: string;
  order?: number;
  riskFlags?: string[];
}

export interface APIError {
  error: string;
  code?: string;
  details?: unknown;
}
