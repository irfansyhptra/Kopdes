---
version: 1.0.0
name: KOPDES-Marketplace-Design
description: A clean, vibrant, and trustworthy digital cooperative marketplace design. Built on a crisp white canvas (#ffffff) with deep forest ink (#1a2e22) for typography, and accented by Cooperative Emerald (#10b981) for primary calls to action, badges, and positive system states. The system features soft rounded corners, subtle shadows, and a modern typography stack featuring Outfit for headings and Plus Jakarta Sans for body text. Optimized for a highly responsive, premium web experience that adapts beautifully from mobile phones to high-resolution desktop displays.

colors:
  primary: "#10b981"          # Emerald 500 - Brand voltage, main CTA backgrounds, active states
  primary-hover: "#059669"    # Emerald 600 - Hover state for primary buttons
  primary-active: "#047857"   # Emerald 700 - Active/press state for primary buttons
  primary-disabled: "#a7f3d0" # Emerald 200 - Disabled state for primary actions
  accent-mint: "#ecfdf5"      # Mint 50 - Soft background tint for cards, alerts, and pill highlights
  accent-gold: "#f59e0b"      # Amber 500 - Ratings, warning badges, and highlight borders
  ink: "#1a2e22"              # Deep Forest Ink - Primary text, headings, and high-contrast lines
  body: "#384d40"             # Muted Forest - Running text, descriptions, and secondary labels
  muted: "#5c7365"            # Soft Sage - Placeholders, inactive tabs, and meta information
  muted-soft: "#8fa397"       # Pale Sage - Disabled text and minor details
  hairline: "#d1e2d7"         # Light Sage Stroke - Borders, dividers, and table grids
  hairline-soft: "#eaf2ed"    # Extra Light Stroke - Subtle row dividers and card borders
  canvas: "#ffffff"           # White Floor - Base web page background
  surface-soft: "#f4fbf7"     # Fresh White - Hover backgrounds and table header fills
  surface-card: "#ffffff"     # White Card - Product card and modular container background
  surface-strong: "#e6f4ea"   # Mint Tint - Stronger container fills, badge backgrounds
  on-primary: "#ffffff"       # White text on emerald buttons
  on-dark: "#ffffff"          # White text on dark green surfaces
  link-blue: "#0284c7"        # Sky 600 - Inline links for legal and support policies
  error: "#dc2626"            # Red 600 - Destructive actions, system errors, and invalid fields
  error-bg: "#fef2f2"         # Red 50 - Error container background
  scrim: "#09140e"            # Deep Scrim - 60% opacity backdrop for overlays and modal dialogs

typography:
  display-xl:
    fontFamily: "'Outfit', 'Plus Jakarta Sans', -apple-system, sans-serif"
    fontSize: 32px
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: -0.64px
  display-lg:
    fontFamily: "'Outfit', sans-serif"
    fontSize: 26px
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: -0.26px
  display-md:
    fontFamily: "'Outfit', sans-serif"
    fontSize: 22px
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: 0
  display-sm:
    fontFamily: "'Outfit', sans-serif"
    fontSize: 18px
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 0
  title-md:
    fontFamily: "'Outfit', sans-serif"
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 0
  title-sm:
    fontFamily: "'Plus Jakarta Sans', sans-serif"
    fontSize: 15px
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 0
  body-md:
    fontFamily: "'Plus Jakarta Sans', sans-serif"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: 0
  body-sm:
    fontFamily: "'Plus Jakarta Sans', sans-serif"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: 0
  caption:
    fontFamily: "'Plus Jakarta Sans', sans-serif"
    fontSize: 13px
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: 0
  caption-sm:
    fontFamily: "'Plus Jakarta Sans', sans-serif"
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: 0
  badge:
    fontFamily: "'Outfit', sans-serif"
    fontSize: 11px
    fontWeight: 700
    lineHeight: 1
    letterSpacing: 0.5px
    textTransform: uppercase
  button-md:
    fontFamily: "'Outfit', sans-serif"
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: 0
  button-sm:
    fontFamily: "'Outfit', sans-serif"
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: 0

rounded:
  none: 0px
  xs: 4px
  sm: 8px                     # Buttons, small badges, and tags
  md: 12px                    # Product cards, form fields, action dropdowns
  lg: 16px                    # Modals, slide-out panels, and core sections
  xl: 24px                    # Search bars and rounded page containers
  full: 9999px                # Circular buttons, pill tags, and search orbs

spacing:
  xxs: 2px
  xs: 4px
  sm: 8px
  md: 12px
  base: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  section: 80px               # Generous vertical space for web sections

components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button-md}"
    rounded: "{rounded.sm}"
    padding: 12px 24px
    height: 48px
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
    textColor: "{colors.on-primary}"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    borderColor: "{colors.primary}"
    borderWidth: 1.5px
    typography: "{typography.button-md}"
    rounded: "{rounded.sm}"
    padding: 10px 22px
    height: 48px
  search-bar:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.ink}"
    rounded: "{rounded.full}"
    borderColor: "{colors.hairline}"
    borderWidth: 1px
    height: 56px
  product-card:
    backgroundColor: "{colors.surface-card}"
    borderColor: "{colors.hairline-soft}"
    borderWidth: 1px
    rounded: "{rounded.md}"
    shadow: "0 2px 8px rgba(26, 46, 34, 0.04)"
  product-card-hover:
    borderColor: "{colors.hairline}"
    shadow: "0 10px 20px rgba(26, 46, 34, 0.08)"
    transform: "translateY(-4px)"
  badge-tag:
    backgroundColor: "{colors.surface-strong}"
    textColor: "{colors.primary-hover}"
    rounded: "{rounded.xs}"
    padding: 4px 8px
  footer:
    backgroundColor: "#0d2116" # Very dark green footer for premium website feel
    textColor: "{colors.on-dark}"
    padding: 64px 24px
