# `.astro` files

## Contents

- Anatomy of a component
- TypeScript conventions in Astro files
- Keep templates simple
- Props
- Reading data
- Rendering nothing
- Markup and styling
- Client-side behaviour
- Accessibility

## Anatomy of a component

```astro
---
/** Financing callout. Toggle with financing.enabled in company.yaml, or leave financing out. */
import { getLocalizedEntry } from "@sycamore-lab/astro-i18n/server";
import { getRelativeLocaleUrl } from "astro:i18n";

import { collectionIds, getText, singletonEntryIds } from "../../content/server";
import { Icon } from "../ui";

const locale = Astro.currentLocale!;
const { data: company } = await getLocalizedEntry(locale, collectionIds.company, singletonEntryIds.company);
const text = await getText(locale);
const requestHref = getRelativeLocaleUrl(locale, "/contact") + "#request";
const financing = company.financing?.enabled ? company.financing : undefined;
---

{financing && (
  <section class="border-y border-base-300 bg-base-100">
    <div class="wrap flex flex-col gap-4 py-8 sm:flex-row sm:items-center sm:gap-8">
      <Icon name="dollar" size={44} class="shrink-0 text-primary" />
      <div class="flex-1">
        <h2 class="font-display text-2xl">{financing.headline}</h2>
        <p class="text-base-content/75">{financing.body}</p>
      </div>
      <a href={requestHref} class="btn btn-outline">
        {text.financing.ask}
      </a>
    </div>
  </section>
)}
```

Frontmatter order:

1. **Imports.** Packages and `astro:*` modules first, relative imports after a blank line; `import type` as its
   own statement. The project's lint fix sorts them. A stylesheet import (`import "../styles/global.css";`) goes first.
2. **`Props`.**
3. **Values**, in dependency order: `locale`, wording and entries, then the values the template reads.
   `Astro.props` is destructured right after `Props`, or after `text` when a default is wording.
4. **Helper functions**, as declarations at the bottom.

## TypeScript conventions in Astro files

The TypeScript conventions apply to frontmatter and `<script>` blocks. Where Astro overrides one:

- **Exports**: the component itself is Astro's implicit default export; named-exports-only governs what the
  frontmatter exports. A barrel gives the component its name:
  `export { default as CallButton } from "./call-button.astro";` (one line per component, alphabetical), next
  to `export * from "./module"` for `.ts` modules.
- **File structure**: frontmatter `const`s run top to bottom, so order them by dependency: imports, `Props`, then
  the values the template reads. Function declarations hoist, so private helpers still go at the bottom.
- **Files**: the kebab-case file name is the component name (`services-cards-section.astro` →
  `ServicesCardsSection`).
- **`Props`**: `interface Props { … }` when the shape is written in the file; `type Props = …` when it is another
  type (`type Props = ServicesComponentProps;`, `type Props = PageLayoutProps<{ title: string }>;`).

## Keep templates simple

Compute values in the frontmatter script; the template should only reference them.

Move into frontmatter whenever possible:

- Ternaries, `??` / `||` fallbacks, and string building (template literals, `.join`, `.toLocaleString()`, etc.)
- Derived booleans used in `&&` conditions, e.g. `const showRating = rating != null;`
- Lookups, `.filter`, `.slice`, `.sort`, and other data shaping before a `.map`
- Per-item derived values: map the source data to view-ready items in frontmatter, so the template's `.map` only
  renders fields

```astro
---
const availability = site.emergency?.enabled ? "Open 24/7" : "Same-day service";
---

<li>{availability}</li>
```

Not `<li>{site.emergency?.enabled ? "Open 24/7" : "Same-day service"}</li>`.

Per-item values are added where the list is read:

```astro
---
const team = (await getLocalizedCollection(locale, collectionIds.team)).map((member) => ({
  ...member.data,
  roleSince: pupa(text.team.since, {
    role: member.data.role,
    year: member.data.since,
  }),
}));
---

{team.map((member) => (
  <p class="text-primary">{member.roleSince}</p>
))}
```

