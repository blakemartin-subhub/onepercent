/**
 * Template Bank: Human-written message templates extracted from 19+ real conversations
 * Each template preserves the exact tonality and structure of messages that actually worked.
 * GPT's job is to fill placeholders, NOT rewrite the template.
 */

import { Template, UniversalPattern, TemplateCategory, LineMode } from '../types';

// ============================================================
// 1-LINE TEMPLATES (23 total)
// ============================================================

const ONE_LINE_TEMPLATES: Template[] = [
  // --- FOOD (3) ---
  {
    id: 'FOOD-1LINE-A',
    category: TemplateCategory.FOOD,
    lineMode: 'one',
    weight: 9,
    lines: ["I'll chef up the {user_cuisine} first though, my family recipe {flag_emoji}"],
    placeholders: {
      user_cuisine: "User's food culture (Italian, Mexican, Korean, etc.)",
      flag_emoji: "Corresponding flag emoji",
    },
    technique: '"first though" acknowledges HER food without repeating it, then pivots to HIS. "first" implies a sequence = multiple dates. "my family recipe" = personal heritage, not generic cooking.',
    description: 'Cook-off energy when both user and match have food signals',
    requiresUserVariable: 'canCook',
    humilityVariant: ["I'll cook it up for you but can't promise Michelin level yet {flag_emoji}"],
  },
  {
    id: 'FOOD-1LINE-B',
    category: TemplateCategory.FOOD,
    lineMode: 'one',
    weight: 8,
    lines: ['with {user_drink} do?'],
    placeholders: {
      user_drink: "User's cultural drink alternative (prosecco, mezcal, soju, etc.)",
    },
    technique: 'Counter-offer substitute. She wants X drink, he offers his cultural equivalent. "do?" = cheeky ask if his thing is acceptable. Short, confident, cultural flex.',
    description: 'When match mentions a specific drink preference',
    requiresUserVariable: 'cuisineTypes',
    humilityVariant: ['what if I bring something better'],
  },
  {
    id: 'FOOD-1LINE-C',
    category: TemplateCategory.FOOD,
    lineMode: 'one',
    weight: 9,
    lines: ['So you like {match_food_pref}'],
    placeholders: {
      match_food_pref: "Match's food/cuisine preference from profile",
    },
    technique: 'Ultra-simple observation stated as fact, no question mark. The lack of punctuation makes it a thought, not a question. She has to elaborate.',
    description: 'Nonchalant observation about food preference',
  },
  // --- PHYSICAL_ACTIVITY (5) ---
  {
    id: 'PHYS-1LINE-A',
    category: TemplateCategory.PHYSICAL_ACTIVITY,
    lineMode: 'one',
    weight: 8,
    lines: ['can we have a {competitive_adjacent_activity}'],
    placeholders: {
      competitive_adjacent_activity: "A competitive spin on match's stated skill (e.g., 'underwater handstands' → 'breath holding contest')",
    },
    technique: 'Does NOT repeat her skill. Pivots to adjacent competitive activity. "can we" = future-assuming. No question mark = suggestion not interview. Competitive framing makes it easy to say yes.',
    description: 'Turn her skill into a playful competition',
  },
  {
    id: 'PHYS-1LINE-B',
    category: TemplateCategory.PHYSICAL_ACTIVITY,
    lineMode: 'one',
    weight: 6,
    lines: ['Vetting for red flags, {spot_a} or {spot_b}?'],
    placeholders: {
      spot_a: 'First local spot for the activity',
      spot_b: 'Second local spot for the activity',
    },
    technique: '"Vetting for red flags" = playful gatekeeping on where she does the activity. CHOICE TECHNIQUE in a 1-liner. Both options assume she does it near him.',
    description: 'Gatekeep/test where she does a specific activity',
  },
  {
    id: 'PHYS-1LINE-C',
    category: TemplateCategory.PHYSICAL_ACTIVITY,
    lineMode: 'one',
    weight: 7,
    lines: ['can u teach me how to {match_activity}...'],
    placeholders: {
      match_activity: "Match's activity from profile (raving, surfing, etc.)",
    },
    technique: 'Inverts the "I\'ll teach u" frame. He\'s the student. Ellipsis = slightly skeptical he needs teaching. The request to be taught IS the date.',
    description: 'Humble student frame when activity is her world',
  },
  {
    id: 'PHYS-1LINE-D',
    category: TemplateCategory.PHYSICAL_ACTIVITY,
    lineMode: 'one',
    weight: 9,
    lines: ["I'll teach you how to {user_adjacent_activity}"],
    placeholders: {
      user_adjacent_activity: "User's sport/activity that's adjacent to hers (e.g., she skis → 'snowboard')",
    },
    technique: "She does one sport, he pivots to his adjacent sport and offers to teach. Same authority frame as MUSIC-1LINE-A but for physical activities. Competitive energy wrapped in generosity.",
    description: 'Authority pivot from her sport to your adjacent one',
    requiresUserVariable: 'outdoorActivities',
    humilityVariant: ["I've always wanted to try {match_activity}"],
  },
  {
    id: 'GAME-1LINE-A',
    category: TemplateCategory.GAMING,
    lineMode: 'one',
    weight: 8,
    lines: ["I'd play you in {match_game} but after winning you'd probably unmatch"],
    placeholders: {
      match_game: "The game she mentioned (video game, board game, etc.)",
    },
    technique: 'Assumes victory, jokes about consequence. Provocative -- she\'ll want to prove him wrong.',
    description: 'Cocky gaming challenge with unmatch joke',
  },
  // --- EXERCISE (1) ---
  {
    id: 'EXER-1LINE-A',
    category: TemplateCategory.EXERCISE,
    lineMode: 'one',
    weight: 10,
    lines: ['let\'s be gym rats together 😌'],
    placeholders: {},
    technique: 'Five words + emoji. "let\'s" = immediate action. "gym rats" = insider slang. "together" = the date IS the gym. 😌 = effortless confidence. Zero placeholders -- works as-is.',
    description: 'Universal gym opener, zero placeholders needed',
  },
  // --- MUSIC (1) ---
  {
    id: 'MUSIC-1LINE-A',
    category: TemplateCategory.MUSIC,
    lineMode: 'one',
    weight: 10,
    lines: ["I'll teach u 😌"],
    placeholders: {},
    technique: 'Three words. Maximum confidence, minimum effort. 😌 does all the emotional work. Doesn\'t explain or qualify. "u" = casual texting energy. Works when match is LEARNING something user can do.',
    description: 'Authority offer when match is learning something you know',
    requiresUserVariable: 'playsMusic',
    humilityVariant: ["we could learn together 😌"],
  },
  // --- SARCASTIC_AMBITION (3) ---
  {
    id: 'SARC-1LINE-A',
    category: TemplateCategory.SARCASTIC_AMBITION,
    lineMode: 'one',
    weight: 9,
    lines: ["what's our {match_sarcastic_goal} gonna be about?"],
    placeholders: {
      match_sarcastic_goal: "Whatever grandiose/absurd thing they claimed (cult, world domination, religion, etc.)",
    },
    technique: '"our" = immediately co-owns the idea. Not "your" (observer). Treats it as a given. Ultra-short, 7 words. The simplicity IS the confidence.',
    description: 'Co-own their absurd dream as co-founder',
  },
  {
    id: 'SARC-1LINE-B',
    category: TemplateCategory.SARCASTIC_AMBITION,
    lineMode: 'one',
    weight: 9,
    lines: ['send me ur {contact_method} and I\'ll have it to you by {deadline} 🫡'],
    placeholders: {
      contact_method: 'Whatever makes sense for the mission (email, address, coordinates)',
      deadline: 'A specific near-future deadline (Monday, Friday, etc.)',
    },
    technique: 'ACCEPT THE MISSION. Treats absurd challenge as completely real with a timeline. Creates anticipation and extracts contact info naturally within the bit.',
    description: 'Accept challenge as real task with deliverables',
  },
  {
    id: 'SARC-1LINE-C',
    category: TemplateCategory.SARCASTIC_AMBITION,
    lineMode: 'one',
    weight: 4,
    lines: ["I'd {user_bigger_alternative}"],
    placeholders: {
      user_bigger_alternative: "User's bigger/more dramatic alternative to her listed options (e.g., she lists 3 apocalypse options → 'watch the world collapse from space')",
    },
    technique: 'Ignores ALL her options. Creates a 4th that\'s bigger than all of hers. Nonchalant, unbothered, cinematic. The ultimate one-up.',
    description: 'Ignore her options, create a bigger one',
  },
  // --- TRAVELING (3) ---
  {
    id: 'TRAV-1LINE-A',
    category: TemplateCategory.TRAVELING,
    lineMode: 'one',
    weight: 9,
    lines: ['how abt a duo trip to {user_destination} this weekend?'],
    placeholders: {
      user_destination: "Destination tied to user's culture or upgraded from match's destination (Italia, Paris, Tokyo, etc.)",
    },
    technique: 'She did solo → he proposes duo. Upgrades format. "this weekend?" = matches spontaneous energy. "how abt" = casual suggestion.',
    description: 'Upgrade her solo travel energy to duo trip',
  },
  {
    id: 'TRAV-1LINE-B',
    category: TemplateCategory.TRAVELING,
    lineMode: 'one',
    weight: 10,
    lines: ["let's go to {destination}"],
    placeholders: {
      destination: "Destination visible in photo or mentioned, using cultural name (Italia not Italy, Espana not Spain)",
    },
    technique: 'Four words. No question mark. Statement of intent. Photo-triggered -- detects travel landmarks. "let\'s go" = immediate action like gym rats and teach u.',
    description: 'Ultra-short travel statement, photo-triggered',
  },
  {
    id: 'TRAV-1LINE-C',
    category: TemplateCategory.TRAVELING,
    lineMode: 'one',
    weight: 8,
    lines: ["well when you {match_life_event} let's hit {user_destination} on the way {flag_emoji}"],
    placeholders: {
      match_life_event: "Her mentioned transition (move back, graduate, etc.)",
      user_destination: "User's cultural destination",
      flag_emoji: 'Flag emoji for destination',
    },
    technique: 'Takes her "temporary" framing and turns it into opportunity. "on the way" = the destination is a pit stop, nonchalant. Future-assumes they\'ll still be together.',
    description: 'Turn her life transition into a travel opportunity',
  },
  // --- OPINIONS (3) ---
  {
    id: 'OPIN-1LINE-A',
    category: TemplateCategory.OPINIONS,
    lineMode: 'one',
    weight: 3,
    lines: ['what else would there be to {match_stated_preference}...'],
    placeholders: {
      match_stated_preference: "Rephrase of what she said she cares about (e.g., 'talk about' for political discussions)",
    },
    technique: 'Agrees so naturally it sounds like a genuine thought. "what else" implies her thing is the ONLY thing worth doing. Trailing ellipsis = confused why anyone thinks otherwise.',
    description: 'Validate her opinion as the obvious default',
  },
  {
    id: 'OPIN-1LINE-B',
    category: TemplateCategory.OPINIONS,
    lineMode: 'one',
    weight: 4,
    lines: ['{match_trait} spawns the best {positive_reframe}'],
    placeholders: {
      match_trait: "Her self-deprecating trait (procrastination, chaos, etc.)",
      positive_reframe: "Elevated version (creation, ideas, energy, etc.)",
    },
    technique: 'Takes her self-deprecating claim and reframes as a STRENGTH. Elevates to philosophy. No emoji, no question -- reads like a pre-existing belief.',
    description: 'Reframe her flaw as a superpower',
  },
  {
    id: 'OPIN-1LINE-C',
    category: TemplateCategory.OPINIONS,
    lineMode: 'one',
    weight: 5,
    lines: ['I have one too but only when I {oddly_specific_scenario} for some reason {emoji}'],
    placeholders: {
      oddly_specific_scenario: "An oddly specific situation where user shares the same quirk",
      emoji: 'Dramatic emoji (😭, 😂, etc.)',
    },
    technique: '"I have one too" = instant shared experience. The oddly specific detail makes it believable and human. He\'s sharing HIS version rather than commenting on hers.',
    description: 'Shared quirk with oddly specific personal detail',
  },
  // --- FUTURE_PROMISES (1) ---
  {
    id: 'FUTURE-1LINE-A',
    category: TemplateCategory.FUTURE_PROMISES,
    lineMode: 'one',
    weight: 3,
    lines: ['are u gonna make my {promise_applied_to_self} worse...'],
    placeholders: {
      promise_applied_to_self: "Her promise/claim applied to yourself as if you already have the condition",
    },
    technique: 'Accept her premise as fact. Apply it to yourself. Imply she\'ll amplify it. "..." = nonchalant trailing off. She can only double down ("yeah 100%").',
    description: 'Accept premise + apply to self + mock concern',
  },
  // --- GENERIC (4) ---
  {
    id: 'GENERIC-1LINE-A',
    category: TemplateCategory.GENERIC,
    lineMode: 'one',
    weight: 3,
    lines: ['my entire profile was built around this answer...'],
    placeholders: {},
    technique: 'Self-referential redirect. Points back at his own profile as the answer to her criteria. Ellipsis = mysterious. She has to look at his profile to understand.',
    description: 'When her green flag/criteria matches your whole profile',
  },
  {
    id: 'GENERIC-1LINE-B',
    category: TemplateCategory.GENERIC,
    lineMode: 'one',
    weight: 10,
    lines: ['knock knock'],
    placeholders: {},
    technique: 'Anti-humor commitment. The most literal/basic response to "make me laugh." She either laughs because it\'s so dumb or plays along with "who\'s there?" Either way she responds.',
    description: 'When she asks to be made to laugh',
  },
  {
    id: 'GENERIC-1LINE-C',
    category: TemplateCategory.GENERIC,
    lineMode: 'one',
    weight: 9,
    lines: ["I'll send u reels"],
    placeholders: {},
    technique: 'Four words. Takes mundane scrolling and turns it into connection. Future-assumes texting/sharing content. Casual. Not trying.',
    description: 'When she mentions scrolling/social media/reels',
  },
  {
    id: 'GENERIC-1LINE-D',
    category: TemplateCategory.GENERIC,
    lineMode: 'one',
    weight: 6,
    lines: ['I actually have {match_desired_trait}, I just {reason_not_visible}'],
    placeholders: {
      match_desired_trait: "The physical/personal trait she said she wants",
      reason_not_visible: "Why it's not obvious from photos (keep it short, just keep it short, etc.)",
    },
    technique: 'She stated a preference. He happens to match it but frames as a reveal. "I actually have" = surprising. Creates curiosity.',
    description: 'When you match her stated physical/personal preference',
  },
];

