import OpenAI from 'openai';
import {
  PROFILE_PARSING_PROMPT,
  SINGLE_LINE_REGEN_PROMPT,
  DIALOGUE_CONTINUATION_PROMPT,
  MASTER_PERSONALITY,
  TEMPLATE_FILL_PROMPT,
  GUIDED_GENERATION_PROMPT,
  PERSONALITY_GENERATION_PROMPT,
  LINE_MODE_INSTRUCTIONS,
  JSON_RESPONSE_FORMAT,
  QUALITY_JUDGE_PROMPT,
  QUALITY_REFINE_PROMPT,
} from '../prompts/index';
import type { UserProfile, MatchProfile, ParsedProfile, GeneratedMessage, MessageReasoning, LineMode } from '../types';
import { TemplateCategory } from '../types';
import {
  categorizeMatchVariables,
  findBestCategory,
  selectTemplate,
  fillTemplate,
  buildUserContext,
  buildMatchContext,
} from './templateMatcher';

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

const MODEL = 'gpt-5.2';

// ============================================================
// PARSE PROFILE
// ============================================================

export async function parseProfile(ocrText: string): Promise<ParsedProfile> {
  const response = await getOpenAI().chat.completions.create({
    model: MODEL,
    messages: [
      { role: 'system', content: PROFILE_PARSING_PROMPT },
      { role: 'user', content: `Parse the following dating profile OCR text:\n\n${ocrText}` },
    ],
    response_format: { type: 'json_object' },
    temperature: 0.3,
    max_completion_tokens: 1500,
  });

  const content = response.choices[0]?.message?.content;
  if (!content) throw new Error('No response from OpenAI');

  try {
    return JSON.parse(content) as ParsedProfile;
  } catch {
    throw new Error('Failed to parse OpenAI response as JSON');
  }
}

// ============================================================
// GENERATE MESSAGES (Template-Driven Pipeline)
// ============================================================

