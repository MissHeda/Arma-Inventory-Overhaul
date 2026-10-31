#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts a payload (fnc_removeEntry, fnc_takeOff) into a container and says what of it did not arrive,
 * counted before and after on this machine: a weapon by its class, a backpack by its class or by one
 * more backpack object there, items by their count, magazines by how many of the class came in for each
 * number of rounds. Only that rest may go anywhere else - what arrived is here, and handing it on as
 * well would make a copy.
 *
 * A uniform, vest or backpack comes with what was in it, its places and its id. The engine adds it
 * empty - or with its default contents - as a new object, found as the one container object that was
 * not there before (everyContainer before and after: the engine promises no order there, so "the last
 * of its class" could be a sibling). Exactly one new object is filled from the snapshot (fnc_restore);
 * none or several, and what it held goes loose into this container instead - never into what may be a
 * sibling - and the RPT names it.
 *
 * Strict mode: a magazine or item that the container's setting keeps out of it goes into the unit's hidden
 * holder instead of the cargo (fnc_hiddenRoute, fnc_hiddenPut) - the window shows it as the container's
 * all the same, and it always arrives whole. Raw puts it into the cargo whatever the settings say: for
 * giving the holder back (fnc_hiddenReturn, fnc_opStrict).
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Payload <ARRAY>
 * 2: Raw - into the cargo, never into the hidden holder <BOOL> (default: false)
 *
 * Return Value:
 * What did not arrive, a payload of the same kind - [] when all of it did <ARRAY>
 *
 * Example:
 * [_box, ["magazine", "30Rnd_65x39_caseless_mag", [30, 17]]] call aio_storage_fnc_addPayload;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_payload", [], [[]]], ["_raw", false, [false]]];

if (_payload isEqualTo []) exitWith {[]};

// A copy: the transaction keeps the payload in its books as well (fnc_execute, the hub).
_payload = +_payload;

if (isNull _container) exitWith {_payload};

if (
    !_raw && {(_payload select 0) in ["item", "magazine"]}
    && {[_container, _payload param [1, ""]] call FUNC(hiddenRoute)}
) exitWith {
    [_container, _payload] call FUNC(hiddenPut)
};

// How many of a class the container holds at its top level, of every kind of cargo.
private _fnc_held = {
    params ["_key"];

    private _held = 0;

    {
        _x params [["_classes", [], [[]]], ["_counts", [], [[]]]];

        {
            if (toLowerANSI _x isEqualTo _key) then {_held = _held + (_counts param [_forEachIndex, 0])};
        } forEach _classes;
    } forEach [getItemCargo _container, getWeaponCargo _container, getBackpackCargo _container];

    _held + ({toLowerANSI (_x select 0) isEqualTo _key} count (magazinesAmmoCargo _container))
};

private _fnc_objects = {
    (everyContainer _container) apply {_x select 1}
};

// The uniform, vest or backpack that just arrived gets what it held.
private _fnc_fill = {
    params ["_class", "_inner", "_before"];

    if (_inner isEqualTo []) exitWith {};

    private _new = (call _fnc_objects) - _before;

    if (count _new == 1) exitWith {
        [_new select 0, _inner, _container] call FUNC(restore);
    };

    ERROR_3("Could not tell which %1 just went into %2 (%3 new) - what it held goes in loose.",_class,typeOf _container,count _new);
    [_container, _inner, objNull, true] call FUNC(restore);
};

private _rest = [];

switch (_payload select 0) do {
    case "weapon": {
        private _weapon = [_payload param [1, [], [[]]]] call FUNC(normalizeWeapon);
        private _key = toLowerANSI (_weapon select 0);
        private _before = [_key] call _fnc_held;

        _container addWeaponWithAttachmentsCargoGlobal [_weapon, 1];

        if (([_key] call _fnc_held) <= _before) then {
            _rest = _payload;
        };
    };
    case "magazine": {
        _payload params ["", ["_class", "", [""]], ["_rounds", [], [[]]]];

        private _key = toLowerANSI _class;
        private _left = [];

        // Magazines with the same rounds go in together: one add and one count for each number of
        // rounds. Counted by class, not by rounds - should the engine change the rounds of one, it still
        // arrived.
        private _groups = createHashMap;
        private _order = [];

        {
            if !(_x in _groups) then {
                _groups set [_x, 0];
                _order pushBack _x;
            };

            _groups set [_x, (_groups get _x) + 1];
        } forEach _rounds;

        {
            private _count = _groups get _x;
            private _before = [_key] call _fnc_held;

            _container addMagazineAmmoCargo [_class, _count, _x];

            private _arrived = ((([_key] call _fnc_held) - _before) max 0) min _count;

            for "_i" from 1 to (_count - _arrived) do {
                _left pushBack _x;
            };
        } forEach _order;

        if (_left isNotEqualTo []) then {
            _rest = ["magazine", _class, _left];
        };
    };
    case "backpack": {
        _payload params ["", ["_class", "", [""]], ["_inner", [], [[]]]];

        private _key = toLowerANSI _class;
        private _before = [_key] call _fnc_held;
        private _bags = everyBackpack _container;
        private _objects = [];

        if (_inner isNotEqualTo []) then {
            _objects = call _fnc_objects;
        };

        _container addBackpackCargoGlobal [_class, 1];

        // Arrived when its class counts one more - or when one more backpack object lies there: a
        // backpack the engine files under another class than the one added (a preset backpack under
        // its empty one) is there all the same, and put down a second time it would be a copy.
        private _new = (everyBackpack _container) - _bags;
        private _arrived = ([_key] call _fnc_held) > _before || {_new isNotEqualTo []};

        if (_arrived) then {
            [_class, _inner, _objects] call _fnc_fill;
        } else {
            _rest = _payload;
        };
    };
    case "item": {
        _payload params ["", ["_class", "", [""]], ["_count", 1, [0]], ["_inner", [], [[]]]];

        private _key = toLowerANSI _class;
        private _before = [_key] call _fnc_held;
        private _objects = [];

        if (_inner isNotEqualTo []) then {
            _objects = call _fnc_objects;
        };

        _container addItemCargoGlobal [_class, _count];

        private _arrived = ((([_key] call _fnc_held) - _before) max 0) min _count;

        if (_arrived > 0) then {
            [_class, _inner, _objects] call _fnc_fill;
        };

        // What it held went with the one that arrived.
        if (_arrived < _count) then {
            _rest = ["item", _class, _count - _arrived, [_inner, []] select (_arrived > 0)];
        };
    };
    default {
        ERROR_1("Cannot put %1 anywhere - it is no payload.",_payload);
        _rest = _payload;
    };
};

_rest
