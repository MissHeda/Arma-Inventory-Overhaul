#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes what one tile stands for (an entry of fnc_getContents) out of a container and hands it back
 * as a payload fnc_addPayload can put somewhere else - the weapon with its attachments, each magazine
 * with its own rounds, a backpack, uniform or vest with everything in it, its places and its id
 * (fnc_snapshot).
 *
 * Out with negative counts, the way ACE takes single things out of a container: addItemCargoGlobal,
 * addMagazineAmmoCargo (the very magazine, by its rounds), addWeaponCargoGlobal, addBackpackCargoGlobal
 * with -1. Only the one thing changes, and it works on a unit's uniform, vest and backpack as on any
 * crate - writing a unit's container anew did not hold in the game (2026-10-08).
 *
 * The engine picks which of a class leaves, so a weapon - and a uniform, vest or backpack the container
 * holds two or more of - goes through fnc_removeSameClass: all of the class out, this very one handed
 * on, the others back in. A magazine leaves only with the tile's rounds: one with other rounds is
 * another item.
 *
 * Whatever goes into the payload has really left: read off the cargo before and after. Anything the
 * engine did not take out is not handed on - and everything that did leave is: in the payload, or
 * among the strays when fnc_removeSameClass could not put a sibling back. Noted in the journal of the
 * phase running here the moment it left (fnc_journalNote).
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Entry <HASHMAP>
 * 2: How many of a stack, -1 for all of it <NUMBER> (default: -1)
 * 3: Details - when given, filled with [strays, the payload's journal index, the strays' journal
 *    indices]: strays are payloads that left besides it and could not go back in (fnc_removeSameClass)
 *    - they settle into the container again; the indices (-1 outside a phase) are what a consumer marks
 *    with fnc_journalNote "in". Without it strays are put back once more, and what still does not go is
 *    named in the RPT <ARRAY> (default: nil)
 *
 * Return Value:
 * Payload, [] when nothing could be taken out <ARRAY>
 *   ["weapon", weapon array]
 *   ["magazine", class, [rounds, ...]]
 *   ["backpack", class, inner snapshot]
 *   ["item", class, count, inner snapshot or []]
 *
 * Example:
 * [uniformContainer player, _entry] call einv_storage_fnc_removeEntry;
 *
 * Public: No
 */

params [
    ["_container", objNull, [objNull]],
    ["_entry", createHashMap, [createHashMap]],
    ["_count", -1, [0]],
    ["_details", nil, [[]]]
];

if (isNull _container) exitWith {[]};

private _class = _entry getOrDefault ["class", ""];
private _key = toLowerANSI _class;
private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";
private _attachments = _entry getOrDefault ["attachments", []];

if (_class isEqualTo "") exitWith {[]};

if (_count < 1) then {
    _count = _entry getOrDefault ["count", 1];
};

// How many of the class the container holds, of every kind of cargo.
private _fnc_held = {
    private _held = 0;

    {
        _x params [["_classes", [], [[]]], ["_counts", [], [[]]]];

        {
            if (toLowerANSI _x isEqualTo _key) then {_held = _held + (_counts param [_forEachIndex, 0])};
        } forEach _classes;
    } forEach [getItemCargo _container, getWeaponCargo _container, getBackpackCargo _container];

    _held + ({toLowerANSI (_x select 0) isEqualTo _key} count (magazinesAmmoCargo _container))
};

// The uniforms, vests or backpacks of the class lying here, [class, object].
private _fnc_inner = {
    (everyContainer _container) select {toLowerANSI (_x select 0) isEqualTo _key}
};

private _before = call _fnc_held;
private _payload = [];
private _note = -1;
private _noted = false;
private _strays = [];
private _strayNotes = [];

