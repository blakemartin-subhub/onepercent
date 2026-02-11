/**
 * Template Matching Engine
 * Categorizes match variables, ranks categories, selects templates, fills placeholders.
 * This is the core intelligence that replaces free-form GPT generation.
 */

import type { UserProfile, MatchProfile, CategorySignal, Template, LineMode } from '../types';
import { TemplateCategory, CATEGORY_PRIORITY } from '../types';
import { getTemplatesByCategory, getGenericTemplates } from '../templates';

// ============================================================
// CATEGORY KEYWORD MAPS
// ============================================================

const CATEGORY_KEYWORDS: Record<TemplateCategory, string[]> = {
  [TemplateCategory.FOOD]: [
    'cook', 'cooking', 'chef', 'food', 'foodie', 'restaurant', 'cuisine', 'eat', 'eating',
    'italian', 'mexican', 'korean', 'french', 'spanish', 'japanese', 'thai', 'indian', 'chinese',
    'sushi', 'pasta', 'tacos', 'ramen', 'pizza', 'brunch', 'dinner', 'lunch', 'bake', 'baking',
    'recipe', 'kitchen', 'vegan', 'vegetarian', 'spicy', 'dessert', 'chocolate', 'wine', 'coffee',
    'cocktail', 'margarita', 'marg', 'prosecco', 'beer', 'drinks', 'bar', 'happy hour',
    'michelin', 'farm to table', 'farmers market', 'grocery', 'meal prep',
  ],
  [TemplateCategory.NATURE_VIEW]: [
    'hike', 'hiking', 'mountain', 'sunset', 'sunrise', 'trail', 'nature', 'scenic', 'lookout',
    'forest', 'beach', 'ocean', 'lake', 'waterfall', 'view', 'views', 'outdoors', 'outdoor',
    'camping', 'stargazing', 'drive', 'road trip',
  ],
  [TemplateCategory.GAMING]: [
    'game', 'gaming', 'gamer', 'video game', 'board game', 'card game', 'xbox', 'playstation',
    'nintendo', 'switch', 'pc gaming', 'valorant', 'fortnite', 'minecraft', 'mario kart',
    'smash bros', 'chess', 'poker', 'uno', 'monopoly', 'catan', 'arcade',
  ],
  [TemplateCategory.PHYSICAL_ACTIVITY]: [
    'surf', 'surfing', 'snowboard', 'snowboarding', 'ski', 'skiing', 'skate', 'skateboard',
    'rock climb', 'climbing', 'bouldering', 'laser tag', 'axe throwing', 'go kart', 'go-kart',
    'bowling', 'mini golf', 'kayak', 'paddleboard', 'wakeboard', 'swim', 'swimming',
    'tennis', 'pickleball', 'volleyball', 'basketball', 'soccer', 'football', 'baseball',
    'golf', 'ping pong', 'pool', 'darts', 'rave', 'raving', 'dance', 'dancing',
  ],
  [TemplateCategory.EXERCISE]: [
    'gym', 'workout', 'work out', 'working out', 'fitness', 'lift', 'lifting', 'weights',
    'pilates', 'yoga', 'crossfit', 'cross fit', 'peloton', 'spin', 'spinning', 'run', 'running',
    'marathon', 'triathlon', 'gym rat', 'leg day', 'arm day', 'gains', 'protein',
    'muscle', 'training', 'exercise', 'fit', 'athletic',
  ],
  [TemplateCategory.MUSIC]: [
    'guitar', 'piano', 'drums', 'sing', 'singing', 'musician', 'music', 'instrument',
    'concert', 'festival', 'band', 'dj', 'vinyl', 'record', 'album', 'spotify',
    'playlist', 'song', 'lyrics', 'ukulele', 'bass', 'violin', 'sax', 'saxophone',
    'music collection', 'learn to play', 'learning how to', 'play for you',
  ],
  [TemplateCategory.OPINIONS]: [
    'controversial', 'opinion', 'believe', 'think', 'hot take', 'unpopular',
    'red flag', 'green flag', 'deal breaker', 'non-negotiable', 'overrated', 'underrated',
    'hate', 'love', 'best', 'worst', 'favorite', 'political', 'debate',
    'pineapple', 'never do again', 'don\'t hate me', 'should not go out',
    'accent', 'southern', 'procrastination', 'spontaneity', 'strength',
  ],
  [TemplateCategory.FUTURE_PROMISES]: [
    'i\'ll make you', 'together we\'ll', 'i promise', 'i\'ll give you', 'dating me',
    'fall for you', 'win me over', 'i\'ll fall', 'attention disorder', 'adhd',
    'turn you into', 'change your', 'ruin your', 'give you', 'make you',
  ],
  [TemplateCategory.SARCASTIC_AMBITION]: [
    'take over the world', 'start a cult', 'world domination', 'start a religion',
    'rule the world', 'pitch deck', 'business plan', 'empire', 'dynasty',
    'start a business', 'million dollars', 'billionaire', 'president',
    'what if i told you', 'commit tax fraud', 'rob a bank',
  ],
  [TemplateCategory.TRAVELING]: [
    'travel', 'traveling', 'travelling', 'backpack', 'backpacking', 'solo trip',
    'flight', 'airplane', 'airport', 'passport', 'italy', 'italia', 'france', 'paris',
    'spain', 'espana', 'japan', 'tokyo', 'bali', 'greece', 'santorini', 'london',
    'europe', 'asia', 'south america', 'mexico', 'tulum', 'cancun', 'colosseum',
    'eiffel', 'spontaneous', 'adventure', 'explore', 'wander', 'nomad',
    'sweden', 'move back', 'temporarily', 'originally from',
  ],
  [TemplateCategory.GENERIC]: [],
};