export async function generateMessages(
  userProfile: UserProfile,
  matchProfile: MatchProfile,
  options: {
    tone?: string;
    conversationContext?: string;
    direction?: string;
    lineMode?: string;
  } = {}
): Promise<{ messages: GeneratedMessage[]; reasoning?: string | MessageReasoning; matchedPrompt?: string }> {
  const { conversationContext, direction, lineMode: lineModeStr = 'twoThree' } = options;
  const lineMode: LineMode = (lineModeStr as LineMode) || 'twoThree';

  let systemPrompt: string;
  let temperature: number;
  let templateId: string | undefined;
  let categoryUsed: string | undefined;
  let matchedPrompt: string | undefined; // The specific prompt+answer that was targeted

  // --- DIALOGUE CONTINUATION PATH ---
  // When conversation context is provided, use dialogue-specific prompt
  if (conversationContext && conversationContext.length > 50) {
    const userCtx = buildUserContext(userProfile);
    const matchCtx = buildMatchContext(matchProfile);

    systemPrompt = MASTER_PERSONALITY + '\n\n'
      + DIALOGUE_CONTINUATION_PROMPT
          .replace('{conversationContext}', conversationContext)
          .replace('{userContext}', userCtx)
          .replace('{matchContext}', matchCtx)
      + '\n\n' + LINE_MODE_INSTRUCTIONS[lineMode]
      + '\n\n' + JSON_RESPONSE_FORMAT;

    if (direction) {
      systemPrompt += `\n\nUSER'S ADDITIONAL DIRECTION:\n${direction}`;
    }

    temperature = 0.8;
    categoryUsed = 'DIALOGUE';
  }
  // --- TEMPLATE PIPELINE PATH ---
  else {
    // Step 1: Categorize match variables
    const signals = categorizeMatchVariables(matchProfile);

    // Step 2: Find best category
    const bestSignal = findBestCategory(signals, userProfile, lineMode);
    const bestCategory = bestSignal?.category ?? TemplateCategory.GENERIC;

    // Capture the matched prompt for the UI
    if (bestSignal) {
      // Find the specific prompt+answer pair that triggered this category
      const matchingPrompt = matchProfile.prompts?.find(p => {
        const combined = `${p.prompt} ${p.answer}`.toLowerCase();
        return combined.includes(bestSignal.specificDetail.toLowerCase().slice(0, 15));
      });
      if (matchingPrompt) {
        matchedPrompt = `"${matchingPrompt.prompt}" → "${matchingPrompt.answer}"`;
      } else {
        matchedPrompt = bestSignal.specificDetail;
      }
    }

    // Step 3: Select template
    const template = selectTemplate(bestCategory, lineMode);

    if (!template) {
      // FALLBACK: No template found -- use personality-only generation
      const userCtx = buildUserContext(userProfile);
      const matchCtx = buildMatchContext(matchProfile);

      systemPrompt = MASTER_PERSONALITY + '\n\n'
        + LINE_MODE_INSTRUCTIONS[lineMode] + '\n\n'
        + PERSONALITY_GENERATION_PROMPT
            .replace('{templateLines}', 'No specific template available. Generate based on personality traits and match profile.')
            .replace('{technique}', 'Use nonchalant, witty, provocative energy. Reference a specific detail from her profile.')
            .replace('{category}', 'GENERIC')
            .replace('{matchSignal}', bestSignal?.specificDetail ?? 'general profile')
            .replace('{userContext}', userCtx)
            .replace('{matchContext}', matchCtx)
        + '\n\n' + JSON_RESPONSE_FORMAT;

      if (direction) {
        systemPrompt += `\n\nUSER'S ADDITIONAL DIRECTION:\n${direction}`;
      }

      temperature = 0.85;
      categoryUsed = 'GENERIC_FALLBACK';
    } else {
      // Step 4: Fill template
      const matchedSignal = bestSignal ?? {
        category: TemplateCategory.GENERIC,
        signal: '',
        hookStrength: 1,
        specificDetail: '',
        sourceType: 'bio' as const,
      };
      const filledResult = fillTemplate(template, userProfile, matchProfile, matchedSignal);

      // Step 5: Build prompt based on template weight
      const userCtx = buildUserContext(userProfile);
      const matchCtx = buildMatchContext(matchProfile);
      const filledLinesText = filledResult.lines.map((l, i) => `LINE ${i + 1}: "${l}"`).join('\n');

      let weightPrompt: string;
      if (template.weight >= 8) {
        weightPrompt = TEMPLATE_FILL_PROMPT;
        temperature = 0.6;
      } else if (template.weight >= 5) {
        weightPrompt = GUIDED_GENERATION_PROMPT;
        temperature = 0.75;
      } else {
        weightPrompt = PERSONALITY_GENERATION_PROMPT;
        temperature = 0.85;
      }

      systemPrompt = MASTER_PERSONALITY + '\n\n'
        + LINE_MODE_INSTRUCTIONS[lineMode] + '\n\n'
        + weightPrompt
            .replace('{templateLines}', filledLinesText)
            .replace('{technique}', template.technique)
            .replace('{category}', template.category)
            .replace('{matchSignal}', matchedSignal.specificDetail || 'general profile detail')
            .replace('{userContext}', userCtx)
            .replace('{matchContext}', matchCtx)
        + '\n\n' + JSON_RESPONSE_FORMAT;

      if (direction) {
        systemPrompt += `\n\nUSER'S ADDITIONAL DIRECTION:\n${direction}`;
      }

      if (filledResult.usedHumilityVariant) {
        systemPrompt += '\n\nNOTE: The user does NOT have the skill/attribute that this template normally requires. The template has been adjusted to a more humble version. Maintain this humility in your output.';
      }

      templateId = template.id;
      categoryUsed = bestCategory;
    }
  }

  // --- CALL GPT + QUALITY GATE ---
  const MAX_REGEN_ATTEMPTS = 2;
  const MAX_REFINE_ATTEMPTS = 2;
  let regenCount = 0;

  while (regenCount <= MAX_REGEN_ATTEMPTS) {
    const response = await getOpenAI().chat.completions.create({
      model: MODEL,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: 'Generate the message(s) now.' },
      ],
      response_format: { type: 'json_object' },
      temperature: temperature + (regenCount * 0.05), // slightly increase temp on regen
      max_completion_tokens: 1500,
    });

    const content = response.choices[0]?.message?.content;
    if (!content) throw new Error('No response from OpenAI');

    let parsed: { messages: GeneratedMessage[]; reasoning?: string | MessageReasoning };
    try {
      parsed = JSON.parse(content);
    } catch {
      throw new Error('Failed to parse OpenAI response as JSON');
    }

    if (!parsed.messages?.length) {
      regenCount++;
      continue;
    }

    // Inject template metadata into reasoning
    if (parsed.reasoning && typeof parsed.reasoning === 'object') {
      parsed.reasoning.templateId = templateId;
      parsed.reasoning.categoryUsed = categoryUsed;
    }

    // Build context framework for the quality judge
    const contextFramework = buildContextFramework(
      templateId, categoryUsed, matchProfile, userProfile, lineMode
    );

    // Combine all message lines for judging
    const messageText = parsed.messages.map(m => m.text).join('\n');

    // --- QUALITY JUDGE (fresh GPT call, no context) ---
    const judgeResult = await judgeMessageQuality(messageText, contextFramework);
    console.log(`[quality-gate] Score: ${judgeResult.score}/100 | Template: ${templateId || 'none'} | Category: ${categoryUsed || 'none'}`);

    if (judgeResult.score >= 86) {
      // PASS -- return immediately
      return { messages: parsed.messages, reasoning: parsed.reasoning, matchedPrompt };
    }

    if (judgeResult.score <= 70) {
      // FAIL -- regenerate completely
      console.log(`[quality-gate] Score ${judgeResult.score} <= 70, regenerating (attempt ${regenCount + 1}/${MAX_REGEN_ATTEMPTS})`);
      regenCount++;
      continue;
    }

    // SCORE 71-85 -- try refining
    console.log(`[quality-gate] Score ${judgeResult.score} in 71-85, refining...`);
    let currentMessages = parsed.messages;
    let refinePassed = false;

    for (let refineAttempt = 0; refineAttempt < MAX_REFINE_ATTEMPTS; refineAttempt++) {
      const refined = await refineMessage(
        currentMessages.map(m => m.text).join('\n'),
        judgeResult.feedback,
        judgeResult.refinementSuggestion || ''
      );

      if (refined) {
        currentMessages = refined;

        // Re-judge the refined version
        const reJudge = await judgeMessageQuality(
          currentMessages.map(m => m.text).join('\n'),
          contextFramework
        );
        console.log(`[quality-gate] Refined score: ${reJudge.score}/100 (attempt ${refineAttempt + 1})`);

        if (reJudge.score >= 86) {
          refinePassed = true;
          break;
        }
      }
    }

    // Return refined version (or original if refinement didn't help)
    if (parsed.reasoning && typeof parsed.reasoning === 'object') {
      parsed.reasoning.templateId = templateId;
      parsed.reasoning.categoryUsed = categoryUsed;
    }
    return { messages: currentMessages, reasoning: parsed.reasoning, matchedPrompt };
  }

  // Exhausted all regen attempts -- make one final call and return whatever we get
  const finalResponse = await getOpenAI().chat.completions.create({
    model: MODEL,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: 'Generate the message(s) now.' },
    ],
    response_format: { type: 'json_object' },
    temperature: 0.9,
    max_completion_tokens: 1500,
  });

  const finalContent = finalResponse.choices[0]?.message?.content;
  if (!finalContent) throw new Error('No response from OpenAI after retries');

  try {
    const parsed = JSON.parse(finalContent) as { messages: GeneratedMessage[]; reasoning?: string | MessageReasoning };
    return { messages: parsed.messages || [], reasoning: parsed.reasoning, matchedPrompt };
  } catch {
    throw new Error('Failed to parse OpenAI response as JSON');
  }
}

