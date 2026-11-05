#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A double click (or the quick move key) on a tile, as mods and the mission set it (fnc_quickAction asks this first). The
 * action for the item (fnc_menuRules on GVAR(doubleClickRules): CfgAioMenu, an entry with doubleClick = 1,
 * aio_gui_fnc_setDoubleClick):
 *   "move" - nothing here, the double click does what it always does
 *   "menu" - the tile's right-click menu opens
 *   other  - the row of its menu with that id, else with that name, runs as a click on it would; a greyed out
 *            row does nothing. Not in the menu now: nothing here.
 * The rows are the menu's own (fnc_contextMenu, collecting): hidden rows are not found, and what may be done
 * where is decided there, as for a right click.
 *
 * Only in the inventory, on a tile that is not under way, not inside a kit's window.
 *
 * Arguments:
 * 0: Index of the grid the tile lies on <NUMBER>
 * 1: Index of the tile <NUMBER>
 * 2: A repeat of a key held down <BOOL> (default: false)
 *
 * Return Value:
 * Done here - the double click is taken <BOOL>
 *
 * Example:
 * [2, 5] call aio_gui_fnc_doubleClickRule;
 *
 * Public: No
 */

params ["_gridIndex", "_tileIndex", ["_repeat", false, [false]]];

if !(call FUNC(isInventoryMode)) exitWith {false};

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {false};

private _grid = (uiNamespace getVariable [QGVAR(grids), []]) param [_gridIndex, createHashMap];
private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _class = _tile getOrDefault ["class", ""];

if (
    _class isEqualTo "" || {_grid getOrDefault ["virtual", true]} || {(_grid getOrDefault ["kit", ""]) isNotEqualTo ""}
    || {_tile getOrDefault ["hidden", false]} || {_tile getOrDefault ["pending", false]}
) exitWith {false};

private _action = ([missionNamespace getVariable [QGVAR(doubleClickRules), createHashMap], _class] call FUNC(menuRules)) param [0, ""];

if (_action isEqualTo "" || {toLowerANSI _action isEqualTo "move"}) exitWith {false};

// The rows of the tile's menu - for the tile under the mouse, which is the one double clicked.
private _choices = [_display, [], true] call FUNC(contextMenu);

if (
    (GVAR(hover) param [0, ""]) isNotEqualTo "tile" || {(GVAR(hover) param [1, -1]) != _gridIndex} || {(GVAR(hover) param [2, -1]) != _tileIndex}
) exitWith {false};

private _fnc_options = {
    private _options = _this param [3, createHashMap];
    [createHashMap, _options] select (_options isEqualType createHashMap)
};

if (toLowerANSI _action isEqualTo "menu") exitWith {
    if (!_repeat) then {
        [_display] call FUNC(contextMenu);
    };

    true
};

private _key = toLowerANSI _action;
private _index = _choices findIf {toLowerANSI ((_x call _fnc_options) getOrDefault ["id", ""]) isEqualTo _key};

if (_index < 0) then {
    _index = _choices findIf {toLowerANSI (_x param [0, ""]) isEqualTo _key};
};

if (_index < 0) exitWith {false};
if (_repeat) exitWith {true};

private _choice = _choices select _index;

if !((_choice call _fnc_options) getOrDefault ["enabled", true]) exitWith {true};

// As a click on the row of an open menu: where it would have opened, for an option that asks to stay open
// (fnc_cbaRun).
GVAR(menuAt) = getMousePosition;
GVAR(menuFor) = +GVAR(hover);

(_choice param [1, []]) call (_choice param [2, {}]);

true