What stays in the template:

- Plain references: `{title}`, `{item.name}`, `href={site.contact.phoneHref}`
- `{cond && <el />}` and `{items.map((item) => <el />)}` that render markup
- Choosing between two markup branches with a ternary, when both branches are elements
- Values that depend on a slot or a loop variable and can't reasonably be precomputed

Name the frontmatter variables for what they mean (`availability`, `reviewSummary`), not how they are computed.
Common shapes: `hasX` / `showX` for conditions, `xHref` for links, `xLabel` for `aria-label`s and button text.

## Props

- **Defaults in the destructuring**: `const { compact = false, id = "request" } = Astro.props;`.
- **A default that is wording** is destructured after the wording is loaded:

  ```ts
  const text = await getText(locale);
  const { title = text.faq.title, homeOnly = false } = Astro.props;
  ```

- **`title` and `intro`** are the props that override a section's default wording. Give a section them rather
  than a prop per string.
- **`class`** lets the caller add classes to the root element. Rename it, and merge with `class:list`:

  ```astro
  ---
  interface Props {
    class?: string;
  }
  const { class: className = "" } = Astro.props;
  ---

  <nav class:list={["hidden xl:block", className]}>
  ```

  For a button, the default is its style, so a caller's classes replace it:
  `const { class: className = "btn-primary" } = Astro.props;` with `class:list={["btn", className]}`.

- **Polymorphic tag**: `as?: "h1" | "h2"`, destructured as `as: Tag = "h2"`.
- **Boolean props** default to `false` and read as flags at the call site: `<FaqSection homeOnly />`,
  `<ServicesSection featuredOnly />`.
- **Photos** take `image`, plus `imageAlt` when the alt text isn't the component's own wording. Render them
  through the project's image component (`Photo`) rather than a bare `<img>`.
- **Variants of one slot take the same props.** Their shared type lives beside them in
  `<kind>-component-props.ts` (`ServicesComponentProps = ServicesQuery & { title?: string; intro?: string }`) and
  each variant declares `type Props = ServicesComponentProps;`. A prop one variant needs is added to all of them.
- **Document a prop** with a `/** … */` line only when its name doesn't explain it.
- **A component's props type** for callers is exported from the folder barrel with `ComponentProps`:
  `export type BaseLayoutProps = ComponentProps<typeof BaseLayout>;`.

## Reading data

A shared component reads what it shows; callers don't pass site-wide entries or the wording down.

```ts
const locale = Astro.currentLocale!;
const { data: company } = await getLocalizedEntry(locale, collectionIds.company, singletonEntryIds.company);
const text = await getText(locale);
```

- `Astro.currentLocale!` when a `string` is required (`getLocalizedEntry`, `getRelativeLocaleUrl`), in a project
  whose config always sets `i18n`, so it is defined. Getters with a default locale (`getText`) take
  `Astro.currentLocale` as it is.
- Destructure only what is used: `const { data: { contact } } = await getLocalizedEntry(…)`.
- Use one of the project's queries (`listServices`, `listReviews`) when one covers the need; add one when two
  components would otherwise repeat the same sorting or derivation.
- Format numbers for the reader: `rating.toLocaleString(locale)`.
- See [content-and-i18n.md](content-and-i18n.md) for wording, links and ids.

## Rendering nothing

Optional data that is missing removes the element, never leaves an empty shell.

- A feature with an `enabled` flag is narrowed once, then used as the condition and the data:
  `const membership = company.membership?.enabled ? company.membership : undefined;` →
  `{membership && (<section>…</section>)}`.
- A list section checks its list: `const hasGuarantees = guarantees.length > 0;`.
- A wrapping label goes with its value: build the whole string in frontmatter
  (`const expiry = special.expires && pupa(text.specials.expires, { date: special.expires });`) and render
  `{expiry && <p>{expiry}</p>}`.
