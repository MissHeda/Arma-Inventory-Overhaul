I made no changes to the repo. Everything below comes from reading CBA 3.19.0.260808 (`cba_settings_src`, plus `cba_xeh`, `cba_ui`, `cba_keybinding` and `cba_main` unpacked from `!Workshop/@CBA_A3`) and vanilla `ui_f` config.

# CBA Addon Options integration for the Enhanced Inventory setup wizard

**Bottom line:**
- **(1) Button in our tab: yes.** It hooks in through `Extended_DisplayLoad_EventHandlers >> RscDisplayGameOptions`. It goes in the empty slot of CBA's bottom button row, between Load and Import, and is shown only while our category is selected.
- **(2) Button-type setting: no.** CBA has no such type.
- **(3) Server-wide writes:** use `CBA_settings_fnc_set` with source `"server"` (needs isServer, a logged-in admin, or the whitelist) or `"mission"` (Eden only). Both persist.
- **(4) Sharing:** the wizard can reuse CBA's import/export text format as its share string as-is. CBA's importer only works while the Addon Options menu is open; the parser works anywhere.

## 1. The Addon Options menu: display, controls, category change, our button

### How the menu opens

Every path ends in `cba_settings_fnc_openSettingsMenu` (`fnc_openSettingsMenu.sqf`):
- the pause menu, through the `cba_settings_MainMenuHelper` display;
- Eden: the "Options" entry in the menu bar, Ctrl+Alt+S, calling `findDisplay 313 call FUNC(openSettingsMenu)`;
- the briefing and lobby displays (`RscDisplayGetReady`, `RscDisplayServerGetReady`, `RscDisplayClientGetReady`), through button `cba_settings_ButtonConfigure`;
- vanilla Options > Game, then the toggle button.

`openSettingsMenu` does the following:
1. `_display createDisplay "RscDisplayGameOptions"`. This is the vanilla display; its idd is 151, going by vanilla's own `finddisplay 151` in the Layout button. Don't rely on the idd: CBA stores the display in `uiNamespace getVariable "cba_settings_display"`.
2. **After** onLoad it calls `cba_settings_fnc_gui_configure` on the toggle button. That function shows the addon page and hides the toggle (4302).
3. It hides BI's OK (999) and creates its own `RscButtonMenuOK` with idc 2, which calls `gui_saveTempData` on click. BI's Cancel (idc 2) is hidden and replaced by a plain button that calls `gui_confirmDiscard`.

The onLoad hook works because the display's onLoad calls `BIS_fnc_initDisplay`. CBA replaces that function with `\x\cba\addons\xeh\fnc_initDisplay.inc.sqf`, which runs:

```sqf
{ _args call compile getText _x } forEach configProperties [configFile >> "Extended_DisplayLoad_EventHandlers" >> _className, "isText _x"]
```

So `_this = [display]`, and the entries run **in config order**. Our `einv_main` requires `cba_main`, and `cba_main` requires `cba_settings`, so our entry always runs **after** `cba_settings_fnc_initDisplayGameOptions`.

### Controls and IDCs (from `script_component.hpp`, `gui.hpp`, `fnc_initDisplayGameOptions.sqf`)

Grid units: `POS_X(n) = n*GUI_GRID_W + GUI_GRID_CENTER_X`, `POS_Y(n) = n*GUI_GRID_H + GUI_GRID_CENTER_Y`.

| IDC | What | Where |
|---|---|---|
| 4301 | `CBA_AddonsGroup` (config). Hidden on the vanilla page, shown on the addon page. | x POS_X(1), y POS_Y(3.1), w 38, h 18.5 |
| 4311 | Search edit, inside 4301 | x 26, y 0.6 inside the group |
| **4312** | **Category combo** (`cba_settings_AddonsList`), created by script inside 4301. `lbData` = **lower-case category**, `lbSort`ed. | x 4.5, w 21, y 0.6 |
| 9043 / 9040 / 9041 / 9042 | "Overwrites" / client / mission labels, volatile warning, inside 4301 at y 1.85 | right side; the warning spans x 1–23 |
| 4302 | Toggle button: Configure Addons / Base | POS_X(20.15), POS_Y(23) |
| 9003 / 9002 / 9001 | Source buttons Server / Mission / Client | POS_Y(2.1), x 1 / 9 / 17 |
| 9020 / 9021 | Save / Load (scripted) | POS_Y(21.7), x 1.5 / 7.6, w 6, h 1 |
| 9010 / 9011 | Import / Export (scripted) | POS_Y(21.7), x 26.4 / 32.5, w 6, h 1 |
| 5000 + children | Setting rows (`cba_settings_Row_*` groups): name 5010, default 5020, lock icon 5030, overwrite checkboxes 5040/5041, editbox 5101, … | inside the per-category options group |

