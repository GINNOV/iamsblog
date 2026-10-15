# Auto-Discovery Heuristics & Curriculum Planning

This document outlines the heuristics used in Mode B (Auto-Discovery) to crawl web applications, identify core user journeys, and construct a structured curriculum plan without human intervention.

---

## 1. Discovery Crawling Strategy

When `FEATURE_QUEUE` is empty or set to `"AUTO"`, the agent crawls the target application (`BASE_URL`):

1. **Header & Navigation Mapping:**
   - Scan `<nav>`, `<header>`, mobile drawer menus, and `.main-menu`.
   - Identify high-level taxonomy: Event categories (Matrimonio, Battesimo, Comunione, Laurea), Product Types, Best Sellers, Offers.
2. **Search & Filter Exploration:**
   - Detect search bar presence (`input[type="search"]`, query parameters).
   - Detect facet filters on category pages (Price slider, in-stock checkboxes, color/occasion filters).
3. **Product Detail Page (PDP) Analysis:**
   - Identify interactive customization modules: text engraving/printing inputs, dropdowns for confetti flavors, ribbon selection, packaging options.
   - Detect quantity selector and "Aggiungi al Carrello" button.
4. **Cart & Checkout Architecture:**
   - Map `/carrello` or `/cart`.
   - Identify coupon/promo code inputs, shipping cost estimators, and order summary blocks.
5. **Customer Support & Inquiry:**
   - Map `/contatti`, WhatsApp widget, FAQ, or sample request forms.

---

## 2. Curriculum Decomposition Rules

Decompose discovered functionality into discrete, bite-sized tutorials (typically 45–90 seconds each):

| Tutorial Focus | Video Code Pattern | Typical Target Duration | Key Requirement |
| :--- | :--- | :--- | :--- |
| **Catalog & Filters** | `[PREFIX]-001_ricerca-e-filtri` | 50s–60s | Filter by event/price, open PDP |
| **Customization** | `[PREFIX]-002_personalizzazione` | 60s–80s | Select options, enter custom text, add to cart |
| **Cart & Coupons** | `[PREFIX]-003_gestione-carrello` | 40s–50s | Quantity edit, apply discount code |
| **User Account / Support** | `[PREFIX]-004_servizio-clienti` | 40s–50s | Contact channels, FAQ, order tracking |

---

## 3. Safety Guardrails & `out_of_scope` Boundaries

When generating the `curriculum_plan.json`, strictly define `out_of_scope` to prevent unintentional destructive or unwanted actions on live production sites:

- **Never complete live financial transactions:** Always stop before submitting credit card information or clicking "Paga Ora" / "Conferma Ordine".
- **Never submit spam forms:** Use client-side field validation or mock inputs without clicking the final submit on production contact forms unless specifically configured with test endpoints.
- **Do not create dummy customer accounts** unless using test email patterns or a dedicated staging environment.

---

## 4. `pre_recording_setup` Principle

To keep videos concise and focused:
- If a tutorial explains *how to use a coupon in the cart*, do NOT record the user searching the catalog for 90 seconds.
- Place: `"pre_recording_setup": "Pre-carica 2 prodotti nel carrello e apri la pagina /carrello prima del frame 0."`
- The browser performs this off-camera, trims out those frames, and starts recording at `t_zero` right on `/carrello`.
