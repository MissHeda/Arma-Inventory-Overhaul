**Review: setup wizard, rule definitions and shaped items**

I checked the design against the repo (v0.1.12, no git commits) and against the CBA 3.19.0 source. I unpacked `cba_settings`, `cba_ui`, `cba_common` and `cba_xeh` from the local Workshop copy into the scratchpad. No repo files were changed.

**Verdict:** the approach is sound: one CBA EDITBOX holds the setup, named groups give batch editing, and shapes become forms. It should not be implemented as written. There are three blockers, several statements that contradict the code or CBA, and the work packages cannot be built or tested on their own.

These CBA claims in the design are confirmed:
- A mission value and a server value at priority 1 tie, and the mission wins. CBA picks the first highest value in the order client, mission, server.
- Client values never count for a global (`isGlobal 1`) setting.
- `force force` means priority 2.
- `cba_main` requires `cba_settings`, so our display-load entry runs after CBA's.
- The category key is the lower-case category name.
- Load (IDC 9021) and Import (IDC 9010) sit at row 21.7, and the space between them (grid x 13.6 to 26.4) is free.
- `cba_settings_fnc_import` writes into CBA's temporary values and refreshes the menu.

## A. Blockers

**1. In Eden the wizard is dead and the rules are never compiled.**
- CBA's per-frame loop is started only in `cba_common` XEH_postInit, and postInit does not run in Eden.
- The gui kit's only button defers every click through `CBA_fnc_execNextFrame` (`fnc_uiButton.sqf` lines 109 and 117). Every button would do nothing when the wizard is opened from the Eden Tools menu or from CBA's menu in Eden. Indexing in chunks per frame and the coverage counts would never run either.
- CBA runs a setting's script only after `cba_settings_ready` is set, which happens in postInit. So `loadRules` never runs in Eden.
- The planned fallback ("compile `aio1 base=default` if nothing is compiled yet") then shows the shipped default, not the mission's text.
- **Fix, part 1:** the wizard gets its own way to defer code, either `_this spawn {isNil {...}}` (what CBA's own Eden code uses) or its own EachFrame handler tied to the wizard display. Setup code must never use `EFUNC(gui,uiButton)`, `fnc_openMenu` or CBA per-frame handlers.
- **Fix, part 2:** the fallback compiles `missionNamespace getVariable "aio_items_rules"`, not the default, and recompiles whenever that text differs from the one it compiled. This also covers the gap between preInit and the moment CBA settings are ready, where every machine would otherwise cache sizes from the default.

**2. The default groups are not a partition, although the design relies on that.**
- `@mag_large` (mass over 20) also contains `@rocket` (20 to 60), `@rocket_heavy` and `@belt` above 20.
- `@mag_rifle` (5 to 20) also contains belts and rockets between 15 and 20.
- Inside the preset, "later wins" hides this. But an own rule beats every preset rule. Editing "Large magazines" in step 2 (`@mag_large > size=3x2`) would therefore also resize all rockets and belts.
- **Fix:**
  - `@mag_rifle: kind=magazine mass>5 mass<=20 !@belt !@rocket`
  - `@mag_large: kind=magazine mass>20 !@belt !@rocket !@rocket_heavy`
  - The check script should assert that the preset groups really don't overlap.
- Overlay groups such as `@medical` and groups the user makes overlap on purpose:
  - Define their precedence: the writer puts overlay-group rules after the plain group rules.
  - Step 2 says "N items are also in X; X wins".

**3. A `;` in the stored text breaks CBA.**
- `cba_settings_fnc_parse` splits on `;` with no regard for quotes. One `;` breaks CBA's Export and any `cba_settings.sqf` line holding the text.
- At server start the broken value fails CBA's check, and the server silently falls back to the default.
- Section 2.2 still reads `;`, and CBA's own text box accepts it.
- **Fix:**
  - The parser treats `;` as an invalid character.
  - Register the setting with CBA 3.19's EDITBOX sanitizer, which CBA calls on every key press in its row: `valueInfo = ["aio1 base=default", false, {sanitize}]`. The sanitizer turns `;` and line breaks into `,` and removes `"`, `'`, `#` and `\`.

## B. Wrong or contradicting the code

1. **7-element records are dropped.** `fnc_getLayout.sqf:93` and `fnc_setPlace.sqf:54` only accept records matching `isEqualTypeArray ["",0,0,0,0,0]`. A record with a seventh field is ignored by getLayout. setPlace never finds it, so a moved item snaps back. WP2 must accept 6 and 7 elements.
2. **`MAX_ROWS` is out of reach.** It lives in `storage/script_component.hpp:12`, which WP1's parser in the items addon cannot see.
   - Move it to `main/script_macros.hpp`, which is WP2's file.
   - Also clamp item footprint height, which has no limit now.
   - Also cap the total cells across `WxH+WxH`. Each cell is one control, so `8x40+8x40+…` makes thousands. Today's container table has the same gap.
3. **The arsenal addon is in no work package.**
   - It calls getLayout and getInfo (`fnc_onCargoChanged.sqf:107/127`, `fnc_checkOverflow.sqf:29`).
   - The signatures stay compatible, but it must be in the test plan.
   - The setup addon must not require `ace_arsenal`.
4. **WP3's file list is incomplete.**
   - `fnc_drawSection.sqf` is missing. Its overflow line gives each overflowing item a box of its full width × height (lines 181–187 and 300), so a shaped item there shows its empty notch as grid cells.
   - `fnc_makeGhost.sqf:36` works out "turned" from a width check.
   - `fnc_updateDrag.sqf:69` re-applies a fixed 90° every frame.
   - The last two are on the list, but both must carry the turn count rather than a true/false flag.
5. **Sending turns over the network is unnecessary.** The server never uses w, h, col or row from `entryToArray`: `moveEntry` with layouts off skips `setPlace`. `onServerAnswer` uses the cell it kept when the request went out. Drop that change.
6. **Check 8.7 tests something that isn't true today.** "Two clients agree on layouts" fails already: records are per machine and arrangements differ as soon as anyone drags. The real check is the same compartments, the same footprints and the same overflow count for the same contents.
7. **"Locked by cba_settings.sqf" is not fully accurate.** CBA's `fnc_set` still applies the new value for the session and only skips saving it. Read-only in the wizard is fine, but the reason shown should be "would be lost on restart".
8. **Project state.**
   - The version is 0.1.12, not 0.1.11.
   - The tables job has already landed: `fnc_parseTable`, `fnc_findInTable`, `fnc_parseContainerTable`, the settings and their stringtable keys are all in the tree.
   - There is no git history, and ARCHITECTURE.md says never commit. The merge order in section 7 has nothing to merge: six agents would write into one working tree.
9. **Retiring the three tables is Mia's call.** They come from the earlier "Milsim definitions" round. The fallback (read them as own rules appended last) is cheap and keeps her choice open.
10. **The version-mismatch warning would fire on every change.** The public hash and CBA's setting refresh reach a client in either order.
    - Publish `[text, hash]` and compare only when the texts match.
    - The hash cannot see another mod patching `aio_gridSize` or `aio_gridShape`. Document that.
    - Comparing `CfgPatches >> aio_main >> versionStr` between server and client is simpler and catches different mod versions too.
11. **The conflict check compares against the wrong value.**
    - "Someone else saved in between" must compare with the target source's own value (`[setting, source] call cba_settings_fnc_get`), not the value in effect.
    - In Eden the value in effect is the server tab, which is the mission maker's own profile.
    - In menu mode, read the source currently selected in CBA's menu.

## C. Missing

**Multiplayer and JIP**
- **Tell the admin when a server save won't show.** A server save at priority 1 ties with any mission that sets its own value, and the mission wins.
- **Override in single player is dangerous.** There "server" is the player's own profile. Priority 2 would stay in force for every later mission, hosted multiplayer included. Hide the override in SP or warn.
- **Repack after a rules change.**
  - getLayout keeps every record that still matches and first-fits the rest. Gaps left behind can push items into overflow that would fit in a fresh layout.
  - Store the rules hash next to the layout (`aio_storage_layoutRules`).
  - When it differs, also lay the container out without records and keep that result if it has less overflow.
- **Arsenal timing.** The arsenal sees new rules only at its next event. Loadouts that overflow after a mid-mission change just show red until then.
- **Keep the wizard's facts out of save games.** Facts for 20,000+ classes in missionNamespace end up in single-player saves. Keep the wizard's facts and index in uiNamespace: they don't change within a game session.

**Eden**
- Blocker A1 applies.
- A mission's value persists only once the scenario is saved.
- The arsenal addon skips Eden (`is3DEN` guard), so the wizard's container preview is the only fit check mission makers get there. Say so in the wizard.

**Performance**
- **Filter the class index.**
  - Vehicle weapons (CfgWeapons type 65536) currently come out as kind "item", so thousands of them would fill the list.
  - CfgMagazines holds vehicle magazines.
  - The new "vehicle" kind would include every soldier class.
  - Keep weapons of type 1, 2, 4, 4096 and 131072 only; man-portable magazines only; vehicles only with maximumLoad above 0 and not soldiers.
- **Budget the index by frame time.** "8,000 classes in under 1 s" is optimistic for RHS or CUP packs with 30,000+ classes.
- **Remember group membership per class** while resolving, since several rules ask about the same group.
- **Caps:**
  - at most 500 statements;
  - at most 64 alternatives in one `|` list;
  - `class~` text at least 3 characters;
  - warn above 8 KB, refuse above 16 KB;
  - at most 24 compartments and 320 cells per container.
- **Build the `well=` lookup only when a rule uses it**, on the server too.

**Bad strings**
- **An undefined group reference must drop the whole statement**, not count as false. Otherwise `!@typo > stack=1` hits every item.
- **An own group referring to itself** (`@mag_rifle: @mag_rifle class=…`) is a loop under "own replaces preset". Either reject it, or define it as "extend the preset group", which is useful for adding one class to a group.
- **Define the remaining bad cases:** header missing, not first or given twice; `size=0x3`; `stack=0`; huge or negative numbers.
- **The compiled rules must be plain data**, never compiled code. They end up in save games and are broadcast.

**Rotation**
- `@N` in a shape: `parseShape` should build the turn into the first form, so auto-turn tries the turns in order from there.
- `uiPictureTurned` swaps width and height for a quarter turn. At 180° the control must keep its upright shape.
- When dragging inside the same grid, the overlap test must ignore the dragged tile's own cells.

**UX**
- **Return to the inventory.** "Change size or shape..." leaves the player on the plain game screen. Reopen the inventory when the wizard closes, if it was opened from there.
- **Warn about footprints that fit nowhere.** An L3 magazine never fits 1×2 pouches; flag that in steps 3 and 5.
- **Always save class lists with `+`.** Instance classes from TFAR, ACRE and EFAK/EUP kits (the compatibility note in BRIEFING.md) are then covered too.
- **Explain `cell=`.** It changes both mass-based sizes and every container sized by load. Say so on the stepper.
- **Optional:** "Fill with: my ACE Arsenal loadouts" in step 4.

## D. Work packages that are not really separate

1. **WP4 depends on files from WP5 and WP6 at build time.**
   - WP4's `config.cpp`, `XEH_PREP.hpp` and `XEH_preInit.sqf` include WP5's `XEH_PREP_steps.hpp` and WP6's `XEH_PREP_entry.hpp`, `Display3DEN.hpp` and `initEntryPoints.inc.sqf`.
   - WP4's stringtable holds the keys of WP5 and WP6.
   - So none of WP4, WP5 or WP6 passes `hemtt check` alone.
   - **Fix:** WP4 creates the four files as empty stubs on day one and hands them over. Freeze the key list before starting.
2. **WP1 and WP2 depend on each other.**
   - WP1's items PREP list and `config.cpp` register WP2's functions.
   - WP1's getInfo and parseRules call WP2's functions.
   - Moving `MAX_ROWS` touches WP2's macros file.
   - Neither can be tested alone, so treat them as one phase.
3. **WP4 and WP5 depend on each other.** WP4's step 1 needs WP5's `previewGrid`; WP5 needs WP4's widgets. Move `previewGrid` into WP4.
4. **ARCHITECTURE.md comes first.** It is the binding contract ("fix it here first"). Section 5 belongs in `docs/ARCHITECTURE.md` before any package starts, not in the integration step at the end.
5. **One phase at a time.** BRIEFING.md asks for one phase at a time, with Mia testing between phases. Six packages with the first game test at the end contradicts that. Suggested phases, each ending in a test in the game:
   1. Rules engine, default port, CBA text box and live reload. No shapes. The check script must show no differences except the stackSmall case.
   2. Shapes in the layout engine and the window, driven by a rule typed into the CBA box.
   3. Wizard frame, saving and sharing, steps 1 and 5, and the entry points. Test in Eden and with a multiplayer admin.
   4. Steps 2–4, split further: index plus list plus step 3, then groups, then containers.

## E. Add to the in-game checks

- **RscEdit's default `maxChars`.** CBA's row and CBA's Export box are both plain RscEdit, and nothing in CBA's config sets it. CBA's KeyUp handler writes the box text back on any key press, even Ctrl+C. A box that cuts the text would therefore save cut rules.
- **Whether `CBA_fnc_execNextFrame` fires while single player is paused.** This covers the pause menu, and the Addon Options screen, which pauses the game.
- **Eden:** wizard buttons, building the index, and saving to the mission (after fix A1).
- **Main menu:** CBA's options screen stops early there, before it creates Load and Import, so the button's missing-control guard is required.

**CBA dependencies to note:**
- CBA marks `cba_settings_fnc_set`, `fnc_import` and `fnc_parse` as internal functions.
- The design also relies on the temporary values in uiNamespace, the IDCs and button row 21.7.
- CBA 3.19 reworked its settings screen recently, so these may change.

Files referenced:
- C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign\addons\storage\functions\fnc_getLayout.sqf
- C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign\addons\storage\functions\fnc_setPlace.sqf
- C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign\addons\storage\script_component.hpp
- C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign\addons\gui\functions\fnc_uiButton.sqf
- C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign\addons\gui\functions\fnc_drawSection.sqf
- C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign\addons\gui\functions\fnc_makeGhost.sqf
- C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign\addons\gui\functions\fnc_updateDrag.sqf
- C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign\addons\arsenal\functions\fnc_onCargoChanged.sqf
- C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign\addons\arsenal\functions\fnc_checkOverflow.sqf
- C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign\docs\ARCHITECTURE.md
- C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign\docs\BRIEFING.md
- CBA source, unpacked: C:\Users\Heda\AppData\Local\Temp\claude\C--Users-Heda-GitHub-Repos\dd03a67c-7561-4733-b916-702a4bb4c42b\scratchpad\pbo\cba_settings\ (`fnc_parse.sqf`, `fnc_set.sqf`, `fnc_import.sqf`, `fnc_priority.sqf`, `fnc_init.sqf`, `fnc_gui_settingEditbox.sqf`, `fnc_initDisplayGameOptions.sqf`, `script_component.hpp`, `XEH_postInit.sqf`) and ...\scratchpad\pbo\cba_common\XEH_postInit.sqf