The per-category options group (`cba_settings_OptionsGroup`, idc -1) is created **lazily** the first time a category is selected. CBA keeps its state in these variables:
- `_display getVariable "cba_settings_optionsGroups"`: HashMap of lower-case category → group.
- On each group: `"cba_settings_rows"` and `"cba_settings_rowOrder"`.
- On each row: `"cba_settings_setting"` and `"cba_settings_source"`.
- In uiNamespace: `"cba_settings_addon"` (selected category key), `"cba_settings_source"` (`"client"`, `"mission"` or `"server"`), and `"cba_settings_clientTemp"` / `"cba_settings_missionTemp"` / `"cba_settings_serverTemp"`. The three temp variables are RscText controls used as namespaces for pending edits.

### What happens when the category changes

- `_ctrlAddonList ctrlAddEventHandler ["LBSelChanged", {_this call FUNC(gui_addonChanged)}]`.
- `cba_settings_fnc_gui_addonChanged [_ctrl, _index]`:
  1. exits while `cba_settings_lock` is set;
  2. reads `lbData`;
  3. sets `uiNamespace "cba_settings_addon"`;
  4. calls `gui_createCategory` if the group is missing;
  5. shows only that group;
  6. calls `gui_refresh`, then `gui_filterSettings`.
- **CBA raises no event for this** (no `CBA_fnc_localEvent`). There are also paths that never reach our LBSelChanged handler after the new state exists:
  - The initial `lbSetCurSel` happens inside CBA's own onLoad, before our handler is attached.
  - `gui_configure` shows group 4301 after onLoad, with no event.
  - The search fallback in `gui_searchSelect` does `LOCK; lbSetCurSel 0; UNLOCK; [_list, 0] call FUNC(gui_addonChanged)` directly.

  The robust way is therefore to poll with `MouseMoving` + `MouseHolding` on the display. CBA's own export dialog uses this same pattern (`fnc_gui_export.sqf`).

### Where the button goes

Put it in the **gap of CBA's bottom row**. Save/Load end at x 13.6 and Import starts at 26.4, all at POS_Y(21.7) with h 1, and nothing else sits there. The group 4301 ends at y 21.6, so the button sits exactly in line with the four RscButtonMenu buttons.

Size and place it **relative to Load (9021) and Import (9010)** rather than with hard-coded grid numbers, so it follows any CBA layout change.

**Alternatives:**
- The header strip inside 4301 (y ≈ 1.75–2.7, x 0.5–28) works, but only 0.95 high, and it collides with the volatile warning on dedicated servers that set `cba_settings_volatile`.
- A fake setting row whose control we cover with a button would get reflow, search and folding for free. However:
  - it is a fake setting that appears in exports and search;
  - it needs a sub-category name that sorts first, or CBA inserts its own "General" header;
  - it depends on the internal `optionsGroups` / `rows` variables.

  Not recommended.

### Config (example: a new `setup` addon; adjust names)

```cpp
// CfgEventHandlers.hpp
class Extended_PreStart_EventHandlers {
    class ADDON { init = QUOTE(call COMPILE_FILE(XEH_preStart)); };   // PREP the UI functions so uiNamespace has them in the main menu too
};
class Extended_DisplayLoad_EventHandlers {
    class RscDisplayGameOptions {
        ADDON = QUOTE(_this call (uiNamespace getVariable [ARR_2('FUNC(initCbaMenu)',{})]));
    };
};
// requiredAddons must (transitively) contain cba_settings - cba_main already does - so our entry runs after CBA's.
```

### fnc_initCbaMenu.sqf

