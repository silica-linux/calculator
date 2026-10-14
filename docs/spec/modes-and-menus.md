# Modes and menus

Sessions CA-01, CA-02.

## Switching modes

- Shortcuts: ⌘1 basic, ⌘2 scientific, ⌘3 programmer.
- There is **no animation**. The window size and the keypad change together in a single
  frame. Only latency was measured, from the key-down to that frame:

| Switch | Latency |
| --- | --- |
| basic → scientific (⌘2) | 208 ms |
| scientific → programmer (⌘3) | 451 ms |
| programmer → basic (⌘1) | 261 ms |

The latency is the reference system's own delay; Silica only needs the one-frame swap.

## Mode menu (toolbar)

The Mode button opens a menu with, top to bottom, each item with a small symbol on its left:

1. Basic (checked when current), Scientific, Programmer
2. separator, then an entry that hands the calculation over to the notes app (⌥⌘M)
3. separator, then Convert and RPN mode (both toggles)

The notes entry opens a different application; it is out of scope for this app.

## Menu bar

| Menu | Content |
| --- | --- |
| App menu | standard items |
| Edit | Copy ⌘C, Paste ⌘V; Cut and Undo present but disabled |
| View | Basic ⌘1, Scientific ⌘2, Programmer ⌘3 · notes hand-over ⌥⌘M · Convert ⌥⌘C, RPN mode ⌘R · hide thousands separator, decimal places › 0–15 (default 8) · show history ⌃⌘S, full screen (disabled) |
| Window | standard items |
| Help | standard items |

"·" marks a separator.