// ============================================================
// QUALITY GATE FUNCTIONS
// ============================================================

function buildContextFramework(
  templateId: string | undefined,
  categoryUsed: string | undefined,
  matchProfile: MatchProfile,
  userProfile: UserProfile,
  lineMode: LineMode
): string {
  const parts: string[] = [];
  parts.push(`LINE MODE: ${lineMode === 'one' ? '1 Line (pre-match comment)' : lineMode === 'twoThree' ? '2-3 Lines (opener)' : '3+ Lines (dialogue)'}`);
  parts.push(`CATEGORY: ${categoryUsed || 'UNKNOWN'}`);
  parts.push(`TEMPLATE: ${templateId || 'no template (personality-only)'}`);

  // Match context summary
  if (matchProfile.name) parts.push(`MATCH NAME: ${matchProfile.name}`);
  if (matchProfile.prompts?.length) {
    parts.push('MATCH PROMPTS:');
    for (const p of matchProfile.prompts.slice(0, 3)) {
      parts.push(`  "${p.prompt}" → "${p.answer}"`);
    }
  }
  if (matchProfile.interests?.length) {
    parts.push(`MATCH INTERESTS: ${matchProfile.interests.slice(0, 5).join(', ')}`);
  }

  // User context summary
  parts.push(`USER: ${userProfile.displayName}`);
  if (userProfile.nationalities?.length) parts.push(`USER BACKGROUND: ${userProfile.nationalities.join(', ')}`);
  if (userProfile.canCook) parts.push(`USER COOKS: yes (${userProfile.cuisineTypes?.join(', ') || 'general'})`);
  if (userProfile.playsMusic) parts.push(`USER MUSIC: ${userProfile.instruments?.join(', ') || 'plays'}`);

  return parts.join('\n');
}

interface JudgeResult {
  score: number;
  passed: boolean;
  feedback: string;
  refinementSuggestion: string | null;
}

