# Content, wording and locales

Where these files live depends on the project: in a site, under `src/`; in a template library, in the library
(`src/content/collections.ts`, `schemas.ts`, `queries.ts`, `packs/`), with each site holding only the content
files. Find the project's existing files before adding new ones.

The localized helpers named here (`getLocalizedEntry`, `getLocalizedCollection`, `destructureLocalizedId`,
`localizedGlob`, `localizedFile`, `defaultLocale`) come from `@sycamore-lab/astro-i18n`, and `singleton()` from
`@sycamore-lab/astro-singleton-loader`. In a single-language project that doesn't use them, the sections on collections,
schemas, queries and wording still apply, with Astro's `getEntry`, `getCollection`, `glob()` and `file()`.

## Contents

- Collections
- Schemas
- Queries
- Wording
- Adding a wording key
- Locales
- Links and ids

## Collections

All collections are defined in one module. In a template library that module is exported, and a site's
`src/content.config.ts` only re-exports it, or spreads it to swap a schema or loader.

| Kind of data            | File in `src/content/<locale>/` | Loader                                                    |
| ----------------------- | ------------------------------- | --------------------------------------------------------- |
| One thing (the company) | `company.yaml`                  | `localizedGlob({ pattern: "company.yaml" })`              |
| A list of small entries | `faqs.yaml`, each with an `id`  | `localizedFile("faqs.yaml")`                              |
| Entries with a body     | `services/*.md`                 | `localizedGlob({ base: "services", pattern: "**/*.md" })` |

- Collection keys are camelCase plurals (`services`, `serviceCategories`). A one-file collection's entry id is
  the file name, read as `getLocalizedEntry(locale, collectionIds.company, singletonEntryIds.company)`. Without locales, load a one-thing
  file with `singleton("src/content/company.yaml", "company")`.
- Collection ids are constants. The module that defines the collections has a `collectionIds` object
  (`collection-ids.ts`, exported from the content and server barrels) with one member per collection; the
  collections are keyed by it (`[collectionIds.services]: defineCollection(…)`) and every read passes a member
  (`collectionIds.services`), never the string `"services"`. A new collection adds its id there first. A type takes it the same way:
  `CollectionEntry<typeof collectionIds.services>`. A one-file collection's entry id comes from
  `singletonEntryIds` beside it (`singletonEntryIds.company`).
- Content is YAML and Markdown. A YAML file starts with its editor schema and a pointer to the field docs:

  ```yaml
  # yaml-language-server: $schema=../../../.astro/collections/faqs.schema.json
  #
  # Frequently asked questions. Every entry needs a unique `id`. Field docs: <where the schema is>.
  ```

## Schemas

Every data shape is in one module, with zod from `astro/zod`.

```ts
export const serviceSchema = z.object({
  title: z.string(),
  order: z.number().default(100),
  featured: z.boolean().default(false),
  priceFrom: z.string().optional(),
});

/** Display order of service categories. Lives in src/content/services/categories.yaml. */
export const serviceCategoriesSchema = z.object({
  /** Categories not listed sort last. */
  order: z.array(z.string()).default([]),
});

export type ServiceData = z.output<typeof serviceSchema>;
```

- Export `<name>Schema`, and its type at the bottom of the file with `z.output`: `<Name>Data` for an entry of a
  list, the bare noun for a singleton (`Company`).
- Required only when a site can't work without it (`name`, `contact.phone`). Everything else is `.optional()`,
  and every component that shows it must leave it out when unset.
- `.default()` for flags, ordering and empty lists, so components don't repeat the fallback.
- An optional feature with several fields is an optional object with `enabled: z.boolean()` (`financing`,
  `membership`), so a site can switch it off without deleting it.
- A field whose name doesn't explain it gets a `/** … */` line; these are the field docs content editors read.
- Wording defaults never go in a schema: they differ per language and live with the wording.
- In a library, keep shapes extendable: a layer on top `.extend()`s them and changes `.default()`s.

## Queries

A queries module holds what the project adds on top of `astro:content`: defaults, sorting, derived facts.

```ts
export async function listServices(
  { featuredOnly = false, limit }: ServicesQuery = {},
  locale: string = defaultLocale,
): Promise<CollectionEntry<typeof collectionIds.services>[]> {
```

- `getX(locale)` returns one value, `listX(query, locale)` a sorted list. `locale` is the last parameter and
  defaults to `defaultLocale`.