```sqf
#include "script_component.hpp"
// RscDisplayGameOptions onLoad, after cba_settings_fnc_initDisplayGameOptions (config order).
#define CBA_IDC_ADDONS_GROUP 4301
#define CBA_IDC_ADDONS_LIST  4312
#define CBA_IDC_BTN_IMPORT   9010
#define CBA_IDC_BTN_LOAD     9021

params ["_display"];

private _list = _display displayCtrl CBA_IDC_ADDONS_LIST;
if (isNull _list) exitWith {};   // main menu: CBA bails out before creating the list ("need mission start")

private _load = _display displayCtrl CBA_IDC_BTN_LOAD;
private _import = _display displayCtrl CBA_IDC_BTN_IMPORT;
if (isNull _load || {isNull _import}) exitWith {};   // CBA layout changed - fall back to the other entry points

(ctrlPosition _load) params ["_lx", "_ly", "_lw", "_lh"];
(ctrlPosition _import) params ["_ix"];
private _gap = 0.2 * (((safeZoneW / safeZoneH) min 1.2) / 40);   // 0.2 grid

private _button = _display ctrlCreate ["RscButtonMenu", -1];   // no IDC - avoid collisions, keep the reference
_button ctrlSetPosition [_lx + _lw + _gap, _ly, (_ix - _gap) - (_lx + _lw + _gap), _lh];
_button ctrlCommit 0;
_button ctrlSetText LLSTRING(OpenWizard);
_button ctrlSetTooltip LLSTRING(OpenWizard_Tooltip);
_button ctrlShow false;
_button ctrlEnable false;
_button ctrlAddEventHandler ["ButtonClick", {
    [ctrlParent (_this select 0)] call (uiNamespace getVariable QFUNC(openWizard));
}];
_display setVariable [QGVAR(cbaButton), _button];

// Category key exactly as CBA computes it: lower case of the category *after* localize.
// Read it from the registered setting so a stringtable category keeps working.
_display setVariable [QGVAR(cbaCategory), toLower ((cba_settings_default getVariable ["einv_items_sizeTable", []]) param [4, "Enhanced Inventory"])];

private _sync = {
    params ["_display"];
    private _button = _display getVariable [QGVAR(cbaButton), controlNull];
    private _list = _display displayCtrl CBA_IDC_ADDONS_LIST;
    private _index = lbCurSel _list;
    private _show = ctrlShown (_display displayCtrl CBA_IDC_ADDONS_GROUP)
        && {_index >= 0}
        && {toLower (_list lbData _index) == (_display getVariable [QGVAR(cbaCategory), ""])};
    if (_show isNotEqualTo ctrlShown _button) then { _button ctrlShow _show; _button ctrlEnable _show; };
};
_display displayAddEventHandler ["MouseMoving", _sync];
_display displayAddEventHandler ["MouseHolding", _sync];   // fires continuously while the mouse rests
_list ctrlAddEventHandler ["LBSelChanged", compile format ["[ctrlParent (_this select 0)] call %1", _sync]];
```

The button then shows only while the addon page **and** our category are active. It hides when the user switches to vanilla options (4301 hidden), when a search filters our category away (the current `lbData` changes or `lbCurSel` is -1), and when our category is deselected. `ctrlCreate`d controls draw above config controls.

### Wizard opened from this button ("menu mode")

The parent display is the CBA menu; open the wizard with `_cbaDisplay createDisplay QGVAR(RscWizard)`.

**Source.** `uiNamespace getVariable "cba_settings_source"`.

**Write permission:** replicate CBA's macros:
- server: `(isServer || {call cba_settings_fnc_whitelisted}) && {!isNull cba_settings_server}`;
- mission: `is3DEN`;
- client: `!isServer`.

Client is useless for our tables: they are `isGlobal = 1`, so a client value never applies. Open read-only there, with the hint "switch to Server / Mission".

**Locked settings.** Treat a setting as locked if it is defined in a config file:
- server: `!isNil {cba_settings_serverConfig getVariable _setting}`;
- mission: `!isNil {cba_settings_missionConfig getVariable _setting}`.

CBA disables those rows and refuses to store them.

**Reading current values.** Read the pending (temp) value first, the same way CBA's `GET_TEMP_NAMESPACE_VALUE_OR_CURRENT` macro does:

```sqf
((uiNamespace getVariable "cba_settings_serverTemp") getVariable [_setting, []]) param [0, [_setting, "server"] call CBA_settings_fnc_get]
```

**Applying.** Hand the result to CBA's own importer. This writes the temp namespaces and `gui_refresh` updates our rows, which turn yellow. **CBA's OK** commits through `CBA_settings_fnc_set ..., true` with all permission and storage handling; **Cancel** goes through `confirmDiscard`, which lists our settings by display name.