switch (true) do {
    // Weapons always, uniforms, vests and backpacks held twice or more: we decide which one leaves.
    case (
        _attachments isNotEqualTo []
        || {_kind in ["rifle", "handgun", "launcher", "binocular"]}
        || {_kind in ["uniform", "vest", "backpack"] && {count (call _fnc_inner) >= 2}}
    ): {
        ([_container, _class, [_entry]] call FUNC(removeSameClass)) params [
            ["_payloads", [], [[]]], ["_left", [], [[]]], ["_payloadNotes", [], [[]]], ["_leftNotes", [], [[]]]
        ];

        _payload = _payloads param [0, [], [[]]];
        _note = _payloadNotes param [0, -1, [0]];
        _noted = true;

        if (_left isEqualTo []) exitWith {};

        if (isNil "_details") then {
            // Nobody takes them: back in once more - what does not go is lost, and named.
            {
                private _rest = [_container, _x] call FUNC(addPayload);

                if (_rest isEqualTo []) then {
                    ["in", _leftNotes param [_forEachIndex, -1]] call FUNC(journalNote);
                } else {
                    ERROR_2("Could not put %1 back into %2 - it is lost.",_rest,typeOf _container);
                };
            } forEach _left;
        } else {
            _strays = _left;
            _strayNotes = _leftNotes;
        };
    };
    case (_kind isEqualTo "backpack"): {
        private _inner = call _fnc_inner;
        private _snapshot = if (_inner isEqualTo []) then {[]} else {[(_inner select 0) select 1, (_inner select 0) select 0] call FUNC(snapshot)};

        _container addBackpackCargoGlobal [_class, -1];

        if ((call _fnc_held) < _before) then {
            _payload = ["backpack", _class, _snapshot];
        };
    };
    case (_kind in ["magazine", "grenade"]): {
        // The tile's own rounds when it names them: a magazine with other rounds is another item.
        private _hasAmmo = "ammo" in _entry;
        private _ammo = _entry getOrDefault ["ammo", 0];
        private _fnc_rounds = {
            (magazinesAmmoCargo _container) select {toLowerANSI (_x select 0) isEqualTo _key} apply {_x select 1}
        };

        private _rounds = call _fnc_rounds;

        for "_i" from 1 to _count do {
            private _now = call _fnc_rounds;

            if (_hasAmmo && {!(_ammo in _now)}) exitWith {};
            if (_now isEqualTo []) exitWith {};

            private _take = _ammo;

            if (!_hasAmmo) then {
                _take = _now select 0;
            };

            _container addMagazineAmmoCargo [_class, -1, _take];

            if (count (call _fnc_rounds) >= count _now) exitWith {};
        };

        // What really left goes into the payload: the rounds before, less those still there.
        {
            private _index = _rounds find _x;

            if (_index >= 0) then {_rounds deleteAt _index};
        } forEach (call _fnc_rounds);

        if (_rounds isNotEqualTo []) then {
            _payload = ["magazine", _class, _rounds];
        };
    };
    default {
        private _taken = _count min _before;

        if (_taken <= 0) exitWith {};

        // A uniform or vest lying here (the only one of its class) takes what is in it along.
        private _inner = [];

        if (_kind in ["uniform", "vest"]) then {
            _inner = call _fnc_inner;
            _taken = 1;
        };

        private _snapshot = if (_inner isEqualTo []) then {[]} else {[(_inner select 0) select 1, (_inner select 0) select 0] call FUNC(snapshot)};

        _container addItemCargoGlobal [_class, -_taken];

        private _gone = (_before - (call _fnc_held)) min _taken;

        if (_gone > 0) then {
            _payload = ["item", _class, _gone, _snapshot];
        };
    };
};

if (_payload isEqualTo []) exitWith {
    ERROR_2("Could not take %1 out of %2 - nothing was moved.",_class,typeOf _container);

    if (!isNil "_details") then {
        _details append [_strays, -1, _strayNotes];
    };

    []
};

// It left: written down at once, so a script error from here on cannot lose it (fnc_phaseFinalize).
if (!_noted) then {
    _note = ["out", +_payload] call FUNC(journalNote);
};

if (!isNil "_details") then {
    _details append [_strays, _note, _strayNotes];
};

// More of the class gone than the payload holds: something else took one meanwhile. What left with
// this take is in the payload; the RPT says so.
private _expected = switch (_payload select 0) do {
    case "magazine": {count (_payload select 2)};
    case "item": {_payload select 2};
    default {1};
};
private _after = call _fnc_held;

if (!_noted && {_before - _after != _expected}) then {
    WARNING_5("Took %1x %2 out of %3, but %4 before and %5 after.",_expected,_class,typeOf _container,_before,_after);
};

_payload
