/**
 * Shared types for the OnePercent backend
 * Template-driven message generation system
 */

// ============================================================
// LINE MODE
// ============================================================

export type LineMode = 'one' | 'twoThree' | 'threePlus';

// ============================================================
// TEMPLATE CATEGORIES
// ============================================================

export enum TemplateCategory {
  FOOD = 'FOOD',
  NATURE_VIEW = 'NATURE_VIEW',
  GAMING = 'GAMING',
  PHYSICAL_ACTIVITY = 'PHYSICAL_ACTIVITY',
  EXERCISE = 'EXERCISE',
  MUSIC = 'MUSIC',
  OPINIONS = 'OPINIONS',
  FUTURE_PROMISES = 'FUTURE_PROMISES',
  SARCASTIC_AMBITION = 'SARCASTIC_AMBITION',
  TRAVELING = 'TRAVELING',
  GENERIC = 'GENERIC',
}

// Category priority ordering (higher = checked first)
export const CATEGORY_PRIORITY: TemplateCategory[] = [
  TemplateCategory.FOOD,
  TemplateCategory.SARCASTIC_AMBITION,
  TemplateCategory.TRAVELING,
  TemplateCategory.GAMING,
  TemplateCategory.MUSIC,
  TemplateCategory.EXERCISE,
  TemplateCategory.PHYSICAL_ACTIVITY,
  TemplateCategory.NATURE_VIEW,
  TemplateCategory.OPINIONS,
  TemplateCategory.FUTURE_PROMISES,
  TemplateCategory.GENERIC,
];

// Category weights (how rigidly AI follows the template)
export const CATEGORY_WEIGHTS: Record<TemplateCategory, number> = {
  [TemplateCategory.FOOD]: 9,
  [TemplateCategory.NATURE_VIEW]: 7,
  [TemplateCategory.GAMING]: 8,
  [TemplateCategory.PHYSICAL_ACTIVITY]: 6,
  [TemplateCategory.EXERCISE]: 7,
  [TemplateCategory.MUSIC]: 5,
  [TemplateCategory.OPINIONS]: 3,
  [TemplateCategory.FUTURE_PROMISES]: 3,
  [TemplateCategory.SARCASTIC_AMBITION]: 8,
  [TemplateCategory.TRAVELING]: 8,
  [TemplateCategory.GENERIC]: 4,
};

// ============================================================
// TEMPLATE TYPES
// ============================================================

export interface Template {
  id: string;
  category: TemplateCategory;
  lineMode: LineMode;
  weight: number;               // 1-10: how rigidly AI should follow this template
  lines: string[];              // The actual template lines with {placeholders}
  placeholders: Record<string, string>;  // { placeholder_name: description }
  technique: string;            // How/why this template works
  description: string;          // Short description of the vibe
  requiresUserVariable?: string;  // e.g. 'canCook' -- if set, user must have this
  humilityVariant?: string[];   // Alternative lines when user DOESN'T have the required variable
}

export interface UniversalPattern {
  id: string;
  name: string;
  description: string;
  example: string;
  applicableLineModes: LineMode[];
  applicableCategories: TemplateCategory[] | 'ALL';
}

export interface CategorySignal {
  category: TemplateCategory;
  signal: string;              // The raw text that triggered this signal
  hookStrength: number;        // 1-10: how strong the signal is
  specificDetail: string;      // The specific variable extracted
  sourceType: 'prompt' | 'interest' | 'bio' | 'hook' | 'photo';
}

export interface TemplateMatchResult {
  template: Template;
  filledLines: string[];
  category: TemplateCategory;
  signal: CategorySignal;
  userVariableUsed: boolean;
}

// ============================================================
// PROFILE TYPES
// ============================================================

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
  datingIntent?: string;
  emojiStyle: 'none' | 'light' | 'heavy';
  activities?: string[];
  nationalities?: string[];
  firstDateGoal?: 'coffee' | 'drinks' | 'dinner' | 'activity' | 'cooking' | 'walk_park';

  // Template-aligned fields (from onboarding)
  canCook?: boolean;
  cookingLevel?: 'beginner' | 'intermediate' | 'advanced';
  cuisineTypes?: string[];          // Italian, Mexican, Korean, French, etc.
  playsMusic?: boolean;
  instruments?: string[];           // Guitar, Piano, Drums, Voice, etc.
  instrumentLevel?: 'learning' | 'intermediate' | 'advanced';
  outdoorActivities?: string[];     // Hiking, Surfing, Skiing, Rock Climbing, etc.
  localSpots?: string[];            // Date spot names/descriptions
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
  contentType?: 'profile' | 'conversation';

  // Category signals extracted during parsing
  categorySignals?: {
    foodSignal?: string;
    activitySignal?: string;
    exerciseSignal?: string;
    musicSignal?: string;
    travelSignal?: string;
    gamingSignal?: string;
    opinionSignal?: string;
    futurePromiseSignal?: string;
    sarcasticAmbitionSignal?: string;
    natureViewSignal?: string;
  };
}

// ============================================================
// MESSAGE TYPES
// ============================================================

export interface MessageReasoning {
  whoAmI?: string;
  whoIsShe?: string;
  hookUsed?: string;
  ctaDirection?: string;
  whyThisApproach?: string;
  conversationState?: string;
  approach?: string;
  nextMove?: string;
  templateId?: string;
  categoryUsed?: string;
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