- Say so in the doc comment ("Renders nothing when there are no specials"), because the caller places the
  component unconditionally.

## Markup and styling

- **A section** is `<section class="section"><div class="wrap">…</div></section>`. `section` is the vertical
  rhythm, `wrap` the page width and gutters; both are utilities defined once in the project's stylesheet
  (`@utility section { … }`), so spacing changes in one place. Bands with their own padding (`PageHeader`, CTAs)
  use `wrap` with `py-*`.
- **Headings**: one `<h1>` per page, from the hero or `PageHeader`. A section's title is an `<h2>` (use
  `SectionHeading` for title plus intro), items inside it are `<h3>`. Headlines use the project's display
  utility (`font-display`), so they follow the theme.
- **Classes** (Tailwind with daisyUI): utilities, with daisyUI classes for controls (`btn btn-primary`, `input`, `select`,
  `link`, `floating-label`, `breadcrumbs`) and its radii (`rounded-box` for panels, `rounded-field` for small
  marks). Mobile first, widening with `sm:` / `lg:`.
- **Colors** are the theme's semantic ones so every theme and dark mode work. With daisyUI: `bg-base-100/200/300`,
  `text-base-content`, `primary`, `secondary`, `accent`, `neutral` with their `-content` pairs. Mute text with
  opacity (`text-base-content/75`), not another color. Custom CSS uses the variables (`var(--color-primary)`).
- **Building blocks** live in the project's UI folder (`components/ui`: `Icon`, `Photo`, `CallButton`,
  `SectionHeading`…); read their props and use them instead of repeating their markup.
- **`<style>` blocks** are for what utilities can't express (keyframes, `clamp()` sizes, pseudo-elements). They
  are scoped; reach the theme with `:global([data-theme="dark"]) .hero-livery`. A class used only as a hook for
  one must be allowed in the ESLint config when it checks class names (see Finishing in SKILL.md). Wrap motion in
  `@media (prefers-reduced-motion: no-preference)`.
- **Raw markup** goes through `set:html`, as in structured data:
  `<script type="application/ld+json" set:html={JSON.stringify(schema)} />`.
- **Dev-only components** style themselves inline: a dev tool must add nothing to the production CSS.
- **A shared library's stylesheet** lists its own components with `@source`, since Tailwind skips
  `node_modules`.
- **Pages of a template site hold no classes.** See [template-sites.md](template-sites.md).

## Client-side behaviour

Prefer no JavaScript on a static page: `<details>` for menus and accordions, plain form posts.

When a script is needed:

- Use a processed `<script>` (no attributes). It is TypeScript, bundled once however many times the component is
  on the page, so select every instance: `document.querySelectorAll<HTMLElement>(".theme-toggle").forEach(…)`.
- Import browser helpers from a package's `/client` entry:
  `import { toggleColorMode } from "@sycamore-lab/astro-color-mode/client";`.
- Hand server values to it through `data-*` attributes (`data-label-dark={text.switchToDark}`), read with
  `element.dataset`.
- `<script is:inline>` only when the code must run before first paint (`ColorModeScript`) or the component is
  dev-only. It is plain JavaScript, repeated per instance; pass values with `define:vars`.
- Wrap `localStorage` access in `try` / `catch`; it throws when storage is blocked.

## Accessibility

- Every `<nav>` has an `aria-label` from the wording (`text.nav.main`, `text.nav.footer`); the current link has
  `aria-current="page"`.
- An icon-only control has an `aria-label` built from wording: `pupa(text.callPhone, { phone })`. Decorative
  elements have `aria-hidden="true"`; `Icon` does this itself unless given a `label`.
- A form field is a `<label>` wrapping its control, with `autocomplete` and the right `type` / `inputmode`.
- External links to a review or booking site carry `rel="noopener"`.
- Links to another language carry `hreflang` and `lang`.
