# Changelog

All notable changes to Enhanced Inventory. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 0.4.0 - unreleased

### Added

- ACE Arsenal panel: a grid panel on ACE's own display for the selected uniform, vest or backpack tab. Items ACE adds land on the grid, tiles are re-sorted by drag, a tile dropped outside leaves the container, and an add with no free cell is taken back with ACE's message.
- Arsenal staging space: a grid under the container that holds items while the soldier rearranges; it is deleted with ACE's window and grows with its contents.
- Arsenal list drag and wheel: a row of ACE's list can be dragged straight onto a cell, the wheel sets the count while dragging, Ctrl+wheel over a tile adds or removes one. The panel's sections fold.
- Backpack as the fourth slot of the gear row (headgear, uniform, vest, backpack).
- Shaped grids: `grid=` takes a mask (`grid=xxxx/x--x+2x3`, `x` a cell, `-` a hole) and a whole container can be one canvas with a letter per compartment (`grid=abbbbbc/abbbbbc/-bbbbb-`), drawn where it was painted.
- Shaped items: `size=xx/x-` makes an L of three cells; the footprint follows the shape in both orientations, and R turns it. Place records gain an optional rotation.
- `like=CLASS`: a class takes another class's resolved size, stack and grid.
- Grids up to 10 cells wide.
- Presets Default and Realism. Default gives containers 20 % more room; Realism is the former Tarkov preset and stacks as Default does.
- Setup wizard: paint the compartments with colours, a Blocks mode for the block-by-block editor, "Same as another class" (follow with `like=` or copy the cells), a plain preset choice on Start with the cell size under Advanced, a welcome page and a "What you changed" list that removes a rule or jumps to its class.
- Window details: a right-click on another tile while a menu is open moves the menu, and counts and fill texts sit on a dark pill so white pictures do not hide them.
- Client setting `einv_storage_debugDrop`: writes every step of a backpack drop to the RPT.

### Changed

- Cells are the only room: what fits into a container is decided by free grid cells alone. Weight is still shown and drives the weight bar and ACE fatigue, but no move is refused because of it.
- The own arsenal window is replaced by the panel inside ACE Arsenal (the vanilla Virtual Arsenal handling stays, with "ace" in place of "enhanced").
- The weight bar loses its yellow and red ticks: the fill colours by tier and the texts name the next limit and its effect on movement.
- Stackable tiles show n/stack in a flat box bottom right, nothing for a stack of one.
- Backpacks with load 0 take an own grid and are listed by the wizard.
- The wizard has four steps: Start, Items, Containers, Review.

### Removed

- The container weight limit: `roomByWeight`, `getLoadState`, the "Limit by room only" setting, the load bars, "full" chips, red free cells, weight marks and every TooHeavy path. `getMaxLoad` stays only to size a container's default grid.
- The own arsenal window.
- The greyed "Groups" step of the wizard; group rules (`@group > ...`) are edited in the Review step's text.

### Fixed

- Better Inventory (workshop 2791403093) no longer pulls its vanilla display in over the window: a vanilla inventory that loads while the window is open, or right after it blocked the vanilla one, is closed again (display load event, plus a check in the frame), and its Shift/Ctrl stack move, which needs state only its own display sets up, stays off while the window is open. With the window switched off nothing is touched.
- A backpack dropped to the ground no longer vanishes. The cause, found in game: `removeBackpack` leaves the backpack just taken off in a plain holder of the engine's own until the end of the frame and deletes both then - the pile search took that holder for a pile with something in it and put the new backpack into it. A backpack now joins only a pile of ours (`GroundWeaponHolder_Scripted`) or a fresh one, the backpack taken off is marked so its holder is never a target, and the RPT shows which pile a backpack goes onto and when a pile of ours is deleted.
- Setup wizard, Containers: Paint and Blocks preview the same configuration identically and as the inventory shows it - a painted layout that matches the flow is handed over without positions - and the Paint canvas cells are the same size as the Blocks cells.
- Taking a backpack off no longer loses it: the slot is read again a frame later when the engine is late, an arrived backpack is also recognised by the pile's count, and a failed drop puts the backpack back on.
- `hasSpace` counts partial stacks, and the arsenal lights its rows by the same answer.
- A press on the blank part of ACE's list no longer drags the old selection.
- The arsenal's hint no longer sinks under ACE's list: the focus leaves the list while the mouse is over the panel, and goes back to it when the mouse leaves, so ACE's arrow keys work without a click on the list first.
- The staging holder is made only when the soldier is this machine's own root, and a local-only root is never broadcast.
- Legacy place records without a rotation element are read without an out-of-range select.
- The wizard no longer uses commands newer than 2.16; Apply in the cell editor stays off until the drawing changed; `size=mass` items stay within the 8-wide item drawing.
- The count badge keeps its right alignment without a theme box.
- The Ctrl state follows every mouse and key event.