```sqf
private _prio = ["force ", "force force "] select (_source == "server" && {_overrideMission});
private _text = [
    format ["%1einv_items_sizeTable = %2;", _prio, str _sizeTable],
    format ["%1einv_items_stackTable = %2;", _prio, str _stackTable],
    format ["%1einv_storage_containerTable = %2;", _prio, str _containerTable]
] joinString endl;
[_text, _source] call cba_settings_fnc_import;
```

For the mission source, always write `force` (priority 1). Otherwise the server's value (priority ≥ 1) wins; see section 3.

## 2. Is there a button-type setting? No. Fallbacks

**Setting types.** `fnc_init.sqf` accepts only `CHECKBOX`, `EDITBOX`, `LIST`, `SLIDER`, `COLOR` and `TIME`; `gui_createCategory` builds only those row classes. A setting's script (the 7th parameter) runs only after the value has been **saved** (OK → `set` → the `cba_settings_refreshSetting` event), so it cannot act as a button.

**Fallbacks, all opening the same `openWizard` in "direct mode":**

**a) Pause menu (public API, the same one CBA settings uses):**

```sqf
// XEH_preInit, hasInterface
[[LLSTRING(OpenWizard), LLSTRING(OpenWizard_Tooltip)], QGVAR(RscWizard)] call CBA_fnc_addPauseMenuOption;
```

This adds an entry under ESC > Options in both `RscDisplayInterrupt` and `RscDisplayMPInterrupt`. The engine runs `findDisplay <interrupt idd> createDisplay "einv_setup_RscWizard"`, so the wizard's onLoad has to cope with that parent. You can also use CBA's helper trick: an `RscDisplayEmpty` subclass whose onLoad opens the wizard and then closes itself (`cba_settings_MainMenuHelper`).

**b) CBA keybind:**

```sqf
[CBA_SETTINGS_EINV, QGVAR(openWizard), [LLSTRING(OpenWizard), LLSTRING(OpenWizard_Tooltip)], {[findDisplay 46] call FUNC(openWizard); true}] call CBA_fnc_addKeybind;
```

Leave it unbound by default (`KEYBIND_NULL`). It works only in a running mission (display 46), not in Eden or the main menu.

**c) Button in our inventory window header (cog icon).** Everyone can open it; non-admins get read-only plus export, so players can see and share the server's rules.