---

## 1. Overview & Identity

This design system is tailored for a highly responsive, modern digital village cooperative website marketplace (**KOPDES**). The visual identity is anchored in **trust, growth, and community**, utilizing a fresh and premium green color scheme.

The canvas is a pristine white (`{colors.canvas}`) contrasted by **Deep Forest Ink** (`{colors.ink}`) for typography, which replaces generic blacks to create a rich, natural feeling. The main brand element is **Cooperative Emerald** (`{colors.primary}`), carrying primary actions, highlights, active selections, and brand tags.

### Key Visual Pillars
* **Vibrant Greens**: Leveraging emerald and forest greens to create a modern agricultural/cooperative tone that represents prosperity and trust.
* **Warmth through Roundness**: Card layouts use a `{rounded.md}` (12px) radius, while main search fields and buttons run soft corner radiuses to feel approachable.
* **Responsive Layouts**: Designed around a fluid desktop first container width (1200px) that collapses gracefully to standard tablets and mobile screen widths.
* **Modern Typography**: The high-contrast headlines use **Outfit** (a premium geometric display face), while dense interface details use **Plus Jakarta Sans** (a highly readable, clean sans-serif optimized for micro-interactions on screens).

---

## 2. Color System

### Brand & Accents
* **Cooperative Emerald** (`{colors.primary}` — `#10b981`): The primary brand voltage. Used for key action buttons (e.g., "Beli Sekarang", "Tambah Ke Keranjang"), category icons, active selection rings, and checkout flows.
* **Emerald Hover** (`{colors.primary-hover}` — `#059669`): Slightly deeper shade applied when users hover over emerald elements on desktop.
* **Emerald Active** (`{colors.primary-active}` — `#047857`): A deep rich shade for button click states and focused components.
* **Mint Highlight** (`{colors.accent-mint}` — `#ecfdf5`): A gentle mint background tint. Used for alert banners, product labels, promotion tags, and active category pills.
* **Gold Spark** (`{colors.accent-gold}` — `#f59e0b`): Used exclusively for rating stars, flash sale timers, and warning/verification badges.

### Surface & Fills
* **Canvas** (`{colors.canvas}` — `#ffffff`): The base page color. The website employs a crisp white theme to ensure high readability and clean contrast.
* **Surface Soft** (`{colors.surface-soft}` — `#f4fbf7`): A pale greenish-white used for list headers, alternating table rows, and page section fills.
* **Surface Strong** (`{colors.surface-strong}` — `#e6f4ea`): A minty fill used for tag backgrounds, badges, and empty states.
* **Surface Card** (`{colors.surface-card}` — `#ffffff`): Solid white card backgrounds that float over the gray/soft green canvas.

### Hairlines & Borders
* **Hairline** (`{colors.hairline}` — `#d1e2d7`): Used for primary borders, inputs, card boundaries, and visual section dividers.
* **Hairline Soft** (`{colors.hairline-soft}` — `#eaf2ed`): An extremely light green-gray line used to partition elements inside cards and layout rows.