- A list's options are an exported `<Name>Query` type, declared right after the function. A section that shows
  the list spreads the rest of its props into it: `const { title, ...query } = Astro.props;`.
- Don't wrap a plain read. Components call `getLocalizedEntry` and `getLocalizedCollection` themselves; a query
  earns its place by adding something.

## Wording

A component that more than one site or locale uses contains no visible text. Its wording is data: a typed
object per language (a "pack") in the library, which a site's own content file can override key by key.

A getter (`getText(locale)`) returns every key filled: the site's overrides (`text.yaml`) over the pack for
that language (`packs/en.ts`, `packs/es.ts`), falling back to the reference language when there is no pack. One
object holds all of it: interface wording (labels, buttons, headings, `aria-label`s) and the copy each site
words differently (hero titles, taglines, steps).

- Keys are camelCase, grouped by where they are used: `nav.links.services`, `form.phone`, `hero.livery.title`,
  `cta.split.bookBody`, `contact.hours`. A group nests again for a variant or a cluster of related keys
  (`hero.picker.*`, `form.window.*`); a key with no area of its own stays at the top level (`callPhone`, `menu`).
- A section's default heading is `<section>.title` (`faq.title`, `guarantees.title`);
  its intro is `<section>.intro`.
- Overrides are layered over the pack group by group, so a site overriding one key keeps the rest of its group.
- A value with a variable part has a `{placeholder}`, filled in the frontmatter (with `pupa`):
  `pupa(text.callPhone, { phone: contact.phone })`. Don't concatenate around a value; word order differs between
  languages.
- When a sentence can't work without an optional value, add a second key ending in what is missing
  (`areas.title` / `areas.titleNoCity`) and choose in the frontmatter.
- To put markup in the middle of a sentence, split on the placeholder:
  `const [callbackBefore, callbackAfter] = text.form.callback.split("{phone}");`.
- Wording sent to the site's owner rather than the visitor (a notification email's subject) uses the default
  locale: `getText(defaultLocale)`.
- A library's default wording is neutral, so it suits any site that hasn't overridden it.
- Text that belongs to one page of one site isn't a wording key: it is that page's content or props.

## Adding a wording key

1. Add the key and its wording to the reference pack, in its area's group, and the translation at
   the same spot in every other pack. All packs have the same keys.
2. Add the key to the override schema if it isn't derived from the reference pack.
3. Read it in the component's frontmatter.

## Locales

- Every locale has a complete content folder, `src/content/<locale>/`, the default locale included. Nothing falls
  back to another locale except wording: an entry missing from `es/` doesn't exist in Spanish.
- Entry ids are `<locale>/<id>`. Read with `getLocalizedEntry(locale, collection, id)` and
  `getLocalizedCollection(locale, collection)`, never `getEntry` / `getCollection` with a hand-built id.
- A component's locale is `Astro.currentLocale`. Don't parse it from the URL or pass it as a prop.
- Code written for locales also runs on a single-language site: give the site one locale in its `i18n` config
  (a template's integration can do this) instead of branching in components.
- A language pack is matched exactly (`es-MX`) and then by language (`es`).
- Each page is a file per locale (`src/pages/about.md`, `src/pages/es/about.md`). Changing a page or a content
  file in one locale means changing it in every locale; `@sycamore-lab/astro-i18n`'s integration fails the build on a
  page missing from a language, but nothing checks content files.
- 404 and 500 pages belong to no locale: no hreflang links, no language switcher.

## Links and ids

```ts
const servicesHref = getRelativeLocaleUrl(locale, "/services");
const requestHref = getRelativeLocaleUrl(locale, "/contact") + "#request";
const href = getRelativeLocaleUrl(
  locale,
  `/services/${destructureLocalizedId(service.id).id}`,
);
```

- Every internal link goes through `getRelativeLocaleUrl` from `astro:i18n`, with the path as it is in the
  default locale.
- An entry's id in a URL, a form value or `getStaticPaths` params is `destructureLocalizedId(entry.id).id`.
- Absolute URLs (canonical, redirect, hreflang) are built from `Astro.site`:
  `new URL(getRelativeLocaleUrl(locale, "/thanks"), Astro.site).href`. Handle `Astro.site` being unset.
- The site's standard pages and their nav labels are listed once, in one module, not per header and footer.
