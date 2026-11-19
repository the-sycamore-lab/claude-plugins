# Sites built on a template library

A template library (such as `@sycamore-lab/astro-handyman-corp`) ships the sections, layouts' building blocks, content schemas
and default wording; each site installs it and owns only wording, picks and page composition. This file is for
working in such a site, and for adding to the library it is built on. The library is written `<template>`
below.

A site that isn't built on a template library still follows "Pages" and "Layouts" wherever it separates
wording from markup.

## Contents

- Where a change belongs
- Pages
- Layouts
- Variants
- Styles and config
- Adding a section or a variant to the library

## Where a change belongs

| The site needs                          | Change                                                                   |
| --------------------------------------- | ------------------------------------------------------------------------ |
| Different facts, lists, entries         | `src/content/<locale>/*.yaml` and Markdown entries, in every locale      |
| Different default wording               | The site's wording overrides (`text.yaml`), in every locale            |
| A different title or intro on one page  | That page's file in `src/pages/`                                         |
| Sections added, removed or reordered    | The page's layout in `src/layouts/`                                      |
| Another style of hero, header, reviews… | The pick in `src/config/variants.ts`                                     |
| Other colors or headline voice          | The theme in `src/styles/global.css`                                     |
| Something the library can't do          | A new prop, section or variant in the library, so every site gets it     |
| A true one-off                          | A component in the site's `src/components/`, built from the library's UI |

Don't copy a library section into a site to edit it: the copy stops receiving upgrades.

## Pages

A page file holds wording and nothing else: no CSS classes, no sections, no layout markup.

A page whose wording is fixed is Markdown; its frontmatter names the layout and fills its props:

```md
---
layout: ../layouts/services-layout.astro
title: Plumbing services
intro: Repairs, replacements and new installs for homes across the region.
---
```

A page whose wording uses values from content is MDX, which renders the same layout itself:

```mdx
import { collectionIds, getLocalizedEntry, singletonEntryIds } from "<template>/server";

import PrivacyLayout from "../layouts/privacy-layout.astro";

export const entry = await getLocalizedEntry("en", collectionIds.company, singletonEntryIds.company);
export const company = entry.data;

<PrivacyLayout title="Privacy policy">

{company.legalName} collects the details you send through our forms…

</PrivacyLayout>
```

- One file per page and locale: `src/pages/about.mdx` and `src/pages/es/about.mdx`, with the locale written as a
  literal in each (`"en"`, `"es"`). Add, rename or delete a page in every locale at once.
- **Keep every `import` and `export` before the layout on one line.** When one wraps, Astro puts a second
  `<meta charset>` in front of `<html>`. This is why MDX pages import one name per statement, repeating the
  module.
- `[slug]` pages are MDX, since a Markdown page can't export `getStaticPaths`:
  `export const getStaticPaths = () => getServicePageStaticPaths("en");`. Props from the paths are read as
  `props.area.name`.
- Nothing type-checks frontmatter or MDX props against the layout. After changing a layout's props, update every
  page that uses it, in every locale.
- Long text (about, privacy, 404) is the page body, rendered into the layout's `<slot />` inside a section that
  styles it (a prose section).

## Layouts

`src/layouts/layout.astro` wraps the library's base layout with the site's header and footer. Each page has a
`<page>-layout.astro` that wraps it and stacks sections:

```astro
---
import type { PageLayoutProps } from "<template>/server";
import { PageHeader, unpackPageLayoutProps } from "<template>/server";

import { CtaSection, TrustSection } from "../config";
import Layout from "./layout.astro";

type Props = PageLayoutProps<{
  title: string;
  heading: string;
  intro: string;
}>;
const props = unpackPageLayoutProps(Astro.props);
---

<Layout title={props.title}>
  <PageHeader title={props.heading} intro={props.intro} />
  <TrustSection />
  <slot />
  <CtaSection />
</Layout>
```

- `PageLayoutProps<{…}>` with `unpackPageLayoutProps(Astro.props)` (from `@sycamore-lab/astro-page-layout`) lets one
  layout serve both a Markdown page (props in `frontmatter`) and an MDX page (props passed directly). Name the
  result `props`.
- Common wording props: `title` (the `<title>`), `heading` (the `<h1>`), `intro`, `description` (meta).
- Slot variants come from `../config`; single-style sections and UI blocks from the library.
- A layout is shared by every locale: it holds no wording, and gets labels from the wording getter.
- A `[slug]` layout reads its entry itself: `getLocalizedEntry(locale, collectionIds.services, Astro.params.slug!)`.
- A layout's body is a flat stack of sections. Markup beyond that belongs in a section.
- A layout serving one kind of page says which in a doc comment
  (`/** For each locale's services/[slug].mdx: one page per service in services/. */`).

## Variants

A slot is a place on a page that comes in several styles; a variant is one style. With
`@sycamore-lab/astro-component-variation`, `src/config/variants.ts` is the one place a site picks them, and
`src/config/index.ts` is its barrel.

```ts
export const { Header, Footer, HeroSection /* … */ } = defineVariants(catalog, {
  ...defaults,
  HeroSection: catalog.HeroSection.HeroFormSection, // HeroLiverySection | HeroFormSection | HeroPickerSection
});
```

- Pick through the catalog (`catalog.HeroSection.HeroFormSection`), with the slot's other variants in a trailing
  comment.
- Layouts use the slot name (`<HeroSection />`), never a variant by name, so a pick changes every page.
- A site-only variant is added by spreading the catalog:
  `{ ...catalog, HeroSection: { ...catalog.HeroSection, MyHero } }`. It must take the slot's props.

## Styles and config

- `src/styles/global.css` imports the library's styles and one theme, and is imported once, at the top of
  `layout.astro`. A site-only theme replaces the theme import with a copy of one of the library's themes,
  keeping its `light` and `dark` names.
- `astro.config.mjs` holds `site`, `i18n` and the library's one integration, nothing else.
- `src/content.config.ts` re-exports the library's `collections`, or spreads them to swap a schema or loader.
- Secrets and keys come from `.env`, documented in `.env.example`.

## Adding a section or a variant to the library

Follow the library's own folders; these are the usual ones.

A single-style section:

1. `components/sections/<name>-section.astro`, following [components.md](components.md).
2. Export it from the folder's `index.ts`.
3. Add its wording to every pack ([content-and-i18n.md](content-and-i18n.md)).
4. Use it in a layout of the library's demo site, where no section already on that page shows the same data.
5. Look at it in the demo's dev server, in each color mode and with the data it needs removed.

A variant of an existing slot:

1. `components/<kind>/<kind>-<style>-section.astro`, with a doc comment starting `<Kind> variant:` and
   `type Props = <Kind>ComponentProps;` when the slot has a shared props type.
2. Export it from the folder's `index.ts`.
3. Add it to its slot in the library's catalog. `defaults` changes only if it should be the new default.
4. Update the trailing comment in the demo's `variants.ts`.
5. Check it in dev with the variant switcher, in each color mode and every theme.

A new slot also needs a key in `catalog` and `defaults`, a destructured export in the demo's `variants.ts`, and a
props type shared by its variants.

Either way, update the README where it lists sections, slots and variants.