### Typography Ink
* **Deep Forest Ink** (`{colors.ink}` — `#1a2e22`): A dark, highly saturated forest tone. Used for display titles, page headers, body text, and links. Avoids harshness of pure `#000000`.
* **Muted Forest** (`{colors.body}` — `#384d40`): Used for descriptions, ratings details, and general body paragraph text.
* **Soft Sage** (`{colors.muted}` — `#5c7365`): Used for secondary labels, inactive nav tabs, timestamps, and input field placeholders.

---

## 3. Typography Scale

The font hierarchy is balanced for maximum readability across various viewport sizes. Headings employ **Outfit** for editorial weight, while secondary interfaces and body texts leverage **Plus Jakarta Sans**.

| Token | Size | Weight | Line Height | Letter Spacing | Desktop Use | Mobile Use |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `{typography.display-xl}` | 32px | 700 | 1.25 | -0.64px | Hero headings | Main page h1 |
| `{typography.display-lg}` | 26px | 600 | 1.3 | -0.26px | Section headers | Page subheaders |
| `{typography.display-md}` | 22px | 600 | 1.35 | 0 | Dialog titles, card titles | Product list headings |
| `{typography.display-sm}` | 18px | 600 | 1.4 | 0 | Sub-sections, item titles | Card headers |
| `{typography.title-md}` | 16px | 600 | 1.4 | 0 | Card titles, active tabs | Card headers |
| `{typography.title-sm}` | 15px | 600 | 1.4 | 0 | Category strip links | Minor UI tags |
| `{typography.body-md}` | 16px | 400 | 1.5 | 0 | Standard descriptions | Product description |
| `{typography.body-sm}` | 14px | 400 | 1.5 | 0 | Product grid pricing, metadata | Dense specs |
| `{typography.caption}` | 13px | 500 | 1.4 | 0 | Form labels, input placeholders | Secondary labels |
| `{typography.caption-sm}` | 12px | 400 | 1.4 | 0 | Small print, timestamps | Legal footer links |
| `{typography.badge}` | 11px | 700 | 1.0 | 0.5px | Tag/Status labels (e.g. "TERBARU") | Pill tags |

---

## 4. Spacing & Grid System

The spacing system relies on an 8px base grid with a 4px half-step for micro-adjustments:
* `{spacing.xxs}`: 2px
* `{spacing.xs}`: 4px
* `{spacing.sm}`: 8px
* `{spacing.md}`: 12px
* `{spacing.base}`: 16px
* `{spacing.lg}`: 24px
* `{spacing.xl}`: 32px
* `{spacing.xxl}`: 48px
* `{spacing.section}`: 80px (used for top/bottom margins of marketing blocks on desktop)

### Container Layout (Grid)
* **Max Container Width**: 1200px (Centered horizontally on wide viewports with variable margins).
* **Desktop Grid**: 12-column layouts with 24px gutters.
* **Tablet Grid**: 8-column layouts with 16px gutters.
* **Mobile Grid**: 4-column layouts with 16px gutters.

---

## 5. Elevation & Shadows

KOPDES utilizes a progressive shadow system to establish hierarchy on the flat web canvas:

* **Elevation 0 (Flat)**: Standard layout backgrounds, text panels, forms, footers.
* **Elevation 1 (Resting Card)**: `box-shadow: 0 2px 8px rgba(26, 46, 34, 0.04), 0 0 1px rgba(26, 46, 34, 0.1)` — Applied to product cards, category navigation panels, and search controls.
* **Elevation 2 (Hover/Active)**: `box-shadow: 0 8px 24px rgba(26, 46, 34, 0.08), 0 2px 4px rgba(26, 46, 34, 0.02)` — Applied to product cards on hover and buttons.
* **Elevation 3 (Dropdown/Popover)**: `box-shadow: 0 12px 32px rgba(26, 46, 34, 0.12)` — Used for dropdown menus, navigation menus, and cart drawers.
* **Elevation 4 (Modal Overlay)**: `box-shadow: 0 24px 64px rgba(0, 0, 0, 0.15)` — Used for popup dialogs and system modal overlays.

---

## 6. UI Components

### 6.1 Navigation Bar (Header)
* **Structure**: A fixed header with a height of 72px (`{colors.canvas}`) and a 1px bottom border (`{colors.hairline-soft}`).
* **Desktop Layout**: 
  * Logo on the left (Cooperative Brand).
  * Central responsive search bar with category selector dropdown.
  * Right-aligned icons: Shopping Cart (with emerald item count badge), Notification Bell, and User Account Profile menu.
