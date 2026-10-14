# History sidebar

Session CA-01.

- Opened with ⌃⌘S or the History toolbar button. The window grows by **220 pt** to the
  right (230 → 450 wide, height unchanged, origin unchanged) and the sidebar takes the new
  space on the left; the keypad shifts right with it.
- Sidebar background `#2b2b2d` to `#2e2e30` (slight gradient); divider `#3a3b3c`; scroll bar
  `#727273`.

| Element | Geometry | Text |
| --- | --- | --- |
| Section header (e.g. today, last 30 days) | row 36 pt | bold, `#7d7e80`, ≈ 11 pt cap height |
| Record | row 64 pt (cell 171 × 56) | expression above in `#a0a0a1`, small (≈ 7 pt cap height); result below in `#eaeaea` (≈ 12 pt cap height) |

- Records are separated by thin lines.
- Each record offers two actions from its context menu: copy and delete.
- Hover and selection of a record: *unmeasured*.
- Opening animation: *unmeasured* (the mode switch, which also resizes the window, is
  instant; the sidebar is expected to behave the same, *provisional*).
