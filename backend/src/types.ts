/**
 * Shared types for the OnePercent backend
 */

export interface UserProfile {
  id: string;
  displayName: string;
  ageRange?: string;
  bio?: string;
  voiceTone: 'playful' | 'direct' | 'witty' | 'warm' | 'confident' | 'casual';
  hardBoundaries: string[];
  datingIntent?: string;
  emojiStyle: 'none' | 'light' | 'heavy';
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
}

export interface PromptAnswer {
  prompt: string;
  answer: string;
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
}

export interface GeneratedMessage {
  id?: string;
  type: 'opener' | 'followUp' | 'reply';
  text: string;
  riskFlags?: string[];
}

export interface APIError {
  error: string;
  code?: string;
  details?: unknown;
}