// ============================================================
// STEP 1: CATEGORIZE MATCH VARIABLES
// ============================================================

export function categorizeMatchVariables(matchProfile: MatchProfile): CategorySignal[] {
  const signals: CategorySignal[] = [];
  const searchableTexts: Array<{ text: string; source: CategorySignal['sourceType'] }> = [];

  // Collect all searchable text from match profile
  if (matchProfile.bio) {
    searchableTexts.push({ text: matchProfile.bio.toLowerCase(), source: 'bio' });
  }
  for (const prompt of matchProfile.prompts || []) {
    const combined = `${prompt.prompt} ${prompt.answer}`.toLowerCase();
    searchableTexts.push({ text: combined, source: 'prompt' });
  }
  for (const interest of matchProfile.interests || []) {
    searchableTexts.push({ text: interest.toLowerCase(), source: 'interest' });
  }
  for (const hook of matchProfile.hooks || []) {
    searchableTexts.push({ text: hook.toLowerCase(), source: 'hook' });
  }

  // Score each category
  const categoryScores: Map<TemplateCategory, { score: number; bestSignal: string; bestSource: CategorySignal['sourceType']; bestDetail: string }> = new Map();

  for (const [categoryStr, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    const category = categoryStr as TemplateCategory;
    if (category === TemplateCategory.GENERIC) continue;

    let totalScore = 0;
    let bestSignal = '';
    let bestSource: CategorySignal['sourceType'] = 'bio';
    let bestDetail = '';
    let bestMatchScore = 0;

    for (const { text, source } of searchableTexts) {
      for (const keyword of keywords) {
        if (text.includes(keyword)) {
          // Weight by source type: prompts > interests > bio > hooks
          const sourceWeight = source === 'prompt' ? 3 : source === 'interest' ? 2 : source === 'bio' ? 1.5 : 1;
          // Weight by keyword specificity (longer keywords are more specific)
          const specificityWeight = keyword.length > 6 ? 2 : keyword.length > 3 ? 1.5 : 1;
          const matchScore = sourceWeight * specificityWeight;

          totalScore += matchScore;

          if (matchScore > bestMatchScore) {
            bestMatchScore = matchScore;
            bestSignal = text;
            bestSource = source;
            // Extract the specific detail (the context around the keyword)
            const idx = text.indexOf(keyword);
            const start = Math.max(0, idx - 20);
            const end = Math.min(text.length, idx + keyword.length + 30);
            bestDetail = text.slice(start, end).trim();
          }
        }
      }
    }

    if (totalScore > 0) {
      categoryScores.set(category, { score: totalScore, bestSignal, bestSource, bestDetail });
    }
  }

  // Convert to CategorySignal array, sorted by score
  for (const [category, data] of categoryScores) {
    signals.push({
      category,
      signal: data.bestSignal,
      hookStrength: Math.min(10, Math.round(data.score)),
      specificDetail: data.bestDetail,
      sourceType: data.bestSource,
    });
  }

  signals.sort((a, b) => b.hookStrength - a.hookStrength);
  return signals;
}

// ============================================================
// STEP 2: FIND BEST CATEGORY
// ============================================================

export function findBestCategory(
  signals: CategorySignal[],
  userProfile: UserProfile,
  lineMode: LineMode
): CategorySignal | null {
  if (signals.length === 0) return null;

  // Apply user variable boost
  const boostedSignals = signals.map(signal => {
    let boost = 0;

    // Boost categories where user has matching variables
    switch (signal.category) {
      case TemplateCategory.FOOD:
        if (userProfile.canCook) boost += 3;
        if (userProfile.cuisineTypes?.length) boost += 2;
        if (userProfile.nationalities?.some(n =>
          ['italian', 'mexican', 'korean', 'french', 'spanish', 'japanese'].includes(n.toLowerCase())
        )) boost += 2;
        break;
      case TemplateCategory.MUSIC:
        if (userProfile.playsMusic) boost += 3;
        if (userProfile.instruments?.length) boost += 2;
        break;
      case TemplateCategory.PHYSICAL_ACTIVITY:
      case TemplateCategory.NATURE_VIEW:
        if (userProfile.outdoorActivities?.length) boost += 2;
        if (userProfile.activities?.some(a =>
          ['hiking', 'surfing', 'snowboarding', 'skiing', 'climbing'].includes(a.toLowerCase())
        )) boost += 2;
        break;
      case TemplateCategory.EXERCISE:
        if (userProfile.activities?.some(a =>
          ['gym', 'fitness', 'working out', 'yoga', 'pilates'].includes(a.toLowerCase())
        )) boost += 2;
        break;
      case TemplateCategory.TRAVELING:
        if (userProfile.nationalities?.length) boost += 1;
        break;
    }

    return {
      ...signal,
      hookStrength: signal.hookStrength + boost,
    };
  });

  // Check that templates exist for the top category + lineMode
  // Fall through to next category if no templates available
  boostedSignals.sort((a, b) => {
    // First sort by priority ordering
    const aPriority = CATEGORY_PRIORITY.indexOf(a.category);
    const bPriority = CATEGORY_PRIORITY.indexOf(b.category);

    // Combine score with priority (higher score wins, priority breaks ties)
    const aScore = a.hookStrength * 10 - aPriority;
    const bScore = b.hookStrength * 10 - bPriority;
    return bScore - aScore;
  });

  for (const signal of boostedSignals) {
    const templates = getTemplatesByCategory(signal.category, lineMode);
    if (templates.length > 0) {
      return signal;
    }
  }

  // No category has templates for this lineMode -- return top signal anyway
  // (the prompt system will handle generation with personality only)
  return boostedSignals[0] || null;
}

// ============================================================
// STEP 3: SELECT TEMPLATE
// ============================================================

export function selectTemplate(category: TemplateCategory, lineMode: LineMode): Template | null {
  let templates = getTemplatesByCategory(category, lineMode);

  if (templates.length === 0) {
    // Fall back to generic templates
    templates = getGenericTemplates(lineMode);
  }

  if (templates.length === 0) return null;

  // Weighted random selection based on template weight
  // Higher weight = more likely to be selected, but still random for variety
  const totalWeight = templates.reduce((sum, t) => sum + t.weight, 0);
  let random = Math.random() * totalWeight;

  for (const template of templates) {
    random -= template.weight;
    if (random <= 0) return template;
  }

  return templates[0];
}

// ============================================================
// STEP 4: FILL TEMPLATE
// ============================================================

export interface FilledTemplateResult {
  lines: string[];
  usedHumilityVariant: boolean;
  placeholdersFilled: Record<string, string>;
}

export function fillTemplate(
  template: Template,
  userProfile: UserProfile,
  matchProfile: MatchProfile,
  signal: CategorySignal
): FilledTemplateResult {
  // Determine if we need the humility variant
  let useHumility = false;
  let linesToFill = [...template.lines];

  if (template.requiresUserVariable && template.humilityVariant) {
    switch (template.requiresUserVariable) {
      case 'canCook':
        useHumility = !userProfile.canCook;
        break;
      case 'playsMusic':
        useHumility = !userProfile.playsMusic;
        break;
      case 'cuisineTypes':
        useHumility = !userProfile.cuisineTypes?.length;
        break;
      case 'outdoorActivities':
        useHumility = !userProfile.outdoorActivities?.length;
        break;
    }
    if (useHumility) {
      linesToFill = [...template.humilityVariant];
    }
  }

  // Build variable map for placeholder filling
  const variables: Record<string, string> = {};

  // User variables
  variables.user_cuisine = userProfile.cuisineTypes?.[0] || userProfile.nationalities?.[0] || 'Italian';
  variables.user_nationality = userProfile.nationalities?.[0] || '';
  variables.user_drink = getCulturalDrink(userProfile.nationalities?.[0] || '');
  variables.user_destination = getCulturalDestination(userProfile.nationalities?.[0] || '');
  variables.flag_emoji = getFlagEmoji(userProfile.nationalities?.[0] || '');
  variables.user_adjacent_activity = userProfile.outdoorActivities?.[0] || userProfile.activities?.[0] || '';
  variables.user_skill = userProfile.canCook ? 'cooking' : userProfile.playsMusic ? (userProfile.instruments?.[0] || 'music') : (userProfile.activities?.[0] || '');
  variables.user_strength = userProfile.canCook ? 'cooking skills' : (userProfile.activities?.[0] || 'charm');

  // Match variables (extracted from signal + profile)
  variables.match_food_pref = extractMatchVariable(matchProfile, signal, 'food');
  variables.match_activity = extractMatchVariable(matchProfile, signal, 'activity');
  variables.match_game = extractMatchVariable(matchProfile, signal, 'game');
  variables.match_sarcastic_goal = extractMatchVariable(matchProfile, signal, 'sarcastic');
  variables.match_stated_preference = extractMatchVariable(matchProfile, signal, 'opinion');
  variables.match_trait = extractMatchVariable(matchProfile, signal, 'trait');
  variables.match_promise = extractMatchVariable(matchProfile, signal, 'promise');
  variables.match_travel_place = extractMatchVariable(matchProfile, signal, 'travel');
  variables.match_life_event = extractMatchVariable(matchProfile, signal, 'life_event');
  variables.match_desired_trait = extractMatchVariable(matchProfile, signal, 'desired_trait');
  variables.destination = variables.user_destination || extractMatchVariable(matchProfile, signal, 'travel');

  // Specific detail from signal
  variables.specific_detail = signal.specificDetail;
  variables.competitive_adjacent_activity = signal.specificDetail;

  // Fill placeholders in lines
  const filledLines = linesToFill.map(line => {
    let filled = line;
    for (const [key, value] of Object.entries(variables)) {
      filled = filled.replace(new RegExp(`\\{${key}\\}`, 'g'), value);
    }
    return filled;
  });

  return {
    lines: filledLines,
    usedHumilityVariant: useHumility,
    placeholdersFilled: variables,
  };
}

// ============================================================
// CONTEXT BUILDERS
// ============================================================

export function buildUserContext(userProfile: UserProfile): string {
  const parts: string[] = [];
  parts.push(`Name: ${userProfile.displayName}`);
  if (userProfile.nationalities?.length) parts.push(`Background: ${userProfile.nationalities.join(', ')}`);
  if (userProfile.activities?.length) parts.push(`Activities: ${userProfile.activities.join(', ')}`);
  if (userProfile.canCook) {
    const level = userProfile.cookingLevel || 'can cook';
    const cuisines = userProfile.cuisineTypes?.join(', ') || '';
    parts.push(`Cooking: ${level}${cuisines ? ` (${cuisines})` : ''}`);
  }
  if (userProfile.playsMusic) {
    const instruments = userProfile.instruments?.join(', ') || 'music';
    const level = userProfile.instrumentLevel || '';
    parts.push(`Music: ${instruments}${level ? ` (${level})` : ''}`);
  }
  if (userProfile.outdoorActivities?.length) parts.push(`Outdoor: ${userProfile.outdoorActivities.join(', ')}`);
  if (userProfile.localSpots?.length) parts.push(`Date spots: ${userProfile.localSpots.join(', ')}`);
  if (userProfile.firstDateGoal) parts.push(`First date goal: ${userProfile.firstDateGoal}`);
  return parts.join('\n');
}

export function buildMatchContext(matchProfile: MatchProfile): string {
  const parts: string[] = [];
  if (matchProfile.name) parts.push(`Name: ${matchProfile.name}`);
  if (matchProfile.age) parts.push(`Age: ${matchProfile.age}`);
  if (matchProfile.bio) parts.push(`Bio: ${matchProfile.bio}`);
  if (matchProfile.job) parts.push(`Job: ${matchProfile.job}`);
  if (matchProfile.school) parts.push(`School: ${matchProfile.school}`);
  if (matchProfile.location) parts.push(`Location: ${matchProfile.location}`);
  if (matchProfile.prompts?.length) {
    parts.push('Prompts:');
    for (const p of matchProfile.prompts) {
      parts.push(`  "${p.prompt}" → "${p.answer}"`);
    }
  }
  if (matchProfile.interests?.length) parts.push(`Interests: ${matchProfile.interests.join(', ')}`);
  if (matchProfile.hooks?.length) parts.push(`Hooks: ${matchProfile.hooks.join(', ')}`);
  return parts.join('\n');
}

// ============================================================
// HELPER FUNCTIONS
// ============================================================

function extractMatchVariable(
  matchProfile: MatchProfile,
  signal: CategorySignal,
  type: string
): string {
  const detail = signal.specificDetail;

  // Try to extract a clean variable from the signal detail
  switch (type) {
    case 'food': {
      // Look for specific cuisine/food mentions
      const foodKeywords = ['italian', 'mexican', 'korean', 'french', 'japanese', 'thai', 'indian', 'chinese', 'brazilian', 'sushi', 'pasta', 'tacos', 'ramen', 'pizza', 'coffee', 'cocktail', 'margarita', 'marg'];
      for (const k of foodKeywords) {
        if (detail.includes(k)) return k;
      }
      return detail || 'food';
    }
    case 'activity': {
      const activityKeywords = ['surf', 'snowboard', 'ski', 'rock climb', 'hike', 'skate', 'swim', 'tennis', 'basketball', 'volleyball', 'rave', 'dance'];
      for (const k of activityKeywords) {
        if (detail.includes(k)) return k.endsWith('e') ? k + 'ing' : k + 'ing';
      }
      return detail || 'that';
    }
    case 'game': {
      return detail || 'that';
    }
    case 'sarcastic': {
      // Extract the grandiose claim
      if (detail.includes('cult')) return 'cult';
      if (detail.includes('world')) return 'world domination plan';
      if (detail.includes('religion')) return 'religion';
      if (detail.includes('pitch')) return 'pitch deck';
      return detail || 'thing';
    }
    case 'opinion': {
      return detail || 'that';
    }
    case 'trait': {
      return detail || '';
    }
    case 'promise': {
      return detail || 'that';
    }
    case 'travel': {
      const places = ['italy', 'italia', 'france', 'paris', 'spain', 'espana', 'japan', 'tokyo', 'bali', 'greece', 'london', 'guatemala', 'sweden', 'rome', 'florence', 'barcelona'];
      for (const p of places) {
        if (detail.includes(p)) return p.charAt(0).toUpperCase() + p.slice(1);
      }
      return detail || 'somewhere amazing';
    }
    case 'life_event': {
      if (detail.includes('move')) return 'move back';
      if (detail.includes('graduat')) return 'graduate';
      return detail || 'leave';
    }
    case 'desired_trait': {
      return detail || '';
    }
    default:
      return detail || '';
  }
}

function getCulturalDrink(nationality: string): string {
  const drinks: Record<string, string> = {
    italian: 'Italian Prosecco',
    mexican: 'mezcal',
    korean: 'soju',
    french: 'Champagne',
    spanish: 'sangria',
    japanese: 'sake',
    irish: 'whiskey',
    german: 'beer',
  };
  return drinks[nationality.toLowerCase()] || 'prosecco';
}

function getCulturalDestination(nationality: string): string {
  const destinations: Record<string, string> = {
    italian: 'Italia',
    mexican: 'Mexico',
    korean: 'Seoul',
    french: 'Paris',
    spanish: 'Espana',
    japanese: 'Tokyo',
    irish: 'Dublin',
    german: 'Berlin',
    brazilian: 'Rio',
  };
  return destinations[nationality.toLowerCase()] || 'Italia';
}

function getFlagEmoji(nationality: string): string {
  const flags: Record<string, string> = {
    italian: '🇮🇹',
    mexican: '🇲🇽',
    korean: '🇰🇷',
    french: '🇫🇷',
    spanish: '🇪🇸',
    japanese: '🇯🇵',
    irish: '🇮🇪',
    german: '🇩🇪',
    brazilian: '🇧🇷',
    swedish: '🇸🇪',
    american: '🇺🇸',
  };
  return flags[nationality.toLowerCase()] || '🌍';
}
