# OnePercent Design Language

Design reference for maintaining visual consistency across the app.

## Philosophy

**Premium, effortless, clean.** Bold black/white with muted indigo accent - sophisticated but approachable. Never flashy or "app store slop."

---

## Color System

### Light Mode

| Token | Hex | RGB | Tailwind | Usage |
|-------|-----|-----|----------|-------|
| `accent` | #6366F1 | 99, 102, 241 | indigo-500 | Buttons, icons, links, interactive elements |
| `accentLight` | #EEF2FF | 238, 242, 255 | indigo-50 | Subtle backgrounds for accent contexts |
| `textPrimary` | #0A0A0A | 10, 10, 10 | neutral-950 | Headings, body text (true near-black) |
| `textSecondary` | #737373 | 115, 115, 115 | neutral-500 | Subtitles, helper text |
| `textMuted` | #A3A3A3 | 163, 163, 163 | neutral-400 | Meta info, timestamps, disabled |
| `background` | #FFFFFF | 255, 255, 255 | white | Main app background |
| `backgroundSecondary` | #FAFAFA | 250, 250, 250 | neutral-50 | Cards, sections, inputs |
| `card` | #FFFFFF | 255, 255, 255 | white | Elevated card surfaces |
| `border` | #E5E5E5 | 229, 229, 229 | neutral-200 | Subtle borders, dividers |

### Dark Mode

| Token | Hex | RGB | Tailwind | Usage |
|-------|-----|-----|----------|-------|
| `accent` | #818CF8 | 129, 140, 248 | indigo-400 | Indigo accent for dark bg contrast |
| `accentLight` | #1E1B4B | 30, 27, 75 | indigo-950 | Dark accent backgrounds |
| `textPrimary` | #FAFAFA | 250, 250, 250 | neutral-50 | Light text on dark |
| `textSecondary` | #A3A3A3 | 163, 163, 163 | neutral-400 | Secondary text |
| `textMuted` | #737373 | 115, 115, 115 | neutral-500 | Muted text |
| `background` | #0A0A0A | 10, 10, 10 | neutral-950 | Main dark background (true black) |
| `backgroundSecondary` | #171717 | 23, 23, 23 | neutral-900 | Elevated surfaces |
| `card` | #171717 | 23, 23, 23 | neutral-900 | Card surfaces |
| `border` | #262626 | 38, 38, 38 | neutral-800 | Dark mode borders |

### Semantic Colors (Both Modes)

| Token | Hex | Usage |
|-------|-----|-------|
| `success` | #10B981 | Positive states, confirmations |
| `warning` | #F59E0B | Warnings, required fields |
| `error` | #EF4444 | Errors, destructive actions |

---

## Typography

Use system fonts (San Francisco on iOS). No custom fonts needed.

| Style | Weight | Size | Usage |
|-------|--------|------|-------|
| Title | Bold | 32pt | Main screen titles |
| Headline | Semibold | 17pt | Section headers, buttons |
| Body | Regular | 17pt | Body text |
| Subheadline | Medium | 15pt | Labels, row titles |
| Caption | Regular | 12pt | Helper text, timestamps |

---

## Spacing & Layout

### Corner Radii
- **Small**: 8pt - Icon backgrounds, small badges
- **Medium**: 12pt - Buttons, inputs, cards
- **Large**: 16pt - Large cards, modals
- **XLarge**: 20pt - Bottom sheets

### Spacing Scale
- 4pt, 8pt, 12pt, 16pt, 20pt, 24pt, 32pt, 48pt

### Safe Areas
- Always use `.ignoresSafeArea()` on backgrounds
- Respect safe area for content

---

## Shadows

Keep shadows subtle and refined.

```swift
// Light shadow (most cards)
.shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)

// Medium shadow (elevated cards, modals)
.shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
```

Dark mode: Same shadows work due to low opacity.

---

## Animation

### Principles
1. **Easing**: `easeOut` or `linear` - NO bouncy springs
2. **Feel**: Fluid, responsive, effortless
3. **Speed**: Fast enough to feel responsive, slow enough to notice

### Timing
| Type | Duration | Usage |
|------|----------|-------|
| Micro | 0.2-0.3s | Button presses, toggles |
| Entrance | 0.4-0.5s | Screen transitions, modals |
| Stagger delay | 0.06-0.1s | Between list items |

### Entrance Pattern
```swift
// Fade + scale for logos/icons
.opacity(visible ? 1 : 0)
.scaleEffect(visible ? 1 : 0.9)

// Fade + slide for content
.opacity(visible ? 1 : 0)
.offset(y: visible ? 0 : 10)
```

---

## Components

### Primary Button
- Background: `accent` (solid, no gradient)
- Text: White, semibold
- Height: ~50pt
- Corner radius: Medium (12pt)
- Press state: 0.98 scale, 0.9 opacity

### Secondary Button
- Background: `accentLight`
- Text: `accent` color, medium weight
- Same dimensions as primary

### Input Fields
- Background: `backgroundSecondary`
- Border: `border` color, 1pt
- Corner radius: Medium (12pt)
- Focus state: `accent` border

### Cards
- Background: `card`
- Shadow: Light shadow
- Corner radius: Large (16pt)
- Padding: 16pt internal

### Icon Buttons
- Size: 44x44pt (touch target)
- Icon size: ~20pt
- Background: `accentLight`
- Icon color: `accent`
- Corner radius: Small (8pt)

---

## Logo Usage

### Welcome Screen
- Use the app icon image (with depth effect from Icon Composer)
- Size: 80-100pt
- Centered, prominent

### In-App
- Smaller instances can use text "1%" or simplified icon
- Keep consistent with app icon aesthetic

---

## Do's and Don'ts

### Do
- Keep it clean and minimal
- Use plenty of white space
- Let content breathe
- Make interactions feel instant
- Support both light and dark modes

### Don't
- Use gradients anywhere (solid colors only)
- Add bouncy/springy animations (feels slow)
- Overcrowd screens with elements
- Use heavy shadows
- Make users wait for animations to complete
- Use blue-tinted greys (stick to pure neutrals)