// ============================================================
// 2-3 LINE TEMPLATES (10 total)
// ============================================================

const TWO_THREE_LINE_TEMPLATES: Template[] = [
  {
    id: 'DATE-GATE-A',
    category: TemplateCategory.GENERIC,
    lineMode: 'twoThree',
    weight: 9,
    lines: [
      "I'm down",
      "We'll have to save that for date #{date_number} though — I only do that when I know they're one of the special ones 😏",
    ],
    placeholders: {
      date_number: 'Future date number (2, 3, etc.) -- implies date #1 is already happening',
    },
    technique: 'GATES fun activity behind a future date. "I\'m down" = matches energy. Immediately creates anticipation/scarcity. Frames HER as needing to prove she\'s "special."',
    description: 'Universal: gate any activity behind a future date milestone',
  },
  {
    id: 'FOOD-23LINE-B',
    category: TemplateCategory.FOOD,
    lineMode: 'twoThree',
    weight: 8,
    lines: [
      "I can't promise the {match_promise} part yet",
      "But the {user_cuisine} dish I'll cook up for you already makes the date worth it, and maybe the food won't even be the best part...",
    ],
    placeholders: {
      match_promise: "Whatever the match stated they want (soulmate, adventure partner, etc.)",
      user_cuisine: "User's food culture",
    },
    technique: 'CROSS-CATEGORY ENTRY: enters via her FUTURE_PROMISES prompt, delivers via FOOD. "yet" implies it could happen. "maybe the food won\'t even be the best part" = the real hook.',
    description: 'Enter through her promise, deliver with food',
    requiresUserVariable: 'canCook',
    humilityVariant: [
      "I can't promise the {match_promise} part yet",
      "But I'll make the date worth it either way, and maybe the conversation won't even be the best part...",
    ],
  },
  {
    id: 'FOOD-23LINE-C',
    category: TemplateCategory.FOOD,
    lineMode: 'twoThree',
    weight: 9,
    lines: [
      'We cooking {dish_a} or {dish_b} tho?',
      'Paired with some {drink_pairing} ofc 🤌',
    ],
    placeholders: {
      dish_a: 'Specific dish option 1',
      dish_b: 'Specific dish option 2',
      drink_pairing: 'Culturally appropriate drink pairing',
    },
    technique: 'CHOICE TECHNIQUE: "A or B?" not "yes or no?" Once she picks, she\'s committed. "We cooking" = future-assuming collaborative. "ofc" = this is standard for you.',
    description: 'Choice engagement -- two dish options invest her in the plan',
    requiresUserVariable: 'canCook',
    humilityVariant: [
      'We going {dish_a} or {dish_b} tho?',
      "I know a spot that does both 🤌",
    ],
  },
  {
    id: 'FOOD-CTA-A',
    category: TemplateCategory.FOOD,
    lineMode: 'twoThree',
    weight: 8,
    lines: [
      "I've got this {specific_dish} that I'm told {confident_claim}",
      'So dinner when?',
    ],
    placeholders: {
      specific_dish: 'Detailed dish name (classic cherry tomato sauce pasta from scratch)',
      confident_claim: "Social proof claim (deserves a Michelin star, makes people rethink restaurants)",
    },
    technique: 'Naming the EXACT dish makes it tangible. "I\'m told" = social proof without self-bragging. "So dinner when?" = most direct CTA. Two words, no fluff.',
    description: 'Specific dish sell + direct dinner CTA',
    requiresUserVariable: 'canCook',
    humilityVariant: [
      "I've been told I make a decent {specific_dish}",
      'So dinner when?',
    ],
  },
  {
    id: 'SARC-23LINE-A',
    category: TemplateCategory.SARCASTIC_AMBITION,
    lineMode: 'twoThree',
    weight: 7,
    lines: [
      'Oh shit, I missed my deadline 😢',
      'Maybe I can have an extension until tomorrow...?',
      "Can't rush these things you know, could be {high_stakes_reason}",
    ],
    placeholders: {
      high_stakes_reason: "Dramatic/romantic reason tied to the bit (pitching my sole mate, recruiting the co-founder of my life)",
    },
    technique: 'SUSTAINED CHARACTER. Self-deprecating opener (missed deadline). Asks for extension = stays in metaphor. High stakes reason = calls her important but buried inside the bit.',
    description: 'Sustained character bit -- deadline/task variant',
  },
  {
    id: 'MUSIC-PIVOT-A',
    category: TemplateCategory.MUSIC,
    lineMode: 'twoThree',
    weight: 7,
    lines: [
      '{shared_problem} 😭',
      'What about {alternative_instrument} though?? I could teach you that',
    ],
    placeholders: {
      shared_problem: 'Empathy about shared obstacle (I actually lost mine as well)',
      alternative_instrument: 'Another instrument user can offer',
    },
    technique: 'Shares the same problem (empathy). Pivots to another instrument. Keeps "I\'ll teach you" frame alive.',
    description: 'Pivot to alternative instrument when original unavailable',
    requiresUserVariable: 'playsMusic',
    humilityVariant: [
      '{shared_problem} 😭',
      "What about {alternative_instrument} though?? I've been wanting to learn",
    ],
  },
  {
    id: 'CALLBACK-COMPARE-A',
    category: TemplateCategory.GENERIC,
    lineMode: 'twoThree',
    weight: 7,
    lines: [
      "I'm probably as confident in my {user_skill} as you are {match_skill_dominance}...",
      'so you could def say I\'m {match_exact_words} 😌',
    ],
    placeholders: {
      user_skill: "What user is confident in (cooking, etc.)",
      match_skill_dominance: "How she described her skill (beating me in a piano)",
      match_exact_words: "Her EXACT phrasing repurposed (classically trained)",
    },
    technique: 'CALLBACK TO HER WORDS. Takes her exact flex and applies it to his skill. EMOJI BOOKENDING -- same 😌 from opener returns.',
    description: 'Equate your skill to her dominance using her own words',
  },
  {
    id: 'RECOVERY-A',
    category: TemplateCategory.GENERIC,
    lineMode: 'twoThree',
    weight: 8,
    lines: [
      "😭 wow I'm really not off to a great start here",
      'More proof I save all the {quality} for real life tho...',
    ],
    placeholders: {
      quality: 'Whatever she called out (soul, game, charm, spelling)',
    },
    technique: 'RECOVERY. Self-deprecate IMMEDIATELY when teased. Then pivot weakness to STRENGTH pointing toward meeting. "save for real life" = reason to go on the date.',
    description: 'Universal recovery when teased about a mistake',
  },
  {
    id: 'TRAV-23LINE-A',
    category: TemplateCategory.TRAVELING,
    lineMode: 'twoThree',
    weight: 9,
    lines: [
      'Down — soo we starting with a date first or just flying out to {specific_city} this weekend?',
    ],
    placeholders: {
      specific_city: 'Specific city within destination (Florence, Rome, Barcelona)',
    },
    technique: 'BOTH-OPTIONS-ARE-YES. Two options but both = date happening. Gets more specific (country → city). "soo" = casual.',
    description: 'Travel continuation -- both options lead to date',
  },
  {
    id: 'TRAV-23LINE-B',
    category: TemplateCategory.TRAVELING,
    lineMode: 'twoThree',
    weight: 9,
    lines: [
      'alr so we flying out this weekend?',
      'or do we have to like do a first date or something first 🙄',
    ],
    placeholders: {},
    technique: 'Trip = exciting, date = boring obligation. Eye roll makes date sound like annoying formality. She\'s incentivized to pick the fun option.',
    description: 'Travel follow-up -- frame date as boring compared to trip',
  },
];

