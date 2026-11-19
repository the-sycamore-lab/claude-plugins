# Packages

An Astro package is a library other Astro projects install: components, integrations, loaders, helpers. This
applies to a package in a monorepo's `packages/` and to one in a repository of its own.

## Contents

- Shape of a package
- Entries
- Barrels and imports
- Parent and child packages
- Integrations
- Handing options to runtime code
- Ambient declarations
- Modules
- Adding a package

## Shape of a package

```
<name>/
  package.json       "@scope/<name>"
  tsconfig.json      { "extends": "astro/tsconfigs/strict", "include": ["src", "*.ts"], "exclude": ["dist"] }
  eslint.config.ts   export default defineConfig([sycamore, astro]);
  src/               flat until a kind of file needs a folder
```

`package.json`:

```json
{
  "name": "@sycamore-lab/astro-color-mode",
  "version": "0.1.0",
  "description": "Light and dark mode for Astro sites, with no flash of the wrong mode on load.",
  "type": "module",
  "engines": { "node": ">=22.12.0" },
  "exports": {
    "./integration": "./src/integration.ts",
    "./server": "./src/server.ts",
    "./client": "./src/client.ts"
  },
  "files": ["src"],
  "keywords": ["astro-component"],
  "peerDependencies": { "astro": "^7.3.8" },
  "devDependencies": {
    "@sycamore-lab/eslint-config": "^0.1.1",
    "@sycamore-lab/eslint-config-astro": "^0.1.0"
  }
}
```

- Packages publish **raw source**: `exports` point at `.ts` files in `src/`, `files` is `["src"]`, and the
  consumer's Astro build compiles them. There is no build step and no `dist/`.
- `astro` is a peer dependency, at the range the rest of the project uses. What the package imports at runtime
  is a `dependency`.
- `eslint.config.ts` lists the default exports of `@sycamore-lab/eslint-config` and `@sycamore-lab/eslint-config-astro`,
  in that order. A package with Tailwind classes adds `@sycamore-lab/eslint-config-astro-tailwind` after them, names
  its stylesheet in `settings.tailwindcss.cssConfigPath`, and sets `tailwindStylesheet` in its Prettier config.
- A package with its own collections needs an `astro.config.mjs` and `src/content.config.ts` so `astro check` can
  type them; say so in a comment there, since nothing else uses them.
- In a monorepo, a package's tasks are defined the way its siblings define theirs (Nx targets in `project.json`,
  with `astro sync` before `astro check`). When the repository has a package already, copy the smallest one to
  start.

## Entries

A package has no root export. It has one entry per place Astro runs code, and each can only import what exists
there:

| Entry          | Imported by                        | Can use                                                                        |
| -------------- | ---------------------------------- | ------------------------------------------------------------------------------ |
| `/integration` | `astro.config.mjs`                 | Node, `astro/config`, Vite types. No `astro:*` modules, no `.astro` files      |
| `/content`     | `src/content.config.ts`            | `astro:content`, `astro/loaders`, virtual config. No `.astro`, no `astro:i18n` |
| `/server`      | Frontmatter, endpoints, middleware | Everything server-side: components, `astro:content`, `astro:i18n`              |
| `/client`      | `<script>` blocks                  | Browser APIs, `astro:config/client`, `astro:env/client`                        |
| `/styles`      | CSS `@import`                      | A stylesheet; `/styles/*` for further files                                    |

- Add an entry only when the package has something for that place.
- Put each export in the entry where its code runs. The type-check doesn't catch a mistake here: it surfaces
  when Astro runs, say, an `/integration` entry that pulls in a module importing `astro:content`.
- A helper that runs in several places is exported from each entry that needs it (an id helper in both
  `/content` and `/server`; a path helper in both `/server` and `/client`).

## Barrels and imports

An entry file is a barrel: re-exports only, no logic.

```ts
// src/server.ts
export * from "./define-variants";
export { default as VariantSwitch } from "./variant-switch.astro";
```

- `.ts` modules: `export * from "./module";`. `.astro` components: `export { default as Name } from "./name.astro";`.
  One per line, alphabetical by path, the package's own files before re-exports of other packages.
- A folder whose code all runs in one place has an `index.ts` barrel (`components/hero/index.ts`).
- A folder that mixes places has a barrel per entry, named after it (`content/content.ts`, `content/server.ts`),
  which the package's entry of the same name re-exports.

Imports follow the barrels. `@sycamore-lab/eslint-config-astro` enforces this with `import-x/no-internal-modules`; follow
it in a project without that rule too.

| From                          | Import                                                          |
| ----------------------------- | --------------------------------------------------------------- |
| A file in the same folder     | The file: `./icon.astro`, `./nav`, `./services-component-props` |
| Another folder in the package | Its barrel: `../ui`, `../../content/server`                     |
| Another package               | Its entry: `@sycamore-lab/astro-i18n/server`                              |
| An asset (`.css`, images)     | The file                                                        |

The same holds in a site: a folder of the site's own code (`src/config/`) gets an `index.ts`, and other folders
import through it.

## Parent and child packages

A parent package bundles general-purpose child packages into one install, as a template library does with
i18n, color mode and forms packages.

