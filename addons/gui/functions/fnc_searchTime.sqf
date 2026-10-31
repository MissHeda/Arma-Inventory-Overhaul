#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many seconds one cell of a container takes to search: the server's time per cell (einv_gui_searchTime) times the
 * factor of its kind (fnc_searchKind; einv_gui_searchTimeUniform, Vest, Backpack, Crate, Vehicle, Ground), and for what a
 * body carries times the body's factor as well (einv_gui_searchTimeBody). 0 - the time or a factor at 0 - means that kind
 * is not searched at all (fnc_isSearched). An item takes its cells' time, the seal SEAL_CELLS cells (fnc_animateSearch).
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Seconds per cell <NUMBER>
 *
 * Example:
 * [cursorObject] call einv_gui_fnc_searchTime;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

private _base = GVAR(searchTime);

if (isNull _container || {_base <= 0}) exitWith {0};

([_container] call FUNC(searchKind)) params ["_kind", "_body"];

private _factor = switch (_kind) do {
    case "uniform": {GVAR(searchTimeUniform)};
    case "vest": {GVAR(searchTimeVest)};
    case "backpack": {GVAR(searchTimeBackpack)};
    case "ground": {GVAR(searchTimeGround)};
    case "vehicle": {GVAR(searchTimeVehicle)};
    default {GVAR(searchTimeCrate)};
};

if (_body) then {
    _factor = _factor * GVAR(searchTimeBody);
};

(_base * _factor) max 0