// ============================================================
// 3+ LINE TEMPLATES (16 total)
// ============================================================

const THREE_PLUS_LINE_TEMPLATES: Template[] = [
  {
    id: 'CALLBACK-CTA-A',
    category: TemplateCategory.GENERIC,
    lineMode: 'threePlus',
    weight: 6,
    lines: [
      'Haha well...',
      "It wouldn't mean much if I called you {her_claim} just from just ur profile",
      "And I'm picky, so when I call u {her_claim} after the first date it'll mean something ;-)",
      'So how bout we try that and see if it leads to the {callback_topic} 🤷‍♂️',
    ],
    placeholders: {
      her_claim: "Whatever she's claiming to be or wants to be called (special, etc.)",
      callback_topic: 'Original activity/challenge from opener (breath holding contest, etc.)',
    },
    technique: 'EARN-IT FRAME + CALLBACK CTA. Explains selectiveness protects the compliment. Promises she WILL get the label after the date. Callbacks to original topic to close the loop.',
    description: 'Gate the compliment behind a date + callback to original topic',
  },
  {
    id: 'DATE-GATE-B',
    category: TemplateCategory.GENERIC,
    lineMode: 'threePlus',
    weight: 7,
    lines: [
      "I'll save the {promised_thing} for a possible second date... so what are we thinking for the first?",
    ],
    placeholders: {
      promised_thing: "Whatever was offered/discussed (the dish, the lesson, the activity)",
    },
    technique: 'BIDIRECTIONAL DATE-GATE. Gates YOUR OWN offer behind date #2. "what are we thinking" = collaborative, assumes it\'s happening.',
    description: 'Gate your own offer to create first date CTA',
  },
  {
    id: 'ACTIVITY-SUGGEST-A',
    category: TemplateCategory.PHYSICAL_ACTIVITY,
    lineMode: 'threePlus',
    weight: 5,
    lines: [
      'What about {specific_activity}? {emoji}',
      '{brief_personal_experience}',
      "I'm down for either that or {alternative}, unless you're feeling a bit {adjective} {emoji}",
    ],
    placeholders: {
      specific_activity: 'Concrete activity suggestion (pottery painting, etc.)',
      emoji: 'Relevant emoji',
      brief_personal_experience: 'One sentence about doing it before',
      alternative: 'Lower-key alternative (lunch, coffee)',
      adjective: 'Light challenge adjective (artsy, adventurous)',
    },
    technique: 'Suggests specific activity (not vague). Personal experience = credibility. Alternative gives choice but fun option is clearly the exciting one.',
    description: 'Specific activity suggestion with credibility and choice',
  },
  {
    id: 'NUMBER-CLOSE-A',
    category: TemplateCategory.GENERIC,
    lineMode: 'threePlus',
    weight: 8,
    lines: [
      'So down :)',
      'You free {day}, like {time_window}?',
      '{casual_excuse}',
      'My number is {number} — I actually do see my texts lol',
    ],
    placeholders: {
      day: 'Specific day (this Sunday, Thursday)',
      time_window: 'Time range (early afternoon, evening)',
      casual_excuse: 'Optional casual reason for delay (sorry just back on here)',
      number: "User's phone number",
    },
    technique: 'Proposes specific day AND time (confident). Moving to text with joke about actually reading texts gives reason to leave app.',
    description: 'Universal logistics close + number exchange',
  },
  {
    id: 'HOST-CLOSE-A',
    category: TemplateCategory.GENERIC,
    lineMode: 'threePlus',
    weight: 7,
    lines: [
      "I'm so down",
      '{casual_excuse}',
      '{number} - I do see texts tho :)',
      'what about something like this {day}?',
      'For {activity}, I\'ve got a {amenity} and {amenity_2}',
    ],
    placeholders: {
      casual_excuse: 'App excuse',
      number: 'Phone number',
      day: 'Specific day',
      activity: 'Planned activities',
      amenity: 'Specific amenity at their place',
      amenity_2: 'Second amenity',
    },
    technique: 'Sells the EXPERIENCE of coming over. Lists specific amenities so she can visualize the date. Combines two activities = event not just hangout.',
    description: 'Host date close with specific amenities',
  },
  {
    id: 'PHYS-MIDCONV-A',
    category: TemplateCategory.PHYSICAL_ACTIVITY,
    lineMode: 'threePlus',
    weight: 7,
    lines: [
      'Oh sick, also {match_activity} would be a cool second date...',
      'Just saw that — do you know any good spots in {local_area}?',
      'I always have to go to {farther_locations} to find anything decent',
    ],
    placeholders: {
      match_activity: "Activity from match's profile",
      local_area: 'Shared geographic area',
      farther_locations: 'Places user goes for this activity',
    },
    technique: 'MID-CONVERSATION CATEGORY SWITCH. "second date" = first is already locked. Shares experience = credibility. Creates second date plan organically.',
    description: 'Introduce second category mid-chat as future date',
  },
  {
    id: 'SARC-DIALOGUE-A',
    category: TemplateCategory.SARCASTIC_AMBITION,
    lineMode: 'threePlus',
    weight: 5,
    lines: [
      'I like where ur heads at',
      'But was thinking more like {escalated_version}',
      '{additional_absurd_detail}',
      'The real question is, between you and I— who\'s the {leadership_role}...',
    ],
    placeholders: {
      escalated_version: "User's one-up of match's idea (same theme, bigger/funnier)",
      additional_absurd_detail: 'Another layer of absurdity building on line 2',
      leadership_role: 'Competitive role (cult leader, supreme ruler, president)',
    },
    technique: 'YES-AND ESCALATION. Validate → one-up → absurd detail → competitive closer. Creates tension needing resolution (= date).',
    description: 'Improv escalation of shared absurd fantasy',
  },
  {
    id: 'SARC-CTA-A',
    category: TemplateCategory.SARCASTIC_AMBITION,
    lineMode: 'threePlus',
    weight: 7,
    lines: [
      'Hmm',
      'Maybe instead of {her_proposed_conflict}, the first date will settle the beef 🤔',
      'Then we plan our {shared_mission_next_step}',
      'Has to be a {dramatic_requirement} tho...',
    ],
    placeholders: {
      her_proposed_conflict: 'Whatever competitive thing she suggested (fight, duel)',
      shared_mission_next_step: 'Next chapter of shared bit (rebellion, world takeover)',
      dramatic_requirement: 'In-character condition (top secret location, underground bunker)',
    },
    technique: 'IN-CHARACTER CTA. Date becomes next episode of the story. "settle the beef" stays in language. Future-assumes past the first date.',
    description: 'Date as next scene in the shared story',
  },
  {
    id: 'SARC-CTA-B',
    category: TemplateCategory.SARCASTIC_AMBITION,
    lineMode: 'threePlus',
    weight: 6,
    lines: [
      'Ok ok fair enough, I appreciate the {thing_she_granted} 😔',
      'Although, the whole point of a {the_bit} is it\'s built for in-person, bec {romantic_justification}',
      'So maybe you\'ll have to {come_to_date_in_character}, or it just wouldn\'t be the same 🧑‍💼',
    ],
    placeholders: {
      thing_she_granted: 'Whatever power she exercised (grace period, second chance)',
      the_bit: 'Running narrative object (pitch, cult meeting)',
      romantic_justification: 'Why it must be in person (a real pitch comes from the soul)',
      come_to_date_in_character: 'Date ask in-character (swing by the office, come to HQ)',
    },
    technique: 'LOGICALLY JUSTIFIED CTA. Uses bit\'s internal logic to REQUIRE meeting. "the whole point is it\'s in person" = not a request, a structural necessity.',
    description: 'Use the bit\'s logic to make meeting a requirement',
  },
  {
    id: 'MUSIC-RECOVERY-CTA-A',
    category: TemplateCategory.MUSIC,
    lineMode: 'threePlus',
    weight: 4,
    lines: [
      'oh shit',
      "I'm def not winning the {skill_comparison} flex lmao",
      'however!',
      '{user_unique_angle}',
      "So that's my little flex",
      'So how about first date I {user_skill_offer}, then you teach me how to {match_skill_offer} 🤔',
    ],
    placeholders: {
      skill_comparison: "Domain she outclassed him in (musician, athlete)",
      user_unique_angle: 'His spin on same skill (plays by ear without reading notes)',
      user_skill_offer: 'What he brings (cook u dinner)',
      match_skill_offer: 'What she teaches (actually read the keys)',
    },
    technique: 'RECOVERY + EXCHANGE CTA. Take the L, find unique angle, make the gap the REASON for the date. Both contribute = peer-level.',
    description: 'When outclassed: take the L, propose skills exchange date',
  },
  {
    id: 'TRAV-BRIDGE-A',
    category: TemplateCategory.TRAVELING,
    lineMode: 'threePlus',
    weight: 5,
    lines: [
      '{one_more_beat_in_bit}...',
      'Although low key, if you like {real_activity}',
      '{casual_date_intro}',
      '{tangible_details}',
      'Kinda {acknowledge_forward}, but if we\'re already {callback_to_absurd} this honestly seems like a pretty chill first step',
    ],
    placeholders: {
      one_more_beat_in_bit: 'Stay in the bit one more line (I wouldn\'t mind some airport snacks actually)',
      real_activity: "Doable activity from her profile (wine nights with painting)",
      casual_date_intro: 'Tangible date idea introduced casually',
      tangible_details: 'Details that make it real (canvas, cook pasta together)',
      acknowledge_forward: "Self-aware it's bold (relationship vibes)",
      callback_to_absurd: 'Reference running fantasy (moving to Italy together)',
    },
    technique: 'ABSURD-TO-REAL BRIDGE. Fantasy justifies real date. "If we\'re already moving to Italy, painting is chill." The absurdity makes the real ask feel small.',
    description: 'Transition travel fantasy to real date using absurdity as justification',
  },
  {
    id: 'TRAV-ESCALATE-A',
    category: TemplateCategory.TRAVELING,
    lineMode: 'threePlus',
    weight: 8,
    lines: [
      "That's valid",
      'I booked us flights alr',
      'Send ur email so I can forward them',
      'Separate flights tho bec I wanted biz class so see u in {destination}',
    ],
    placeholders: {
      destination: 'Travel destination',
    },
    technique: 'ACCEPT THE MISSION + CONTACT EXTRACTION. Treats absurd as done. Extracts email naturally. "biz class" setup for generous flip.',
    description: 'Execute the travel bit + extract contact info',
  },
  {
    id: 'FLIP-GENTLEMAN-A',
    category: TemplateCategory.GENERIC,
    lineMode: 'threePlus',
    weight: 9,
    lines: [
      'na I got you first class 😌',
      'Took one for the team ☝️',
    ],
    placeholders: {},
    technique: 'SETUP SELFISH, REVEAL GENEROUS. Previous message set up selfish expectation. Now reveals she\'s actually above him. Manufactured contrast amplifies sweetness.',
    description: 'Flip from selfish setup to generous reveal',
  },
  {
    id: 'RECOVERY-B',
    category: TemplateCategory.GENERIC,
    lineMode: 'threePlus',
    weight: 7,
    lines: [
      '{enthusiastic_agreement}',
      '{validate_her_contribution}',
      'I will warn you though, I am not the most talented {activity_skill}...',
      'I can make it up with my {user_strength} tho',
      "What's this weekend looking like for u?",
    ],
    placeholders: {
      enthusiastic_agreement: 'Short agreement (So down!)',
      validate_her_contribution: "Acknowledge what she's bringing (Red wine is definitely the move)",
      activity_skill: 'Skill she\'s better at (artist, painter)',
      user_strength: 'User\'s compensating strength (cooking skills)',
    },
    technique: 'Self-deprecate on weakness → immediately pivot to compensating strength → direct logistics.',
    description: 'Weakness admission + strength pivot + logistics close',
  },
  {
    id: 'EXER-3PLUS-A',
    category: TemplateCategory.EXERCISE,
    lineMode: 'threePlus',
    weight: 7,
    lines: [
      'May not be a gym rat yet',
      "but I'm an up and coming one...",
      'low key could learn a thing or two from u',
      'maybe before we hit the gym the first date could be half date and half consulting 🤔',
    ],
    placeholders: {},
    technique: 'Self-deprecating entry (humility) → "learn from you" (flattery without eagerness) → CTA disguised as joke (half date half consulting).',
    description: 'Humble gym approach with consulting date CTA',
  },
  {
    id: 'TRAV-3PLUS-A',
    category: TemplateCategory.TRAVELING,
    lineMode: 'threePlus',
    weight: 8,
    lines: [
      'Alr so I booked our tickets to {match_travel_place}',
      'So do we want to start with a first date or just like save the dialogue for the security line',
      'Although there was only one business class seat left so we may have to rock paper scissors for that...',
    ],
    placeholders: {
      match_travel_place: "Destination from match's profile",
    },
    technique: 'Future-assuming trip is happening. Jokes about skipping first date. Business class competition = cocky with humility. Leads naturally to first date mention.',
    description: 'Presumptuous trip booking with competitive framing',
  },
];

