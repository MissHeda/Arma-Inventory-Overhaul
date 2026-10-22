#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes a tile of the panel out of the open uniform, vest or backpack - let go outside the panel, the drop key
 * over it, or "Remove" in its menu - and ACE's list follows. A whole tile's record goes first (left in, the
 * tiles after it would take the record before theirs), then exactly the count asked for leaves through the
 * storage (einv_storage_fnc_removeEntry: a magazine by its rounds, a weapon with its parts, a container with
 * what is in it); of part of a stack the tile's record loses that many (einv_storage_fnc_setCount), so the
 * stack that was chosen is the one that shrinks. ACE hears of it as of its own removals (fnc_tellAce),
 * which keeps its counts, load bar and greyed rows right.
 *
 * A tile of the staging space (fnc_staging) goes the same way and is gone; ACE is not told, as nothing of
 * the soldier's changed - only the panel is built again. Nor is it told in Enhanced First Aid Kits' kits tab, where no
 * container's tab is open (fnc_selected). A kit of that mod taken out gives its instance back to that mod's pool,
 * as ACE's own "-" does (einv_compat_efak_fnc_arsenalFree).
 *
 * A tile of the kit's grid (the kits tab, fnc_layout) is taken out of the kit and away
 * (einv_compat_efak_fnc_discard: the kit must let things out in the arsenal).
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

// A tile of the kit's grid in the panel (the kits tab): taken out of the kit (einv_compat_efak_fnc_discard).
private _kit = _grid getOrDefault ["kit", ""];

if (_kit isNotEqualTo "") exitWith {
    private _kitClass = _entry getOrDefault ["class", ""];

    if (
        isNil QEFUNC(compat_efak,discard) || {count _entry == 0} || {_kitClass isEqualTo ""} || {_entry getOrDefault ["pending", false]}
        || {_expected isNotEqualTo "" && {_kitClass != _expected}}
    ) then {
        false
    } else {
        ([_kit, _entry, _count, _grid getOrDefault ["root", objNull]] call EFUNC(compat_efak,discard)) params ["_taken", "_why"];

        if (_taken < 1) then {
            [[_why, "Failed"] select (_why isEqualTo "")] call EFUNC(gui,flashHint);
            false
        } else {
            ["giveBack", _kitClass, objNull, false] call EFUNC(gui,playSound);
            [] call FUNC(settle);
            true
        }
    }
};

// Apart from ACE's list: the staging space or another worn container, whose removal ACE is not told of.
private _worn = [uniformContainer _center, vestContainer _center, backpackContainer _center];
private _staged = !isNull _container && {_container isNotEqualTo _open};

if (
    count _entry == 0 || {isNull _container} || {_staged && {_container isNotEqualTo GVAR(staging)} && {!(_container in _worn)}} || {!local _center}
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

// A kit taken away for good: its instance back to that mod's pool, unless one of its class still lies here.
if (!isNil QEFUNC(compat_efak,arsenalFree)) then {
    [[_class], _worn + [GVAR(staging)]] call EFUNC(compat_efak,arsenalFree);
};

if (_staged) exitWith {
    [] call FUNC(settle);
    true
};

[_class, _before, [_container, _class] call EFUNC(storage,countClass)] call FUNC(tellAce);

true
