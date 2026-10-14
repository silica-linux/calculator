# Window

Sessions CA-01, CA-02.

## Appearance

- The calculator is always dark. Switching the system between light and dark produced two
  captures that were identical pixel for pixel, in every mode (basic, scientific,
  programmer, RPN, convert, history).
- Window background `#272727`.
- Window outline: a 1 pt `#060606` line outside and a 1 pt `#3d3d3d` rim just inside it
  (read on the top and bottom edges).

## Size per mode

| Mode | Window (pt) | Keys (pt) | Grid (cols × rows) | Pitch (pt) |
| --- | --- | --- | --- | --- |
| Basic | **230 × 408** | 48 × 48 circles | 4 × 5 | 54 (6 gap) |
| Basic + Convert | 230 × 461 | 48 × 48 | 4 × 5 | 54 |
| Basic + RPN | 230 × 498 | 48 × 48, plus one row of four 48 × 28 capsules | 4 × 5 + 1 | 54 |
| Basic + history sidebar | 450 × 408 (sidebar 220) | 48 × 48 | 4 × 5 | 54 |
| Scientific | **674 × 408** | 60 × 48 capsules | 10 × 5 | 66 × 54 |
| Programmer | **488 × 582** | 62 × 48 capsules | 7 × 6 | ≈ 67.7 × 54 |

- Programmer column left edges (window x): 10, 78, 145, 213, 281, 349, 416. The pitch is
  not an integer, so columns alternate between 67 and 68 pt.
- The keypad keeps a 10 pt margin to the left, right and bottom window edges. Check:
  basic 10 + 4 × 48 + 3 × 6 + 10 = 230; scientific 10 + 10 × 60 + 9 × 6 + 10 = 674.
- The size is fixed: requests to resize the window are ignored and the zoom (green) button
  is disabled.
- Changing mode resizes the window around a fixed **top-left** corner; the origin does not
  move. The change happens in one frame (see [modes-and-menus.md](modes-and-menus.md)).

Geometry of the basic mode: [diagrams/basic-layout.svg](diagrams/basic-layout.svg).

## Toolbar

| Element | Geometry (pt) | Notes |
| --- | --- | --- |
| Toolbar | height 52, full width | unified with the title area |
| Window buttons | 14 pt circles; hit areas 16 × 16 at x 18, 41, 64, y 18 | pitch 23 |
| History button | hit area 44 × 52 at x 92 | absent in the programmer mode |
| Mode button | hit area 40 × 52 at x 186 (basic) | flush with the right edge |
| Visible button shape | 36 pt circle, fill `#444545`, 1 pt `#0f0f0f` outline, white glyph | both buttons |

- Only the Mode button reacts to the pointer: hover changes its fill from `#454546` to
  `#4e4e4f`. Pressed state of the toolbar buttons: *unmeasured*.

## Inactive window

The rule is the same in every mode (checked in basic, scientific and programmer): every
coloured or light fill drops to a dark gray, glyphs stay white and the display does not
change.

| Element | Active | Inactive |
| --- | --- | --- |
| Operators ÷ × − + = | `#ff8b00` | **`#545555`** |
| ⌫, AC/C, % | `#919191` | `#545555` (same as the operators) |
| Scientific and programmer function keys | `#585859` | `#474749` |
| Digits, hex A–F, 00, FF | `#6a6a6b` | `#4d4d4e` |
| Programmer base segment, selected | `#ff960e` | **`#505051`** |
| Unselected segments / bit editor | `#373738` / `#484849` | unchanged |
| Toolbar buttons | `#444546` | `#3b3b3c` |
| Window buttons | coloured | `#4b4b4c` |
| Display text | `#dedede` | unchanged |

## First-run tip

- On the very first launch a tip popover points at the Mode button. It has a short title
  (it introduces the mode menu), one line of explanation and a close (×) button.
- Popover size 470 × 115 pt including its arrow, placed above the button.
- Once closed it never comes back.
- Fill, text sizes and the arrow geometry: *unmeasured*.
