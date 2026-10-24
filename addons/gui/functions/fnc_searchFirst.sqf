#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A click on a hidden item: it is searched next in its box, before everything that lies ahead of it - the item
 * the box was at starts again from nothing later. Remembered in the box's search record ("first"), so the order
 * holds when the window is built again (fnc_sortSearch). A box that waits for its Search button or was stopped
 * starts searching with the click.
 *
 * Arguments:
 * 0: The tile's grid <HASHMAP>
 * 1: The hidden tile <HASHMAP>
 *
 * Return Value:
 * Queued first <BOOL>
 *
 * Example:
 * [_grid, _tile] call einv_gui_fnc_searchFirst;
 *
 * Public: No
 */

params [["_grid", createHashMap, [createHashMap]], ["_tile", createHashMap, [createHashMap]]];

private _container = _grid getOrDefault ["container", objNull];

if (isNull _container) exitWith {false};

// [class, row, column, compartment], as the queue has it (fnc_markHidden).
private _key = [
    toLowerANSI (_tile getOrDefault ["class", ""]), _tile getOrDefault ["row", 0], _tile getOrDefault ["col", 0], _tile getOrDefault ["block", 0]
];

if ((GVAR(searchQueue) findIf {
    (_x select 0) isEqualTo _container && {[_x select 1, _x select 2, _x select 3, _x param [5, 0]] isEqualTo _key}
}) < 0) exitWith {false};

([_container, true] call FUNC(searchRecord)) set ["first", _key];

GVAR(searchPaused) = GVAR(searchPaused) - [_container];
GVAR(searchIdle) = GVAR(searchIdle) - [_container];

call FUNC(sortSearch);

// The box's run takes the new first entry in the next frame (fnc_animateSearch).
GVAR(searchDirty) = true;

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (!isNull _display) then {
    [_display] call FUNC(updateStatus);
};

true