- Each of the parent's entries re-exports its children's entry of the same name
  (`export * from "@sycamore-lab/astro-i18n/server";`), so a consumer installs and imports one package.
- The parent's integration installs the children's integrations and takes each one's options under the child's
  name: `template({ i18n: { contentDir }, colorMode: { toggle } })`.
- Children know nothing about the parent or each other. Before adding to a child, check the code would make
  sense in an Astro site that has never heard of the parent; the parent's wording, content entries and CSS
  classes don't belong there.

When something general-purpose grows inside a parent, extract it into its own package rather than letting other
code depend on the parent for it.

## Integrations

```ts
/**
 * Declares the Web3Forms access key env variable. It's optional so a form can
 * fall back to something else on builds with no key, and public because
 * Web3Forms keys are meant to be exposed: the form puts it in the page anyway.
 */
import type { AstroIntegration } from "astro";
import { envField } from "astro/config";

export function web3Forms(): AstroIntegration {
  return {
    name: "@sycamore-lab/astro-web3-forms",
    hooks: {
      "astro:config:setup": ({ updateConfig }) => {
        updateConfig({ env: { schema: { WEB3_FORMS_KEY: envField.string({ … }) } } });
      },
    },
  };
}
```

- One exported function per integration, in `src/integration.ts`, returning `AstroIntegration`. Its `name` is
  the package name.
- The file opens with a doc comment saying what the integration sets up and why it has to be an integration.
- Options are an exported `interface <Name>Options`, every field optional with a `/** … */` line, defaults
  applied in the function (`{ contentDir = "src/content" }: I18nOptions = {}`).
- A site needs only `integrations: [parent()]`: an integration adds what it depends on with `updateConfig`
  (Vite plugins, `env.schema`, `fonts`, other integrations) instead of documenting setup steps.
- Fail at build, warn in dev, when the site is inconsistent:
  `if (isBuild) throw new Error(message); logger.warn(message);`.
- Dev-only behaviour hangs off `astro:server:setup` or `import.meta.env.DEV`, so none of it reaches production.

## Handing options to runtime code

Integration options exist only in `astro.config.mjs`. Components and loaders get them through a virtual module
named `virtual:<scope>-<package>/config`:

```ts
// integration.ts
const configModuleId = "virtual:sycamore-color-mode/config";
const resolvedConfigModuleId = `\0${configModuleId}`;

function configModule(colorMode: Required<ColorModeOptions>): Plugin {
  return {
    name: "sycamore-color-mode-config",
    resolveId: (id) => (id === configModuleId ? resolvedConfigModuleId : null),
    load: (id) =>
      id === resolvedConfigModuleId
        ? `export const colorMode = ${JSON.stringify(colorMode)};`
        : null,
  };
}
```

```ts
// virtual-config.d.ts
declare module "virtual:sycamore-color-mode/config" {
  export const colorMode: Required<import("./integration").ColorModeOptions>;
}
```

Register it with `updateConfig({ vite: { plugins: [configModule(colorMode)] } })`, and re-export the value from
the entry that needs it (`export { colorMode } from "virtual:sycamore-color-mode/config";`).

Build-time environment variables are declared with `envField` in the integration and re-exported under a
camelCase name: `export { WEB3_FORMS_KEY as web3FormsKey } from "astro:env/client";`.

## Ambient declarations

A package has no `astro.config`, so `astro sync` generates no types for its virtual modules or env variables.
Declare them in a `.d.ts` beside the code (`virtual-config.d.ts`, `astro-env-client.d.ts`) and load it from every
entry barrel that exports something depending on it, with exactly this:

```ts
// An import can't load a file of ambient declarations.
// eslint-disable-next-line @typescript-eslint/triple-slash-reference
/// <reference path="./virtual-config.d.ts" />
export * from "./loaders";
```

Globals a script sets on `window` are declared with `declare global { interface Window { … } }` in the module
that uses them.

## Modules

- One concern per file, named for its primary export (`get-localized-entry.ts`, `define-variants.ts`).
- A wrapper around an Astro API keeps Astro's signature and overloads, with what it adds in front:
  `getLocalizedEntry(locale, collection, id)` over `getEntry(collection, id)`. Its doc comment starts from the
  Astro function ("Astro's `getEntry`, with a locale in front…").
- A loader that wraps Astro's `file()` or `glob()` spreads the original and overrides what it changes, and
  comments any name Astro relies on.
- Throw an `Error` whose message names the function or package and what to fix:
  `defineVariants: the pick for "${slot}" is not one of its variants in the catalog`.
- Comments explain what Astro forces: an internal API, an ordering requirement, a validator that runs before
  defaults. If the code would look wrong or removable without the comment, write it.
- An internal Astro API (`astro/compiler-runtime`) is allowed only in dev-only code, with a comment saying so.

## Adding a package

1. Start from the closest existing package when there is one, renaming it in `package.json`, the task config
   and the integration's `name`; otherwise from the shape above.
2. Keep only the entries it needs in `exports` and `src/`.
3. If a parent should carry it: add the dependency, re-export each entry from the parent's entry of the same
   name, install its integration in the parent's with its options under its name, and add its options to the
   parent's options interface.
4. Install at the repository root to link the workspace, then run the package's check task.
5. Add it wherever the README lists packages and their entries.