**d) Eden menu bar (config only, the same pattern as CBA's `Display3DEN.hpp`):**

```cpp
class ctrlMenuStrip;
class Display3DEN { class Controls { class MenuStrip: ctrlMenuStrip { class Items {
    class Tools { items[] += {QGVAR(openWizard)}; };   // CBA appends its entry to Options
    class GVAR(openWizard) { text = CSTRING(OpenWizard); action = QUOTE(findDisplay 313 call FUNC(openWizard)); };
}; }; }; };
```

## 3. Setting server-wide CBA settings from script

**Signature.** `[_setting, _value, _priority (0/1/2 or bool), _source "client"|"mission"|"server", _store bool] call CBA_settings_fnc_set` (`fnc_set.sqf`):
- From scheduled code it re-enters through `CBA_fnc_directCall`.
- It validates the value with `fnc_check`; for EDITBOX that is only `isEqualType ""`.
- It returns `false` if `[value, priority]` is unchanged.

**`"server"` source:**
- **On the server machine** (SP, host or dedicated; `isServer`):
  - writes `cba_settings_client` and `cba_settings_server` with `setVariable [..., true]`, which is a public, JIP-synced namespace object;
  - when `_store` is true, writes the server profile hash: `profileNamespace "cba_settings_hash"`, or uiNamespace if dedicated and `configFile >> "cba_settings_volatile" == 1`, followed by `saveProfileNamespace`. Values equal to the default are removed from the hash. Store is refused if the setting is in the server's userconfig file;
  - raises the global `cba_settings_refreshSetting` event. Every machine then re-resolves the setting, sets the missionNamespace variable, runs the setting script and raises `CBA_SettingChanged`.
- **On a client:**
  - only if `cba_settings_fnc_whitelisted` is true. That function reads `cba_settings_whitelist[]` from configFile and missionConfigFile (description.ext) together. If neither defines it, the list defaults to `["admin"]`, where "admin" means `IS_ADMIN_LOGGED` = `serverCommandAvailable "#shutdown"`: logged-in admins only, not voted ones. Otherwise the player's UID must be in the list;
  - it then sends `["cba_settings_setSettingServer", [setting, value, priority, store]] call CBA_fnc_serverEvent`. The server handler does not check permissions again. If not whitelisted: a warning and `false`.

**`"mission"` source:**
- Only persistent inside Eden: `_store` requires `is3DEN`. It writes the hidden scenario attribute `"Scenario" get3DENMissionAttribute "cba_settings_hash"` (a CBA hash of lower-case setting → [value, priority]) through `set3DENMissionAttributes`. That ends up in mission.sqm once the user **saves the scenario**.
- Every machine reads it at mission start through `getMissionConfigValue "cba_settings_hash"`, so all clients agree.
- Settings that are in the mission's `cba_settings.sqf` are locked. That file is only read if the attribute `cba_settings_hasSettingsFile` is true; Eden sets it on save/export when the file exists.
- At runtime, `"mission"` without Eden only changes the local machine. The internal `cba_settings_setSettingMission` event exists but has no permission check and is not JIP-safe. Don't use it.

**`"client"` source:** profile `cba_settings_hash`. Note that on the server, client and server share that same profile hash.

**Priority resolution** (`fnc_priority.sqf` plus the `SANITIZE_PRIORITY` macro):
- Effective priorities: client ≤ 0, mission ≤ 1, server ≤ 2.
- The winner is `["client","mission","server"] select (_arr find selectMax _arr)`, so **ties go to the earlier source**.
- With `isGlobal = 1`, which our tables use, client and server values are forced to at least 1 on every source except mission. Results:
  - server value (1) beats clients;
  - mission `force` (1) ties with server (1), so **mission wins**;
  - server `force force` (2) beats everything;
  - a mission value without force (0) loses to the server.

  So: mission makers define the inventory rules, and server admins can force-override them with priority 2. Wizard defaults: mission → priority 1; server → 1, or 2 with an "override mission" checkbox.
- `isGlobal = 2` means local-only. `needRestart` (the 8th parameter) only shows an icon; the value still changes live, so the setting script must cope with mid-mission changes (re-parse, re-validate layouts).

**Wizard in "direct mode"** (pause menu, keybind, Eden menu, inventory header):

```sqf
private _source = ["server", "mission"] select is3DEN;
private _prio = [[1, 2] select _overrideMission, 1] select is3DEN;
{ _x params ["_setting", "_value"]; [_setting, _value, _prio, _source, true] call CBA_settings_fnc_set } forEach _changes;
// remote admin: returns true immediately, the real change arrives via CBA_SettingChanged
```

**How settings are saved, overall:**
- client and server: the profile `cba_settings_hash` (server: the `-profiles` `.vars` file);
- mission: mission.sqm attribute, or the mission's `cba_settings.sqf` (locked);
- server or user config file: `userconfig\cba_settings.sqf` (needs `-filePatching`) or an addon with CfgPatches `cba_settings_userconfig` and `\cba_settings_userconfig\cba_settings.sqf`. These override the profile and lock the rows;
- presets: `profileNamespace "cba_settings_presetsHash"` (name → export text), plus autosaves of the last 3 mission and last 3 server presets.

**EDITBOX size:**
- CBA has no limit; the check is only the type.
- The CBA row editbox (`Row_Editbox` → `RscEdit`, single line) sets no `maxChars`, and vanilla `RscEdit` has none either. The vanilla debug console field also has none and holds multi-KB scripts. I could not verify the engine default (BIKI returns 403 from here).
- **Risk:** CBA's row `KeyUp` writes back `ctrlText`. If the engine ever truncates a long value, a single key press in the raw row would truncate the stored table. Test in-game: `ctrlSetText` a 20 KB string on an RscEdit, then compare `count ctrlText`.
- Network: every change re-broadcasts the whole string (public namespace variable, JIP).
- Keep the tables compact by design: rules per parent class or category instead of per item, and a compact shape code. That is also what the user wants ("batches, not item by item").

## 4. Import/export strings: reuse the format, not necessarily the functions

**Export.** `[_source, _exportDefault] call cba_settings_fnc_export` (`fnc_export.sqf`):
- Despite its header saying otherwise, `_exportDefault` defaults to `true` in code.
- It covers all settings of all mods, sorted by `[category, setting]`, with lines like `// Enhanced Inventory` and `force einv_items_sizeTable = "…";`.
- The prefix is `""`, `"force "` or `"force force "` for priority 0, 1 or 2. Values are written with `str`, which doubles inner quotes.
- When the menu is open it reads pending temp values; it also works without the menu.

**Import.** `[_text, _source] call cba_settings_fnc_import` → `fnc_parse [_text, true, _source, false]`:
- it strips comments in a string-aware way, then **only writes the menu's temp namespaces** and calls `gui_refresh`;
- **outside the open Addon Options menu it does nothing**, because the temp namespaces are controls on that display.

**Parse** (`fnc_parse.sqf`) works anywhere:
- `[_text, true, _source, false] call cba_settings_fnc_parse` returns `[[setting, value, priority], …]`;
- it checks that each setting exists and passes `check`; invalid ones are logged and skipped;
- it splits statements with **`splitString ";"`, which is not string-aware**;
- the name is everything before the first `=`; the value is read with `parseSimpleArray`.

**Consequences:**
- **Our table grammar must never contain `;`.** Also avoid `"`, `'`, `//`, `/*`, `#` and `\`, because server and mission files go through `preprocessFile`. `class:WxH,…`, `:N` and `+` are fine; `=` inside a value is fine too.
- For the wizard's share string, use exactly the CBA line format restricted to our settings, e.g. `force einv_items_sizeTable = "…";` per line. That one string can be pasted into the wizard, into CBA's own Import box, into a server's `cba_settings.sqf` or into a mission's `cba_settings.sqf`. The shipped default is simply the setting's default value, and CBA's per-row "reset to default" still works.
- Wizard Import: run `fnc_parse` with validation and keep only our setting names (compare with `toLower`). Then call `cba_settings_fnc_import` in menu mode, or `CBA_settings_fnc_set` in direct mode.
- Clipboard: CBA shows "Copy to clipboard" only when `isServer` and never reads the clipboard. Its Import is a paste box (a multi-line `RscEdit`). Do the same on MP clients: a selectable edit box for Ctrl+A / Ctrl+C, and a paste box for import.
- Wizard presets: keep them in our own `profileNamespace` variable (name → line string). Putting them into `cba_settings_presetsHash` is possible, since loading an einv-only preset would import only our lines, but that touches a CBA internal.

## Fragility to know about

- The button relies on IDCs 4301, 4312, 9010 and 9021, on `lbData` being the lower-case category, and on XEH config order. Everything is null-guarded, so if CBA changes, the button silently disappears and the fallbacks still work.
- The menu-mode apply relies on `cba_settings_fnc_import`, `cba_settings_fnc_whitelisted`, the `cba_settings_*Temp` variables and the `cba_settings_serverConfig` / `cba_settings_missionConfig` namespaces. These are internal names, stable in 3.19.
- If anyone ever switches the category to a stringtable key, the category key becomes language-dependent. The code above therefore reads it from the registered setting instead of hard-coding it.

## Scratch files (repo untouched)

All under `C:\Users\Heda\AppData\Local\Temp\claude\C--Users-Heda-GitHub-Repos\dd03a67c-7561-4733-b916-702a4bb4c42b\scratchpad\`:
- `cfg\cba_settings.cpp`, `cfg\ui_f.cpp`, `cfg\cba_xeh.cpp`, `cfg\cba_main.cpp`: converted configs.
- `x_cba_xeh\`, `x_cba_ui\`, `x_cba_keybinding\`, `x_cba_main\`: unpacked PBOs.
- `tools_cbaui\pbo_one.py`, `tools_cbaui\pbo_all.py`: the extraction scripts.

The key CBA sources for this are in `scratchpad\cba_settings_src\`: `fnc_initDisplayGameOptions.sqf`, `fnc_gui_addonChanged.sqf`, `fnc_gui_searchSelect.sqf`, `fnc_set.sqf`, `fnc_whitelisted.sqf`, `fnc_priority.sqf`, `fnc_parse.sqf`, `fnc_import.sqf`, `fnc_export.sqf`, `gui.hpp` and `script_component.hpp`.

Web lookups for the engine's edit-box limit found nothing usable:
- [CT_EDIT on the BI wiki](https://community.bistudio.com/wiki/CT_EDIT) returned 403 Forbidden.
- [Arma 3 User Interface Editor](https://community.bistudio.com/wiki/Arma_3_User_Interface_Editor) did not document `maxChars`.