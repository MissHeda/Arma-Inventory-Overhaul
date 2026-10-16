#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Moves the unit's selected throwable off one that may not be thrown (fnc_throwState): to the next one
 * that may, in the order the game cycles them (throwables). Nothing happens when the selected one may be
 * thrown, or none is selected.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Classes that may be thrown <ARRAY of STRING>
 * 2: Classes that may not <ARRAY of STRING>
 *
 * Return Value:
 * Whether the selection was moved <BOOL>
 *
 * Example:
 * [player, ["HandGrenade"], ["SmokeShell"]] call einv_storage_fnc_throwSelect;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_usable", [], [[]]], ["_blocked", [], [[]]]];

private _selected = (currentThrowable _unit) param [0, ""];

if (_selected isEqualTo "" || {_usable isEqualTo []} || {(_blocked findIf {_x == _selected}) < 0}) exitWith {false};

// The next one after the selected in the game's own order that may be thrown.
private _order = (throwables _unit) apply {_x select 0};

_order = _order arrayIntersect _order;

private _at = _order findIf {_x == _selected};
private _next = _usable select 0;

for "_i" from 1 to (count _order) do {
    private _class = _order select ((_at + _i) mod (count _order));

    if ((_usable findIf {_x == _class}) >= 0) exitWith {
        _next = _class;
    };
};

_unit selectThrowable _next;

true
