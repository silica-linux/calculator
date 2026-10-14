# Calculator · specification

What the app does and how it behaves. Measurements: `silica-reference` › `calculator.md`
(CA-01); numbers here are the ones the code uses.

## Window

- Always dark: the system appearance does not change it. Background `#272727`.
- Fixed size per mode: basic 230 × 408, scientific 674 × 408, programmer 488 × 582. A mode
  change resizes the window keeping the top-left corner, in one frame, with no animation.
- Toolbar 52 pt unified with the window (Ossido draws the window buttons): a history button
  (36 pt circle at x 96, not in the programmer mode) and the mode button (36 pt circle at
  width − 44), fill `#444546`, 1 pt `#0f0f0f` outline, white glyph. Only the Mode button has
  a hover state (`#4e4e4f`); no key or segment changes under the pointer.
- Inactive window, every mode (CA-02): operators and ⌫ C/AC % `#545555`, scientific and
  programmer functions `#474749`, digits `#4d4d4e`, the chosen base segment `#505051`, the
  toolbar buttons `#3b3b3c`.

## Keys

- Basic: 4 × 5 circles of 48 at a 54 pt pitch, from (10, 133). Scientific: 10 × 5 capsules
  60 × 48 at 66 × 54. Programmer: 7 × 6 capsules 62 × 48, columns at x 10, 78, 145, 213, 281,
  349, 416, from y 254.
- Fills: digits `#6a6a6a`, functions `#919191`, operators sRGB `#ff8b00`, scientific
  `#585859`, programmer `#575758`; pressed `#8e8e8e`, `#b0b0b0`, `#ffad25`. 1 pt `#0d0d0d`
  outline, a light rim. No change on hover. After the release the key fades back in ~200 ms
  (operators ~330 ms). A typed key lights the matching key for ~80 ms.
- AC with nothing typed, C as soon as something is; both clear the whole expression.
  Operators have no latched state.

## Display

- Main line right-aligned 12 pt from the window edge, baseline y 119, 24 pt cap height
  `#dedede`. After "=" the expression moves to a line above (baseline 81, 17 pt cap height,
  `#9e9e9e`) and the result takes the main line.
- A long entry shrinks to 17 pt cap height, then scrolls out to the left behind a 13 pt fade.
- Numbers: locale decimal and thousands separators, at most 8 decimals (2 ÷ 3 = 0.66666667),
  scientific notation beyond 16 digits or below the last decimal.
- Arithmetic is exact on decimals (0.1 + 0.2 = 0.3): fractions of big integers; functions with
  irrational results go through a double and keep 15 significant digits.

## Modes

- Basic: ⌫ AC % ÷ / 7 8 9 × / 4 5 6 − / 1 2 3 + / ± 0 . =
- Scientific adds ( ) mc m+ m- mr, 2nd, x² x³ xʸ eˣ 10ˣ, 1/x √x ∛x ʸ√x ln log₁₀, x! sin cos tan
  e EE, Rand sinh cosh tanh π Rad. 2nd (or Shift held) switches eˣ→yˣ, 10ˣ→2ˣ, ln→logᵧ,
  log₁₀→log₂ and the trigonometric and hyperbolic functions to their inverses. Rad/Deg
  switches the angle unit; "Rad" shows on the display while angles are in radians.
- Programmer: 64-bit integers in base 8, 10 or 16 (segmented control), AND OR XOR NOR, << >>
  (by one), X<<Y X>>Y, NOT NEG RoL RoR, mod, flip₈ flip₁₆, digits A–F, FF, 00, parentheses.
  The bit editor shows the 64 bits in groups of four; clicking a bit toggles it. ASCII /
  Unicode shows the character of the value; "Hide binary" hides the bit editor.

## Commands

| Id | Shortcut | What |
| --- | --- | --- |
| `calculator.mode.basic` | ⌘1 | basic mode |
| `calculator.mode.scientific` | ⌘2 | scientific mode |
| `calculator.mode.programmer` | ⌘3 | programmer mode |
| `calculator.copy` | ⌘C | copy the value on the display |
| `calculator.paste` | ⌘V | paste a number (either separator) |
| `calculator.equals` | Return, = | evaluate |
| `calculator.clear` | Esc, Delete | clear |
| `calculator.backspace` | Backspace | delete the last character |

Typed keys: digits, `.` `,`, `+ - * x / :`, `%`, `=`; scientific `^ ( ) !`; programmer
digits 0–F, `& | ^ ~ %`, `( )`.

## Known gaps

- The app cannot resize its window yet (silica-desktop#1): the `.desktop` entry starts at the
  basic size (`--size 230x408`); another mode keeps its measured layout anchored at the top-left
  corner until the embedder offers `silica/window` › `setSize`, which the app already calls.
- History sidebar (⌃⌘S, +220 pt), Convert and RPN modes, the first-launch tip, the decimal
  places setting and the thousands-separator toggle are not implemented. The zoom button is
  not disabled (Ossido does not know the window is fixed).
- Pressed colours of the scientific and programmer keys and the pressed state of the toolbar
  buttons are not measured (estimated: digit +36 levels; no pressed state).
