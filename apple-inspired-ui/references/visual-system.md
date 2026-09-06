# Apple-Inspired Visual System

Use this reference as a practical starting point. Adapt values to the product, brand, content density, and framework already in use.

## Foundations

### Typography

Use the platform system stack:

```css
font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
```

| Role | Size / line height | Weight | Use |
| --- | --- | --- | --- |
| Display | `48–64px / 1.02–1.08` | 650–750 | Short marketing statement |
| Page title | `32–40px / 1.1–1.2` | 650–700 | Main page heading |
| Section title | `22–28px / 1.2` | 600–700 | Section hierarchy |
| Body | `15–17px / 1.45–1.6` | 400–450 | Reading and UI copy |
| Label | `13–14px / 1.25–1.4` | 500–600 | Controls and metadata |
| Caption | `11–12px / 1.3–1.45` | 450–550 | Secondary metadata |

Use tighter tracking only for large headings. Avoid ultra-light text and long centered paragraphs.

### Spacing and shape

Base spacing tokens: `4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80`.

- Compact control radius: `8–10px`
- Standard control radius: `10–12px`
- Card or panel radius: `14–20px`
- Hero or large media radius: `24–32px`
- Hairline border: `1px`, preferably translucent or tonal
- Minimum pointer/touch target: `44 × 44px`

Use nested radii consistently: an inner element's radius should generally be the outer radius minus its inset.

### Color roles

Define semantic variables for both schemes. Example starting point:

```css
:root {
  color-scheme: light dark;
  --bg: #f5f5f7;
  --surface: rgba(255, 255, 255, 0.78);
  --surface-solid: #ffffff;
  --text: #1d1d1f;
  --text-secondary: #6e6e73;
  --separator: rgba(60, 60, 67, 0.18);
  --accent: #007aff;
  --success: #248a3d;
  --warning: #b25000;
  --danger: #d70015;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #000000;
    --surface: rgba(36, 36, 38, 0.76);
    --surface-solid: #1c1c1e;
    --text: #f5f5f7;
    --text-secondary: #a1a1a6;
    --separator: rgba(84, 84, 88, 0.65);
    --accent: #0a84ff;
    --success: #30d158;
    --warning: #ff9f0a;
    --danger: #ff453a;
  }
}
```

Treat these values as neutral defaults. Replace the accent with the user's brand color and verify contrast in every state.

## Materials and elevation

Translucent material is appropriate for a top bar, sidebar, floating control group, sheet, or overlay that sits above moving content. It is usually not appropriate for every content card.

```css
.material {
  background: var(--surface);
  border: 1px solid var(--separator);
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.10);
  -webkit-backdrop-filter: saturate(160%) blur(20px);
  backdrop-filter: saturate(160%) blur(20px);
}

@supports not ((backdrop-filter: blur(1px))) {
  .material { background: var(--surface-solid); }
}
```

Use one or two elevation levels per screen. Stronger elevation should indicate a genuinely higher interaction layer, such as a popover or modal.

## Layout patterns

### Desktop productivity

- Optional title or toolbar: `52–64px` high.
- Sidebar: approximately `220–280px`, collapsible when useful.
- Reading/content width: usually `640–880px`; dashboards may be wider.
- Use dividers, section headers, and alignment before introducing more cards.

### Mobile

- Respect safe-area insets with `env(safe-area-inset-*)`.
- Keep primary controls reachable and persistent only when persistence adds value.
- Replace hover-only disclosure with visible or tap-accessible affordances.
- Collapse columns intentionally; reorder content according to task priority.

### Marketing

- Lead with one message and one primary action.
- Use full-bleed imagery or product visuals selectively.
- Alternate dense and quiet sections to create rhythm.
- Reveal secondary detail progressively rather than displaying every feature at once.

## Components

- Buttons: clear label, compact silhouette, visible focus ring, and distinct pressed and disabled states. Reserve filled accent for the primary action.
- Inputs: use persistent labels when ambiguity is possible; show validation next to the field and never rely on color alone.
- Navigation: communicate current location through more than a subtle color change.
- Cards: group related content. If removing the card does not harm grouping or interaction, prefer whitespace and a divider.
- Sidebars: organize by workflow and keep labels short. Avoid excessive nesting.
- Dialogs and sheets: state the consequence, keep actions predictable, trap focus appropriately, and restore focus on close.
- Icons: use one consistent outline or filled family available to the project. Pair unfamiliar icons with labels.

## Motion

- Micro-interactions: roughly `120–180ms`.
- Panels and sheets: roughly `220–360ms`.
- Prefer ease-out for entering and ease-in for leaving.
- Animate opacity and transforms where possible; avoid layout-heavy animation.
- Disable nonessential animation under `prefers-reduced-motion: reduce`.

## Common failure modes

- Excessive glassmorphism that lowers contrast and performance.
- A rounded rectangle around every piece of content.
- Huge headings in productivity screens.
- Apple-blue accents applied despite an established brand palette.
- Desktop chrome copied onto mobile or marketing layouts.
- Visual fidelity prioritized over semantic HTML, keyboard use, or readable states.
- Claims that a design is official, native, or identical to an Apple product.
