---
name: typescript-conventions
description: Sycamore TypeScript coding conventions. Always use when creating or updating TypeScript files (.ts, .tsx).
---

# TypeScript Conventions

## Functions

- Use **function declarations** at module/file scope
- Use **arrow expressions** inside functions (callbacks, closures, returned functions)

## Exports

- **Named exports only** — no default exports
- Barrel files (`index.ts`) use `export * from "./module"` exclusively, one re-export per line

## Types and Classes

- Use **classes** for domain model objects with `readonly` on immutable properties
- Create `Readonly<T>` type aliases named `Readonly[ClassName]` (e.g., `ReadonlyToken = Readonly<Token>`)
- Use **intersection types** to extend readonly types for specializations
  (e.g., `ReadonlySoccerPlayerToken = ReadonlyToken & { readonly team: Team }`)
- Use `type` aliases for function signatures (e.g., `type TokenFactory = (id: number, position: Position) => Token`)
- Use `Record<K, V>` for exhaustive enum-keyed maps of plain values — a label or emoji table read from
  elsewhere (`sportLabels`, `frequencyLabels`) — where the compiler enforces all keys present
- Derive a value from an enum in a `switch` returning each case inline, not a lookup map of composite values
  plus module constants (`getThemeOptions`, `getTitle`). Omit `default` so the return type still demands a
  case per member

## Enums

- PascalCase name and members
- String values matching member name: `Thin = "Thin"`, `Normal = "Normal"`

## Naming

- Variables/parameters: camelCase
- Classes: PascalCase noun phrases
- Type aliases: PascalCase (`RenderHooksResult`) — hook return types (`useXxxReturn`) are the only exception
- Abbreviations as regular words: `tokenId` not `tokenID`, `ExternalApi` not `ExternalAPI`
- Private backing fields: underscore prefix with public getter (`private _tokens` / `get tokens()`)
- Module-scoped constants: camelCase (`export const black = new Color(0, 0, 0)`)

## Errors

- Error classes extend `Error` or the project's shared base errors
- Domain-specific errors extend shared base and fix the `type` string (e.g., `TokenNotFoundError extends NotFoundError`)
- Throw eagerly at validation boundaries — no Result/Either monads
- No branded/nominal types

## Immutability

- `readonly` on all class properties that shouldn't change after construction
- `readonly` arrays for collection getters (`get tokens(): readonly ReadonlyToken[]`)
- Mutable properties only for fields that must update (e.g., `Token.position`)
- `static readonly` for class-level constants

## File Structure (Newspaper Pattern)

Arrange each file like a newspaper article — most important first, details below:

1. **Imports**
2. **Exported functions / entry points** — the public API of the module
3. **Type definitions** — parameter shapes used by the functions above
4. **Private helper functions** — implementation details called by the exports

TypeScript resolves types and function declarations regardless of order within a module, so forward references
work fine. Keep types at the bottom so readers see _what the module does_ before _what data it operates on_.

## Comments

Comment only what the code cannot say. A comment must add information a reader could not get by reading the
code beside it — otherwise delete it.

Do not write:

- Restatements of the code (`// Suspends until the user resolves` above a line that does exactly that)
- Descriptions of what a well-named function or type already conveys
- Narration of a call sequence the reader can follow
- Signposts for structure the file already shows (`// --- helpers ---`)

Do write, sparingly:

- **Why**, when the reason is not visible locally — a non-obvious constraint, an ordering requirement, a
  deliberate trade-off, a workaround for external behaviour
- What would otherwise look like a mistake, so nobody "fixes" it (e.g. why a promise is created once outside
  render, why a write merges rather than overwrites)

If a comment is needed to explain _what_ the code does, prefer renaming or restructuring until it isn't.

## Files

- All files use **kebab-case** matching the primary export (e.g., `soccer-player-token.ts` → `SoccerPlayerToken`)
- If a module has multiple related files (e.g. component + story + spec),
  group them in a folder named after the module with a barrel `index.ts`
