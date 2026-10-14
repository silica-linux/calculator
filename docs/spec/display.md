# Display

Sessions CA-01, CA-02. Positions are window coordinates.

## Basic display

| State | Content | Cap height | Colour |
| --- | --- | --- | --- |
| Entry | "0", or the expression typed so far ("12+34") on one line | **24 pt** (≈ 34 pt type) | `#dedede` |
| After = | result on the main line; the expression moves to a smaller line above | main 24 pt; above **17 pt** (≈ 24 pt type) | above `#9e9e9e` |
| Long entry (19 digits) | type drops to 17 pt cap height; the start of the number slides out to the left under a ≈ 13 pt fade at the left edge | 17 pt | `#dedede` |
| 2 ÷ 3 = | "0.66666667" (8 decimals, the default setting) | 24 pt | `#dedede` |

- The display area (accessibility frame) is 210 × 42 pt at (10, 86).
- Text is right-aligned with its right edge at x 218 (12 pt from the window edge).
- Baselines: main line y 119, expression line y 81 (38 pt apart).
- Ink boxes after 12 + 34 =: result "46" x 162–197, y 77–98; expression "12+34" x 141–198,
  y 45–60. `docs/parity.md` compares them with Silica.

## Convert mode

- Two lines: the input value with its unit, and the converted value with its unit
  (example: 12 in euros gives 13.44 in dollars). The converted line uses `#9e9e9e`.
- Each line has a unit pop-up (hit area 42 × 14 pt: the unit code in small capitals and an
  up/down chevron).
- A swap-units button (35 × 31 pt, an orange up/down arrow pair) sits to the left.
- The unit picker is a popover of 356 × 486 pt: a search field, a row of category chips
  (angle, area, currency, data, energy, force, …; the selected chip is orange), a list of
  units with their code under the name, a check mark on the current unit, and a footer
  naming the currency rates source and the time of the last update.
- Window height in this mode: 461 pt.

## RPN mode

- The display becomes a stack of four lines (210 × 138 pt; ≈ 35 pt per line, 1 pt lines
  between them).
- Under the stack, a row of four capsules 48 × 28 pt: swap x and y, roll down, roll up,
  drop.
- Window height in this mode: 498 pt.

## Programmer panel

- The value carries its base as a subscript ("0₁₆").
- Segmented controls, 24 pt tall: character view ASCII | Unicode (150 pt wide), the binary
  toggle (126 pt, label `hideBinary` / `showBinary`), and the base selector 8 | 10 | 16
  (117 pt). The selected base segment is orange `#ff960e`.
- Unselected segments `#373738`; bit editor background `#484849`.
- Bit editor 468 × 61 pt: two rows of 32 bits in groups of four, each bit about 9 × 15 pt,
  with position labels 63, 47, 32 over the first row and 31, 15, 0 over the second.
- Clicking a bit flips it (behaviour; the visual of a flipped bit is *unmeasured*).
