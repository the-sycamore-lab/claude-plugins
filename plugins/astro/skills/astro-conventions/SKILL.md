---
name: astro-conventions
description: Sycamore Astro coding conventions. Always use when creating, updating or reviewing code in an Astro project - .astro components, layouts and pages (frontmatter, template, <script>, <style>), Markdown/MDX pages, Astro packages (entries, barrels, integrations), content collections and schemas, wording and i18n - or when adding a package, section, variant, prop or wording key.
---

# Astro conventions

How Sycamore writes Astro code: sites, the packages of components and integrations they are built from, and
template libraries that many sites share.

## Scope

Apply each rule where the project has what it is about. A rule about locales says how to write localized code
in a project that has locales; it is not a reason to add locales, Tailwind, a wording pack or a package split
to a project without them.

Examples come from a library of sections for home-service business sites (`HeroFormSection`, `company.yaml`,
`getText`). Their names are illustrations; use the project's own.

Several rules name helpers from the `@sycamore-lab/*` Astro packages (`i18n`, `color-mode`, `component-variation`,
`page-layout`, `singleton-loader`, and template libraries built on them). When the project doesn't install the
package, follow the same rule with the project's own helper or Astro's API.

## Before writing

1. An `.astro` file's frontmatter and `<script>` blocks are TypeScript. Invoke every available skill that defines
   TypeScript conventions (e.g. `typescript:typescript-conventions`), even though their descriptions name only
   `.ts` / `.tsx`, and apply their rules to that code. Astro's overrides are in [components.md](components.md).
2. Read the reference for what you are touching:

| Touching                                                                    | Read                                       |
| --------------------------------------------------------------------------- | ------------------------------------------ |
| Any `.astro` file                                                           | [components.md](components.md)             |
| A package's entries, barrels, `package.json`, an integration, a new package | [packages.md](packages.md)                 |
| Collections, schemas, queries, wording, locales, links                      | [content-and-i18n.md](content-and-i18n.md) |
| A site built on a template library: pages, layouts, variant picks, theme    | [template-sites.md](template-sites.md)     |

3. Read the project's README and a neighbouring file of the kind you are writing, for its names, folders and
   tasks.
4. For Astro's own APIs, check current documentation (an Astro docs MCP server if the session has one) against
   the Astro version in `package.json`, instead of relying on memory.

## The rules that are broken most easily

- **Templates only reference values.** Ternaries, fallbacks, string building and data shaping go in the
  frontmatter, under a name that says what the value means.
- **No visible text in a shared component.** A component that several sites or locales reuse takes its wording
  from the project's wording source (`getText(locale)`), with placeholders filled in the
  frontmatter. A new string is a new key in every language.
- **Import through barrels.** Reach into another folder or package only through its `index`, `integration`,
  `content`, `server` or `client` file.
- **Each package entry runs in one place.** `/integration`, `/content`, `/server` and `/client` can each import
  only what exists where they run. The type-check doesn't catch an export in the wrong entry.
- **Theme colors only.** Semantic colors from the theme (`bg-base-200`, `text-primary`), never a hex value or a
  palette color in a component.
- **Missing data leaves the element out.** An optional field that is unset removes whatever shows it, label and
  wrapper included; a section with nothing to show renders nothing.
- **Links and ids are localized.** In a project with locales, `getRelativeLocaleUrl(locale, "/contact")` for
  hrefs, and the entry's id without its locale in a URL.

## Naming

| Thing                   | Convention                                                                             |
| ----------------------- | -------------------------------------------------------------------------------------- |
| Files and folders       | kebab-case; the file name is the component or primary export (`call-button.astro`)     |
| Components              | PascalCase, ending in their type: `…Section`, `…Header`, `…Footer`, `…Button`, `…Form` |
| Slot variants           | `<Slot kind><Style>Section`: `HeroFormSection`, `ReviewsGridSection`                   |
| Page layouts            | `<page>-layout.astro`, wrapping the site's `layout.astro`                              |
| Schemas and their types | `serviceSchema` → `ServiceData`; a singleton's `companySchema` → `Company`             |
| Queries                 | `getX` for one value, `listX` for a sorted, filterable list                            |
| Integrations            | A noun, `variantSwitcher()`; `xConfig()` when it only hands options to runtime code    |
| Integration options     | `ColorModeOptions`, an exported `interface` with a doc comment per field               |
| Virtual modules         | `virtual:<scope>-<package>/config`                                                     |
| Packages                | The folder is the package name without its scope: `packages/i18n` → `@scope/i18n`      |

## Finishing

Run the project's own fix and check tasks for everything you changed: `package.json` scripts in a single
project, the task runner's targets in a monorepo (`npx nx fix <project>`, `npx nx check <project>`). Between
them they should cover `astro check`, ESLint, Prettier and, where set up, spell-checking. Fix what they report
instead of formatting by hand; import order, barrel rules and class order are theirs to decide.

- A spell-checker flags a real word: add it to the project's dictionary (`cspell.json`), keeping the list
  sorted.
- ESLint flags a class as unknown: it is a hook for a `<style>` block; add it to the allowed class names in
  `eslint.config.*` (the `whitelist` of `tailwindcss/no-custom-classname`).
- A README that lists packages, entries, exports, sections or variants is part of the change: update the table
  or list yours touches.
- A component nothing has rendered isn't finished: look at it in the dev server, in each color mode and with its
  optional data removed.
