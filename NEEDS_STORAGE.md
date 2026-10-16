# Needs storage: separate stacks

Mia's request: with 5 of 10 of an item on cell 1, dropping one item on another cell must leave it there as a
stack of its own, not join the five; Shift+click on a stack splits it; dropping onto a stack of the same class
still merges, on purpose. The window cannot do this alone, because the storage has no such thing as two partial
stacks of one class in one container.

## Why the window cannot

- `einv_storage_fnc_getContents` builds the tiles from the cargo's counts: `_fnc_addStacked` cuts a class's
  total into full stacks plus one remainder. 5 and 1 of a stack-10 class are always one tile of 6, whichever cell
  the one was put on.
- `einv_storage_fnc_getLayout` / `fnc_setPlace` keep one record per tile, `[key, col, row, w, h, block, rot]`,
  matched to the n-th entry of that key. There is nowhere to say how many a tile holds.
- `fnc_opPut` / `fnc_opMove` add the payload to the cargo (`fnc_addPayload`) and the count simply grows.
- Within one container a part of a stack is a no-op today (`fnc_sendMoves`: "a container holds a class as one").

## What the window already does (inert until the storage says it can)

The window only acts on the new behaviour while `missionNamespace getVariable "einv_storage_stackSplits"` is
`true`. Until then it behaves exactly as in 0.4.22: drops join, Shift+click selects a range.

| Where | What it sends / does |
|---|---|
| `einv_gui_fnc_endDrag` | a drop on a cell (`place`) passes the option `"separate", true` to `fnc_applyMove`; part of a stack let go in its own container is no longer dropped as a no-op |
| `einv_gui_fnc_applyMove` | puts `"separate"` into the move HashMap |
| `einv_gui_fnc_sendMoves` | move to another holder: the `put` step's args are `[to, payload, cell, false, false, true]` (separate is the 6th); within one root the `move` step's args are `[from, to, payload, count, cell, true]`; within one holder with a count smaller than the tile's: a new op `split` with args `[holder, payload, count, cell]` (cell `[]` = nearest free) |
| `einv_gui_fnc_splitStack` | Shift+click on a stack of two or more: `fnc_applyMove` from = to = the container, half the stack, cell `[]`, `"separate", true` |
| `einv_gui_fnc_hoverKeys` | shows "Shift+Click Split" instead of "Shift+Drag Half stack" |

## The change in `addons/storage`

1. **Flag.** In `XEH_preInit.sqf`, on every machine, once the rest is in: `missionNamespace setVariable ["einv_storage_stackSplits", true]`
   (`GVAR(stackSplits) = true`). Leave it out (or false) to switch the window's new behaviour off again.

2. **Where the counts live.** Extend the places record with a trailing count for a stackable tile:
   `[key, col, row, w, h, block, rot, count]`. `fnc_readPlaces` / `fnc_writePlaces` / `fnc_setPlace` /
   `fnc_dumpPlaces` keep it (a record without it is "as many as the layout gives", i.e. today's behaviour, so old
   saves and old clients read fine). `fnc_entryKey` stays the class (+ rounds for a magazine); the n-th record of a
   key is the n-th tile of that key.

3. **getContents.** `_fnc_addStacked` takes the holder's records for the key: one tile per record, with the
   record's count; the cargo's total is then reconciled with the sum of the records:
   - total above the sum (the engine or a script added items): the surplus tops up the last tile that has room,
     then opens new tiles of a full stack;
   - total below the sum (items left without the window): remove from the last tile(s) first;
   - no records for the key: today's cut (full stacks first, then the remainder).
   `fnc_normalize` persists the reconciled records (the same drift path as positions).

4. **Ops** (all with the argument shapes above, `separate` false/absent = today):
   - `put` with `separate`: the payload becomes a **new tile** of its own at the requested cell (or the first fit),
     with a record whose count is the payload's count; it joins nothing. If the count exceeds one stack it is cut
     into full tiles as usual. Without `separate` the payload joins the first tile of its key that has room (the
     layout's present behaviour), which is what Quick move, Take all, Sort and `fnc_plan` rely on - they keep
     filling partial stacks.
   - `move` (container to container within one root): the same, via its put half.
   - `take` of part of a stack: the tile's record count goes down by the count taken; a tile at zero loses its
     record. `take` of the whole tile removes the record.
   - new op **`split`** `[holder, payload, count, cell]`: within one holder, lift `count` from the tile the payload
     names (record count down by `count`) and lay it down as a new tile at `cell`, or - cell `[]` - at the free
     spot nearest to the source tile's cell (compartment of the source first, then the others; upright, then
     turned). No free spot: reason `"NoRoom"`, nothing changes. The cargo is untouched - it is a change of the
     records only, one `placeMany`-like write.
   - register `split` where the ops are registered (`fnc_execute`) and in `GVAR(holderTypes)` for containers; kit
     holders leave it out (the window then does nothing for them).

5. **Counting room.** `fnc_hasSpace`, `fnc_hasRoom`, `fnc_plan` and the ACE Arsenal checks count tiles from the
   records: two partial tiles of a class cost two spots, and a plan that fills a class fills the partial tiles
   first. Surplus handling (`fnc_hiddenSweep` and the "Surplus" doc) needs a free spot per tile as before.

6. **Never merge on their own.** Two tiles of one class in one container stay two until the player merges them
   (the window's follow-up below), Sort, or Take all / Quick move fills them. `Sort` may merge: it re-lays
   everything out, which is the player asking.

## Window follow-up once the storage has it

- **Drop onto a stack of the same class merges** (explicit). `fnc_updateDrag` today refuses a footprint over a
  taken tile of the same class as `"NoRoom"` (`fnc_swapPlan`: "the same class only merges"). With the flag on it
  should answer `["grid", ..., merge]` when the footprint covers exactly one searched, not-pending tile of the
  same class with room left, and `fnc_endDrag` should send a `put` with the target tile's key (`"mergeInto"`) so the
  storage adds to *that* record. Not written yet: it needs the op to exist to be tested.
- Tests to run in game after both: 5/10 on cell 1, drop 1 elsewhere in the same container (split, two tiles), in
  another container (two tiles), onto the stack of five (merge); Shift+click; Quick move of the single to a
  container that holds a partial stack (fills it); Take all; close and reopen (records persist); another player
  adding the same class by script (reconciled, no loss); old save without counts.
