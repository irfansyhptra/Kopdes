---
name: apple-inspired-ui
description: Design or refine responsive web and app interfaces with a polished Apple- and macOS-inspired visual language. Use for UI generation, redesigns, prototypes, dashboards, landing pages, settings screens, and design-system guidance; do not use to reproduce Apple products, trademarks, or proprietary assets exactly.
---

# Apple-Inspired UI

Create calm, premium, highly legible interfaces inspired by the design qualities associated with Apple platforms: clarity, deference, depth, precise spacing, restrained color, and purposeful motion. Preserve the user's product identity and requirements rather than turning every result into a macOS clone.

## Working method

1. Identify the target platform, viewport, content hierarchy, primary task, and implementation stack from the request. Infer sensible defaults when these do not materially change the result.
2. Establish the information architecture and key user flow before styling. Keep the primary action unmistakable and remove decoration that competes with content.
3. Read [references/visual-system.md](references/visual-system.md) before producing visual specifications or code. Apply only the patterns appropriate to the target platform.
4. Build reusable tokens and components. Prefer semantic names such as `surface`, `text-primary`, and `accent` over hard-coded one-off styling.
5. Implement responsive, accessible behavior and the important interaction states: default, hover where applicable, focus-visible, pressed, selected, disabled, loading, empty, and error.
6. Review the output at small and large viewports. Check hierarchy, alignment, contrast, keyboard navigation, reduced-motion behavior, overflow, and touch-target sizes.

## Design direction

- Favor generous negative space, crisp alignment, short line lengths, and a small number of strong visual layers.
- Use a system-font stack. Match typography to the platform instead of requiring proprietary Apple font files.
- Use translucency only when it communicates layering or persistent navigation. Always provide a solid fallback and retain readable contrast.
- Prefer soft elevation, hairline borders, and tonal separation over heavy shadows or excessive outlines.
- Use one product accent color plus semantic status colors. Let content, imagery, and hierarchy carry the design.
- Keep corner radii related and proportional. Do not make every container a floating rounded card.
- Use concise, direct interface copy. Labels should describe actions and states, not visual metaphors.
- Make motion subtle, interruptible, and functional. Respect `prefers-reduced-motion`.

## Platform adaptation

- For desktop web or macOS-like tools, use a restrained toolbar/sidebar/content structure when the workflow warrants it. Support dense information without sacrificing scanability.
- For mobile web or native-like mobile layouts, prioritize thumb reach, safe-area spacing, bottom actions where suitable, and touch targets of at least 44 by 44 CSS pixels.
- For marketing pages, translate the same principles into editorial typography, focused storytelling, strong imagery, and progressive disclosure; do not imitate operating-system chrome.
- For dashboards, preserve data density and comparison. Avoid blur, oversized titles, and decorative cards that weaken analytical clarity.

## Output requirements

When the user requests code, deliver a functional interface using the existing project conventions. Reuse the project's components and tokens where possible. Do not add a large UI dependency solely to achieve the look.

When the user requests a prompt or design specification, include layout, typography, color roles, materials, component behavior, responsive rules, interaction states, and accessibility requirements. Use concrete values as a coherent starting system, not as inflexible laws.

When reference material is supplied, preserve its content and functional intent while improving hierarchy and finish. Never claim the output is an official Apple design or use Apple logos, product screenshots, exact proprietary icons, or copied trade dress unless the user has supplied authorized assets and explicitly requests their use.

## Quality gate

Before finishing, confirm that:

- The screen has one clear primary purpose and action.
- Visual depth corresponds to actual interface hierarchy.
- Text and controls remain legible without transparency effects.
- Repeated dimensions derive from shared tokens.
- Responsive behavior is defined rather than merely scaled.
- Keyboard focus, contrast, touch size, motion preference, and semantic structure are handled.
- The result feels refined and restrained while remaining recognizably the user's product.