* **Mobile Layout**:
  * Hamburger menu button on the left.
  * Centered Brand Logo.
  * Right-aligned icons: Search icon, Shopping Cart.
  * Search bar collapses into a full-width expandable header strip beneath the navbar when toggled.

### 6.2 The Search Hub
* **Structure**: A pill-shaped search input (`{rounded.full}`).
* **Details**: Integrated Category Dropdown on the left, separated by a vertical hairline line. Central text input field. High-voltage search orb on the right containing the search icon in Cooperative Emerald.
* **Interactions**: On focus, the border shifts to `{colors.primary}` with a subtle glow of `0 0 0 4px rgba(16, 185, 129, 0.1)`.

### 6.3 Product Card (Marketplace Grid)
* **Structure**: A content container (`{rounded.md}`) with thin borders (`{colors.hairline-soft}`) and Elevation 1.
* **Elements**:
  * **Aspect Ratio**: 4:3 image placeholder box with top-corner clipping (`{rounded.md}`).
  * **Seller Badge**: Floating badge showing the source (e.g., "UMKM DESA") in the top-left corner (`{colors.surface-strong}` and primary text).
  * **Stock Bar**: A thin progress bar indicating remaining stock for hot items.
  * **Price**: Displayed in prominent bold Emerald Green (`{typography.title-md}` in `{colors.primary-hover}`).
  * **CTA Add-To-Cart**: An icon-based emerald circle button (`{rounded.full}`) on the bottom-right corner to allow quick-adding to the shopping cart.
* **Hover Interaction**: Card lifts up (`transform: translateY(-4px)`), shadow transitions to Elevation 2, and the image scales up by 2% inside its container.

### 6.4 Shopping Cart Drawer (Keranjang)
* **Structure**: An Elevation 3 slide-out sidebar overlaying the page from the right, taking up 100% of the height and 400px of width (or 100% width on mobile viewports).
* **Header**: "Keranjang Belanja" title in `{typography.display-sm}` with a close button.
* **ItemList**: Clean row dividers (`{colors.hairline-soft}`) displaying product name, price, quantity controls (minus, input, plus), and a delete trashcan icon.
* **Sticky Footer**: Displays subtotal, tax estimation, and a full-width "Lanjut ke Pembayaran" primary button (`{colors.primary}`).

### 6.5 Form Inputs
* **Structure**: Clean input boxes (`{rounded.sm}`) with a height of 44px.
* **Interactions**: Labels reside on top of inputs in caption size. When active/focused, the border glows with a 1px emerald border. Error states display a red border (`{colors.error}`) accompanied by small red explanatory text.

### 6.6 The Dark Green Footer
* **Structure**: A premium contrasting footer (`{colors.footer}`) using a deep `#0d2116` green background, giving a clean finish to the web canvas.
* **Layout**: Stretches across the viewport with 4 columns:
  * Column 1: KOPDES Logo, description of the village cooperative mission, and social icons.
  * Column 2: Belanja (Categories links).
  * Column 3: Mitra UMKM (Registration info, Business portal links).
  * Column 4: Bantuan & Hubungi Kami (Customer support channels, addresses).
* **Copyright Bar**: Separated by a top border, displaying copyright text, terms of service, and privacy policies in muted white text.

---

## 7. Responsive Breakpoint Specification

| Breakpoint Name | Width Threshold | Layout Adjustments |
| :--- | :--- | :--- |
| **Mobile** | `< 640px` | * Container width: 100% with 16px horizontal margins.<br>* Navbar: collapses to Hamburger + Logo + Cart.<br>* Search bar: shifts to a full-screen mobile search overlay.<br>* Product Grid: displays 1-up or 2-up cards depending on device scale.<br>* Core buttons: stretch to full-width targets. |
| **Tablet** | `640px – 1024px` | * Container width: 90% centered.<br>* Navbar: displays horizontal category pills, search bar stays visible.<br>* Product Grid: displays 3-up cards.<br>* Side-by-side pages (e.g. checkout, product details) stack vertically. |
| **Desktop** | `1024px – 1280px`| * Container width: Max 1024px centered.<br>* Navbar: Full header layout containing all icons and links.<br>* Product Grid: displays 4-up cards.<br>* Split pages: Left (content/gallery, ~65%) and Right (checkout rail/detail selection, ~35%) layout. |
| **Wide Screen** | `> 1280px` | * Container width: Max 1200px centered.<br>* Sidebar drawers slide out elegantly without layout displacement.<br>* Product Grid: displays 5-up cards.<br>* Margin spacing expands to section limits (`80px`). |
