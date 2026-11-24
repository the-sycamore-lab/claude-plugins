---
name: typescript-testing-conventions
description: Sycamore TypeScript testing conventions. Always use when creating or updating TypeScript test or mock files (.spec.ts, .spec.tsx, .mock.ts, .mock.tsx, files under mocks/).
---

# TypeScript Testing Conventions

## Test Names

Names are terse noun/verb phrases, not sentences. Three rules, applied in order:

1. **No `should`.** `it("adds token")`, never `it("should add token")`.
2. **No leading `when`** on condition blocks. `describe("id exists")`, not `describe("when the id exists")`.
3. **No articles.** Drop every `a`, `an`, and `the`. `throws out of bounds error`, not
   `throws an out of bounds error`. `moves token to closest position within board bounds`.

What survives must still be grammatical. Dropping words often breaks subject-verb agreement —
fix it rather than leaving the wreckage: `there is only number` (not `there are only number`),
`there is at least 1 point`, `removes all tokens`.

When dropping an article would leave something ungrammatical, rephrase instead of forcing it:
`they have an intersection` becomes `they intersect`, not `they have intersection`.

### Fixed phrasings

Use these exact forms so the same concept reads the same way in every file:

| Subject                                               | Name                                         |
| ----------------------------------------------------- | -------------------------------------------- |
| Boolean **getter** (`isEmpty`, `isFull`)              | `is true` / `is false`                       |
| **Method** returning boolean (`contains`, `isWithin`) | `returns true` / `returns false`             |
| `bounds` getter                                       | `calculates bounds`                          |
| Throwing                                              | `throws <error name without articles> error` |
| Not throwing                                          | `does not throw error`                       |
| Emitting an event                                     | `emits event`                                |

The getter/method split is deliberate: a getter _is_ a value, a method _returns_ one.

Never name a test after the assertion mechanics (`is as expected`) or hedge with adverbs
(`calculates bounds correctly`). The name states the behavior; the body proves it.

## Structure

- Top-level `describe` takes a **reference, not a string**: `describe(TokenManager, ...)`,
  `describe(TokenManager.prototype.add, ...)`, `describe(Board.hydrate, ...)`. Renames then
  propagate automatically.
- Getters and plain properties have no reference to pass, so they use a string matching the
  member name: `describe("isEmpty", ...)`, `describe("bounds", ...)`.
- Nest feature/member → condition → outcome. Conditions are `describe`, outcomes are `it`.

## Shared Setup

- Declare shared variables with `let` in `describe` scope; assign them in `beforeEach`.
- **Every shared variable must be reset in a root `beforeEach`.** A block that only assigns the
  variables it changes inherits whatever the previously-executed sibling left behind. This does
  not fail — it silently tests the wrong scenario.
- No block may depend on a sibling having run first. If two blocks need the same value, hoist
  its assignment into a shared `beforeEach`; do not lean on declaration order.
- For heavyweight setup, use a `describe<Thing>(callback)` helper that builds the subject in
  `beforeEach` and hands the callback a ref (e.g. `describeBoard` in `board-spec-setup.ts`).

## Reusable Test Helpers

- Extract repeated cases as **function declarations**, never arrow consts:
  `function itAddsToken(): void { it("adds token", () => { ... }); }`
- Name the helper after the message it emits: `itAddsToken` → `it("adds token")`.
- **Declare helpers below the blocks that call them.** Function declarations hoist, so call sites
  above resolve fine, and the file reads newspaper-style — the `describe`s state what is verified,
  the helper bodies sit underneath as detail. This is why arrow consts are banned: they are in the
  temporal dead zone until evaluated, so a call above the declaration throws at registration time.

## Parametrized Tests

- Every `describe.each` / `it.each` title needs a suffix distinguishing its cases. Default to
  numbered: `- case %#`. A `%s`-style interpolation of a meaningful argument is better where one
  exists (`returns full board type for %s`).
- **One row per case.** `[[a], [b], [c]]` is three cases; `[[a, b, c]]` is one case with three
  columns, and the extra columns are silently never tested.

## Mocks

- Factory functions named `mock<Concept>()` returning randomized valid data (`mockColor()`,
  `mockTextValue()`), built on the project's random helpers (e.g. `generateRandomNumber` /
  `pickRandomElement`).
- Concrete subclasses for abstract types: `class MockToken extends Token`.
- `.mock.ts` co-located with the source and re-exported through the concept's barrel.