async function judgeMessageQuality(
  messageText: string,
  contextFramework: string
): Promise<JudgeResult> {
  try {
    const prompt = QUALITY_JUDGE_PROMPT
      .replace('{contextFramework}', contextFramework)
      .replace('{messageToJudge}', messageText);

    const response = await getOpenAI().chat.completions.create({
      model: MODEL,
      messages: [
        { role: 'system', content: prompt },
        { role: 'user', content: 'Judge this message now.' },
      ],
      response_format: { type: 'json_object' },
      temperature: 0.3, // Low temp for consistent scoring
      max_completion_tokens: 500,
    });

    const content = response.choices[0]?.message?.content;
    if (!content) return { score: 80, passed: false, feedback: 'Judge failed to respond', refinementSuggestion: null };

    const result = JSON.parse(content) as JudgeResult;
    return {
      score: result.score ?? 80,
      passed: result.passed ?? (result.score >= 86),
      feedback: result.feedback ?? '',
      refinementSuggestion: result.refinementSuggestion ?? null,
    };
  } catch (error) {
    console.error('[quality-gate] Judge error:', error);
    // On judge failure, pass the message through (don't block)
    return { score: 86, passed: true, feedback: 'Judge error, passing through', refinementSuggestion: null };
  }
}

async function refineMessage(
  originalMessage: string,
  feedback: string,
  refinementSuggestion: string
): Promise<GeneratedMessage[] | null> {
  try {
    const prompt = MASTER_PERSONALITY + '\n\n'
      + QUALITY_REFINE_PROMPT
          .replace('{originalMessage}', originalMessage)
          .replace('{feedback}', feedback)
          .replace('{refinementSuggestion}', refinementSuggestion);

    const response = await getOpenAI().chat.completions.create({
      model: MODEL,
      messages: [
        { role: 'system', content: prompt },
        { role: 'user', content: 'Refine the message based on the feedback.' },
      ],
      response_format: { type: 'json_object' },
      temperature: 0.75,
      max_completion_tokens: 800,
    });

    const content = response.choices[0]?.message?.content;
    if (!content) return null;

    const parsed = JSON.parse(content) as { messages: GeneratedMessage[] };
    return parsed.messages?.length ? parsed.messages : null;
  } catch (error) {
    console.error('[quality-gate] Refine error:', error);
    return null;
  }
}

// ============================================================
// REGENERATE SINGLE LINE
// ============================================================

export async function regenerateSingleLine(
  userProfile: UserProfile,
  matchProfile: MatchProfile,
  allMessages: string[],
  lineIndex: number,
  _options: { tone?: string } = {}
): Promise<{ text: string; reasoning?: string }> {
  const userCtx = buildUserContext(userProfile);
  const matchCtx = buildMatchContext(matchProfile);

  const messagesFormatted = allMessages
    .map((msg, i) => `${i + 1}. "${msg}"${i === lineIndex ? ' ← REWRITE THIS ONE' : ''}`)
    .join('\n');

  const prompt = MASTER_PERSONALITY + '\n\n'
    + SINGLE_LINE_REGEN_PROMPT
        .replace('{messageSequence}', messagesFormatted)
        .replace('{lineNumber}', (lineIndex + 1).toString())
        .replace('{originalText}', allMessages[lineIndex] || '');

  const response = await getOpenAI().chat.completions.create({
    model: MODEL,
    messages: [
      { role: 'system', content: prompt },
      { role: 'user', content: `Rewrite line ${lineIndex + 1} to sound more natural and human. It should flow well with the other lines.\n\nUSER CONTEXT:\n${userCtx}\n\nMATCH CONTEXT:\n${matchCtx}` },
    ],
    response_format: { type: 'json_object' },
    temperature: 0.9,
    max_completion_tokens: 500,
  });

  const content = response.choices[0]?.message?.content;
  if (!content) throw new Error('No response from OpenAI');

  try {
    const parsed = JSON.parse(content) as { messages?: GeneratedMessage[]; text?: string; reasoning?: string | MessageReasoning };
    // Handle both response formats
    const text = parsed.text || parsed.messages?.[0]?.text || allMessages[lineIndex];
    const reasoning = typeof parsed.reasoning === 'string' ? parsed.reasoning : parsed.reasoning?.whyThisApproach;
    return { text, reasoning };
  } catch {
    throw new Error('Failed to parse OpenAI response as JSON');
  }
}

// ============================================================
// MODERATE CONTENT
// ============================================================

export async function moderateContent(text: string): Promise<{
  flagged: boolean;
  categories: string[];
}> {
  const response = await getOpenAI().moderations.create({
    input: text,
  });

  const result = response.results[0];
  const flaggedCategories = Object.entries(result.categories)
    .filter(([, flagged]) => flagged)
    .map(([category]) => category);

  return {
    flagged: result.flagged,
    categories: flaggedCategories,
  };
}
