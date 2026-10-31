#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What this player knows of a container he searches: a HashMap with "known" (class in lower case -> how many entries of
 * it he knows, fnc_markHidden, fnc_learn) and "unsealed" (true once he has opened it, fnc_isSealed, fnc_animateSearch).
 * Every player searches for himself: nothing of it is broadcast.
 *
 * Where it is kept depends on whether the container stays the object it is:
 *   a crate, a vehicle, a pile on the ground - on the object, on this machine (QGVAR(searchRecord))
 *   a uniform, vest or backpack - the engine makes a new object every time one is moved (taken off a body, dropped,
 *     put into a crate), so it is kept in GVAR(searchMemory) by the id the container carries in its search state
 *     (aio_storage_searchState, [id, source]; aio_storage_fnc_snapshot and fnc_restore carry it to the new object,
 *     fnc_takeOff writes where it came from). The first time anything is known of one that has no id yet, this
 *     machine gives it one and broadcasts it, so every player's knowledge goes with the container from then on. Should
 *     another machine have given it another id at the same moment and its broadcast won, what this machine knew under
 *     its own (QGVAR(searchKey), on the object here) is taken over to the one that stands.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Make it, to write to it - off answers an empty one, not kept, where nothing is known yet <BOOL> (default: false)
 *
 * Return Value:
 * The record <HASHMAP>
 *
 * Example:
 * [_box, true] call aio_gui_fnc_searchRecord;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_create", false, [false]]];

if (isNull _container) exitWith {createHashMap};

private _state = _container getVariable [QEGVAR(storage,searchState), []];
private _id = _state param [0, "", [""]];

// A crate, a vehicle, a pile: its record lies on it.
if (_id isEqualTo "" && {!(_container isKindOf "Bag_Base")} && {!(_container isKindOf "ContainerSupply")}) exitWith {
    private _own = _container getVariable QGVAR(searchRecord);

    if (isNil "_own") then {
        _own = createHashMap;

        if (_create) then {
            _container setVariable [QGVAR(searchRecord), _own];
        };
    };

    _own
};

// A uniform, vest or backpack nothing is known of yet gets its id now - public, with where it came from kept as it was.
if (_id isEqualTo "" && {_create}) then {
    _id = format ["%1:%2:%3", clientOwner, round (diag_tickTime * 1000), round random 1e6];
    _container setVariable [QEGVAR(storage,searchState), [_id, _state param [1, "", [""]]], true];
};

if (_id isEqualTo "") exitWith {createHashMap};

// The id this machine kept its knowledge under lost to another one: taken over, the larger count and the seal open.
private _mine = _container getVariable [QGVAR(searchKey), ""];

if (_mine isNotEqualTo _id) then {
    if (_mine isNotEqualTo "" && {_mine in GVAR(searchMemory)}) then {
        private _old = GVAR(searchMemory) deleteAt _mine;
        private _into = GVAR(searchMemory) getOrDefault [_id, createHashMap];
        private _known = _into getOrDefault ["known", createHashMap];

        {
            _known set [_x, (_known getOrDefault [_x, 0]) max _y];
        } forEach (_old getOrDefault ["known", createHashMap]);

        _into set ["known", _known];
        _into set ["unsealed", (_into getOrDefault ["unsealed", false]) || {_old getOrDefault ["unsealed", false]}];
        GVAR(searchMemory) set [_id, _into];
    };

    _container setVariable [QGVAR(searchKey), _id];
};

private _record = GVAR(searchMemory) get _id;

if (isNil "_record") then {
    _record = createHashMap;

    if (_create) then {
        GVAR(searchMemory) set [_id, _record];
    };
};

_record