// ============================================================
// UNIVERSAL PATTERNS (27 total)
// ============================================================

export const UNIVERSAL_PATTERNS: UniversalPattern[] = [
  { id: 'DATE_GATE', name: 'Date Gate', description: 'Gate an activity behind a future date to create anticipation', example: "We'll have to save that for date #2 -- I only do that when I know they're one of the special ones", applicableLineModes: ['twoThree', 'threePlus'], applicableCategories: 'ALL' },
  { id: 'BIDIRECTIONAL_DATE_GATE', name: 'Bidirectional Date Gate', description: 'Works gating HER thing OR YOUR thing', example: "I'll save the dish for a possible second date... so what are we thinking for the first?", applicableLineModes: ['twoThree', 'threePlus'], applicableCategories: 'ALL' },
  { id: 'CALLBACK_CTA', name: 'Callback CTA', description: 'Reference the original opener topic to close the date ask', example: 'So how bout we try that and see if it leads to the breath holding contest', applicableLineModes: ['threePlus'], applicableCategories: 'ALL' },
  { id: 'EARN_IT_FRAME', name: 'Earn It Frame', description: "I'm picky, so when I call you X it'll mean something", example: "And I'm picky, so when I call u special after the first date it'll mean something", applicableLineModes: ['threePlus'], applicableCategories: 'ALL' },
  { id: 'IN_CHARACTER_CTA', name: 'In-Character CTA', description: 'Never break the bit. Date becomes the next scene of the story', example: 'Maybe instead of fight, the first date will settle the beef', applicableLineModes: ['threePlus'], applicableCategories: [TemplateCategory.SARCASTIC_AMBITION] },
  { id: 'YES_AND_ESCALATION', name: 'Yes-And Escalation', description: 'Validate → one-up → absurd detail → competitive closer', example: "I like where ur heads at / But was thinking more like... / The real question is who's the cult leader", applicableLineModes: ['threePlus'], applicableCategories: [TemplateCategory.SARCASTIC_AMBITION] },
  { id: 'ACCEPT_THE_MISSION', name: 'Accept the Mission', description: 'When match issues a challenge, immediately start executing with a timeline', example: "send me ur email and I'll have it to you by Monday 🫡", applicableLineModes: ['one', 'twoThree'], applicableCategories: [TemplateCategory.SARCASTIC_AMBITION, TemplateCategory.TRAVELING] },
  { id: 'SUSTAINED_CHARACTER', name: 'Sustained Character', description: 'Bits survive days of silence. Each message is a new episode.', example: 'Oh shit, I missed my deadline / Maybe I can have an extension', applicableLineModes: ['twoThree', 'threePlus'], applicableCategories: [TemplateCategory.SARCASTIC_AMBITION] },
  { id: 'LOGICALLY_JUSTIFIED_CTA', name: 'Logically Justified CTA', description: "Use the bit's internal logic to require meeting up", example: "the whole point of a pitch is it's built for in-person", applicableLineModes: ['threePlus'], applicableCategories: [TemplateCategory.SARCASTIC_AMBITION] },
  { id: 'CROSS_CATEGORY_ENTRY', name: 'Cross-Category Entry', description: 'Enter via one category, deliver via another', example: "Her FUTURE_PROMISES prompt → deliver via FOOD (I can't promise the soulmate part yet, but the Italian dish...)", applicableLineModes: ['twoThree', 'threePlus'], applicableCategories: 'ALL' },
  { id: 'CHOICE_TECHNIQUE', name: 'Choice Technique', description: '"A or B?" instead of "yes or no?" Once she picks, she\'s in.', example: 'We cooking pasta or lasagna tho?', applicableLineModes: ['one', 'twoThree'], applicableCategories: 'ALL' },
  { id: 'SO_THING_WHEN', name: '"So {thing} when?"', description: 'Most direct CTA. Two words. Only when vibe is established.', example: 'So dinner when?', applicableLineModes: ['twoThree'], applicableCategories: 'ALL' },
  { id: 'MID_CONV_CATEGORY_SWITCH', name: 'Mid-Conversation Category Switch', description: 'Introduce a 2nd category mid-chat, date-gate it as future date', example: 'Oh sick, also rock climbing would be a cool second date...', applicableLineModes: ['threePlus'], applicableCategories: 'ALL' },
  { id: 'CULTURAL_MIRRORING', name: 'Cultural Mirroring', description: 'When she mirrors your culture, mirror back and deepen', example: 'She says "ciao bello" → he responds "Ciao bella :) hai anche un po\' di origini italiane?"', applicableLineModes: ['threePlus'], applicableCategories: [TemplateCategory.FOOD, TemplateCategory.TRAVELING] },
  { id: 'EXCHANGE_CTA', name: 'Exchange CTA', description: "I'll do X, you teach me Y. Trade of equals.", example: "So how about first date I cook u dinner, then you teach me how to actually read the keys", applicableLineModes: ['threePlus'], applicableCategories: [TemplateCategory.MUSIC, TemplateCategory.FOOD] },
  { id: 'CALLBACK_HER_WORDS', name: 'Callback to Her Words', description: 'Repurpose her exact phrasing for yourself', example: "so you could def say I'm classically trained 😌", applicableLineModes: ['twoThree', 'threePlus'], applicableCategories: 'ALL' },
  { id: 'EMOJI_BOOKENDING', name: 'Emoji Bookending', description: 'Same emoji in opener and closer for narrative continuity', example: '😌 in "I\'ll teach u 😌" and later "classically trained 😌"', applicableLineModes: ['twoThree', 'threePlus'], applicableCategories: 'ALL' },
  { id: 'ABSURD_TO_REAL_BRIDGE', name: 'Absurd-to-Real Bridge', description: 'Use running fantasy as justification for actual date', example: "if we're already moving to Italy together this honestly seems like a pretty chill first step", applicableLineModes: ['threePlus'], applicableCategories: [TemplateCategory.TRAVELING, TemplateCategory.SARCASTIC_AMBITION] },
  { id: 'BOTH_OPTIONS_YES', name: 'Both-Options-Are-Yes', description: 'Give two options where both result in date happening', example: 'soo we starting with a date first or just flying out to Florence this weekend?', applicableLineModes: ['twoThree'], applicableCategories: [TemplateCategory.TRAVELING] },
  { id: 'SETUP_SELFISH_REVEAL_GENEROUS', name: 'Setup Selfish, Reveal Generous', description: 'Act cocky/selfish → reveal you actually put her first', example: 'Separate flights bec I wanted biz class → na I got you first class 😌', applicableLineModes: ['threePlus'], applicableCategories: 'ALL' },
  { id: 'RECOVERY_OUTCLASSED', name: 'Recovery When Outclassed', description: "Take the L, find your unique angle, make the gap the REASON for the date", example: "oh shit / I'm def not winning the musician flex / however! / I don't know any notes, just know songs by sounds / So that's my little flex", applicableLineModes: ['threePlus'], applicableCategories: [TemplateCategory.MUSIC, TemplateCategory.EXERCISE] },
  { id: 'SELF_REFERENTIAL_REDIRECT', name: 'Self-Referential Redirect', description: 'Point back at your own profile as the answer to her criteria', example: 'my entire profile was built around this answer...', applicableLineModes: ['one'], applicableCategories: [TemplateCategory.GENERIC] },
  { id: 'VALIDATE_FLAW_SUPERPOWER', name: 'Validate Flaw as Superpower', description: 'Reframe her self-deprecation as philosophy', example: 'Procrastination spawns the best creation', applicableLineModes: ['one'], applicableCategories: [TemplateCategory.OPINIONS] },
  { id: 'COUNTER_OFFER_SUBSTITUTE', name: 'Counter-Offer Substitute', description: 'She wants X, you offer your cultural equivalent', example: 'with prosecco do?', applicableLineModes: ['one'], applicableCategories: [TemplateCategory.FOOD] },
  { id: 'INVERT_TEACH_FRAME', name: 'Invert the Teach Frame', description: 'Flip from authority to student when activity is her world', example: 'can u teach me how to rave...', applicableLineModes: ['one'], applicableCategories: [TemplateCategory.PHYSICAL_ACTIVITY] },
  { id: 'IGNORE_OPTIONS_CREATE_OWN', name: 'Ignore All Options, Create Your Own', description: "When she lists choices, don't pick any — one-up with bigger", example: "I'd watch the world collapse from space", applicableLineModes: ['one'], applicableCategories: [TemplateCategory.SARCASTIC_AMBITION, TemplateCategory.OPINIONS] },
  { id: 'ANTI_HUMOR_COMMITMENT', name: 'Anti-Humor Commitment', description: 'Most literal/basic response IS the joke', example: 'knock knock', applicableLineModes: ['one'], applicableCategories: [TemplateCategory.GENERIC] },
];

// ============================================================
// ALL TEMPLATES COMBINED
// ============================================================

export const ALL_TEMPLATES: Template[] = [
  ...ONE_LINE_TEMPLATES,
  ...TWO_THREE_LINE_TEMPLATES,
  ...THREE_PLUS_LINE_TEMPLATES,
];

// ============================================================
// HELPER FUNCTIONS
// ============================================================

export function getTemplatesByCategory(category: TemplateCategory, lineMode: LineMode): Template[] {
  return ALL_TEMPLATES.filter(t => t.category === category && t.lineMode === lineMode);
}

export function getGenericTemplates(lineMode: LineMode): Template[] {
  return ALL_TEMPLATES.filter(t => t.category === TemplateCategory.GENERIC && t.lineMode === lineMode);
}

export function getAllTemplatesForLineMode(lineMode: LineMode): Template[] {
  return ALL_TEMPLATES.filter(t => t.lineMode === lineMode);
}

export function getTemplateById(id: string): Template | undefined {
  return ALL_TEMPLATES.find(t => t.id === id);
}
