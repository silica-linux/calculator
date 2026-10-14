# Keys

Sessions CA-01, CA-02.

## Layout (basic)

Five rows of four circular keys, 48 pt across on a 54 pt pitch, starting at (10, 133).

| Row | Keys |
| --- | --- |
| 1 | ⌫ · AC/C · % · ÷ |
| 2 | 7 · 8 · 9 · × |
| 3 | 4 · 5 · 6 · − |
| 4 | 1 · 2 · 3 · + |
| 5 | ± · 0 · decimal separator · = |

Row edges (window y): 133/181, 187/235, 241/289, 295/343, 349/397. Column edges (window
x): 10/57, 64/111, 118/165, 172/219.

## Fills by role

| Role | Keys | Fill | Glyph |
| --- | --- | --- | --- |
| Function | ⌫, AC/C, % | `#919191` | white |
| Digit | 0–9, ±, decimal separator | `#6a6a6a`; rim lighter at the top `#969797` and bottom `#888888` | white |
| Operator | ÷ × − + = | **`#ff8b00`** | white (`#fffff8`) |
| Scientific function | ( ) mc m+ m- mr, 2nd … Rad | `#585859` | white |
| Programmer function | AND, OR … mod, flip | `#575758` | white |

- Every key has a 1 pt `#0d0d0d` outline that separates it from the `#272727` window.
- The decimal and thousands separators follow the locale (the session ran with comma as
  decimal separator and period for thousands).

## Glyph sizes

Cap heights and ink boxes (w × h, pt) of the basic keys:

| Glyph | Ink box | Notes |
| --- | --- | --- |
| Digit "8" | 11 × 16 | 16 pt cap height, about 22 pt type |
| AC | 27 × 16 | |
| ⌫ | 22 × 18 | |
| ÷ | 17 × 15 | operator glyphs are drawn shapes, not text |
| + | 17 × 16 | |
| − | 16 × 2 | |
| = | 14 × 8 | |
| × | 13 × 13 | |

## Clear key

- The key reads **AC** while nothing has been typed and switches to **C** as soon as a digit
  is entered.
- Pressing C after "8 ÷" cleared the whole expression, back to 0 and AC (there is no
  "clear only the last entry" step in that case).
- Esc on the keyboard behaves like the key: the first Esc gives the C step, the second the
  AC state.

## Operators

- Operators never stay highlighted. After ÷ the display shows the expression typed so far
  ("8÷") and the ÷ key looks the same as before it was pressed.

## States

| Key | Rest | Hover | Pressed (button held) | Typed on the keyboard |
| --- | --- | --- | --- | --- |
| Digit | `#6a6a6a` | no change | `#8e8e8e` | briefly lighter (below) |
| Function | `#919191` | no change | `#b0b0b0` | *unmeasured* |
| Operator | `#ff8b00` | no change | **`#ffad25`** | briefly lighter |
| 2nd (scientific) | `#585859` | tooltip after ≈ 1 s | *unmeasured* | toggles; on: `#7e7e7f` |

- Hover was checked on basic keys, on programmer keys (AND, D, 7, AC, ÷), on the base
  segments, on the binary toggle and on a bit: nothing changes under the pointer. The only
  hover in the app is the toolbar Mode button ([window.md](window.md)).
- Pressed fills of the scientific and programmer function keys: *unmeasured*.
- The 2nd tooltip explains that the key shows the alternative functions and that holding
  Shift does the same (our string: `secondTooltip`).
- With 2nd on, labels swap: eˣ → yˣ, 10ˣ → 2ˣ, ln → logᵧ, log₁₀ → log₂, and sin/cos/tan
  and sinh/cosh/tanh → their inverses.

## Press timing (mouse)

Times from the button-down event, for a digit ("5") and an operator ("−"). Timeline:
[diagrams/press-timing.svg](diagrams/press-timing.svg).

| Event | Digit | Operator |
| --- | --- | --- |
| Down → first lighter frame | +86 ms; most of the change at once, then a slow rise for ≈ 170 ms | +35 ms, all at once |
| Up → fade back begins | +55 ms | +31 ms |
| Fade back to rest | ≈ 200 ms | ≈ 330 ms |

Rule: the press shows almost immediately; the release fades out, the operator more slowly
than the digit.

## Keyboard input

- A typed key lights the matching on-screen key. The lighter fill is visible from about
  17 ms after the key-down to about 97 ms (two frames), then drops back with no fade.
- The display updates in the same frame as the highlight.
- Return evaluates; Esc clears (see Clear key).
- Typed characters seen in the session: digits, `=` (with Shift), Return, Esc.
