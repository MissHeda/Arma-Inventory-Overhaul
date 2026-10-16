#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes a tile of the panel out of the open uniform, vest or backpack - let go outside the panel, Delete
 * over it, or "Remove" in its menu - and ACE's list follows. A whole tile's record goes first (left in, the
 * tiles after it would take the record before theirs), then exactly the count asked for leaves through the
 * storage (einv_storage_fnc_removeEntry: a magazine by its rounds, a weapon with its parts, a container with
 * what is in it); of part of a stack the tile's record loses that many (einv_storage_fnc_setCount), so the
 * stack that was chosen is the one that shrinks. ACE hears of it as of its own removals (fnc_tellAce),
 * which keeps its counts, load bar and greyed rows right.
 *
 * A tile of the staging space (fnc_staging) goes the same way and is gone; ACE is not told, as nothing of
 * the soldier's changed - only the panel is built again.
 *
 * Only on ACE's own unit where it is local, as ACE's own buttons work; never for a tile still on its way
 * somewhere.
 *
 * Arguments:
 * 0: The tile, [grid index, tile index] <ARRAY>
 * 1: How many of a stack, -1 for all <NUMBER> (default: -1)
 * 2: Class the tile must still be - for a menu choice run a frame after it was opened <STRING> (default: "")
 *
 * Return Value:
 * Taken out <BOOL>
 *
 * Example:
 * [[0, 3], -1] call einv_arsenal_fnc_remove;
 *
 * Public: No
 */

params [["_source", [], [[]]], ["_count", -1, [0]], ["_expected", "", [""]]];

_source params [["_gridIndex", -1], ["_tileIndex", -1]];

if (!(_gridIndex isEqualType 0) || {!(_tileIndex isEqualType 0)}) exitWith {false};

private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_gridIndex, createHashMap];
private _entry = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _container = _grid getOrDefault ["container", objNull];
private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

(call FUNC(selected)) params ["", "_open"];

private _staged = !isNull _container && {_container isEqualTo GVAR(staging)};

if (
    count _entry == 0 || {isNull _container} || {_container isNotEqualTo _open && {!_staged}} || {!local _center}
    || {_entry getOrDefault ["pending", false]}
) exitWith {false};

private _class = _entry getOrDefault ["class", ""];

if (_class isEqualTo "" || {_expected isNotEqualTo "" && {_class != _expected}}) exitWith {false};

private _whole = _count < 1 || {_count >= (_entry getOrDefault ["count", 1])};
private _before = [_container, _class] call EFUNC(storage,countClass);

if (_whole) then {
    [_container, _entry, []] call EFUNC(storage,setPlace);
};

private _payload = [_container, _entry, [_count, -1] select _whole] call EFUNC(storage,removeEntry);

if (_payload isEqualTo []) exitWith {
    ["Failed"] call EFUNC(gui,flashHint);
    false
};

// Of part of a stack, this tile gives the items: its record's count goes down by as many, so a stack that
// lies apart from others of its class is the one that shrinks (einv_storage_fnc_setCount).
if (!_whole) then {
    [_container, _entry, (_entry getOrDefault ["count", 1]) - _count] call EFUNC(storage,setCount);
};

["giveBack", _class, objNull, false] call EFUNC(gui,playSound);

if (_staged) exitWith {
    [] call FUNC(settle);
    true
};

[_class, _before, [_container, _class] call EFUNC(storage,countClass)] call FUNC(tellAce);

true
