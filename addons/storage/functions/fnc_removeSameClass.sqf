#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes weapons, uniforms, vests or backpacks of one class out of a container so that the engine never
 * decides which one leaves: snapshots of all of the class, all out with one negative count - verified -,
 * each wanted one handed on - its exact match (the same container object, an equal tag id, an equal
 * weapon array), else the first unmatched one of the class - and the others back in from their
 * snapshots, same ids, same inside arrangement, verified by count (fnc_addPayload).
 *
 * Should not all of the class leave, what did goes back in and nothing is handed on. What does not go
 * back is handed back as strays: they have left, and settle into the container again (fnc_settle).
 * fnc_execute may hand it every take of one holder and one such class in a phase at once: one removal
 * and one re-add for the class - twenty identical rifles out costs one removal and no re-add.
 *
 * Every payload that left is noted in the journal of the phase running here the moment it left, one put
 * back marked consumed (fnc_journalNote); the ones handed on and the strays stay noted until their
 * consumer marks them - their journal indices come back with them for that.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Class <STRING>
 * 2: The entries asked for (fnc_getContents, fnc_findEntry) <ARRAY of HASHMAPs>
 *
 * Return Value:
 * [payloads - one per entry asked for, [] for one that could not be taken -, strays, the payloads'
 *  journal indices (-1 for none or outside a phase), the strays' journal indices] <ARRAY>
 *
 * Example:
 * [cursorObject, "arifle_MX_F", [_entry]] call aio_storage_fnc_removeSameClass;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_class", "", [""]], ["_wanted", [], [[]]]];

private _none = _wanted apply {[]};

private _noNotes = _wanted apply {-1};

if (isNull _container || {_class isEqualTo ""} || {_wanted isEqualTo []}) exitWith {[_none, [], _noNotes, []]};

private _key = toLowerANSI _class;
private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";
private _isWeapon = (_kind in ["rifle", "handgun", "launcher", "binocular"]) || {(_wanted findIf {(_x getOrDefault ["attachments", []]) isNotEqualTo []}) >= 0};

if (!_isWeapon && {!(_kind in ["uniform", "vest", "backpack"])}) exitWith {
    ERROR_1("%1 is no weapon, uniform, vest or backpack - nothing was moved.",_class);
    [_none, [], _noNotes, []]
};

// The id a tile's key carries for a uniform, vest or backpack (class|c<id>, fnc_entryKey).
private _fnc_uidOf = {
    params ["_entry"];

    private _entryKey = _entry getOrDefault ["key", ""];

    if (_entryKey isEqualTo "") then {
        _entryKey = [_entry] call FUNC(entryKey);
    };

    private _at = _entryKey find "|c";

    if (_at < 0) exitWith {""};

    _entryKey select [_at + 2]
};

// Every one of the class as it is now, [payload, container object or objNull, id or ""] - read before
// anything moves, so each can go back exactly as it was.
private _all = [];

if (_isWeapon) then {
    private _weapons = weaponsItemsCargo _container;

    if (isNil "_weapons") then {_weapons = []};

    {
        private _array = [_x] call FUNC(normalizeWeapon);

        if (toLowerANSI (_array select 0) isEqualTo _key) then {
            _all pushBack [["weapon", _array], objNull, ""];
        };
    } forEach _weapons;
} else {
    {
        _x params ["_itemClass", "_object"];

        if (toLowerANSI _itemClass isEqualTo _key) then {
            private _snapshot = [_object, _itemClass] call FUNC(snapshot);
            private _payload = if (_kind isEqualTo "backpack") then {
                ["backpack", _itemClass, _snapshot]
            } else {
                ["item", _itemClass, 1, _snapshot]
            };

            _all pushBack [_payload, _object, ((_snapshot select 5) select 1) param [0, ""]];
        };
    } forEach (everyContainer _container);
};

if (_all isEqualTo []) exitWith {[_none, [], _noNotes, []]};

// What is asked for, also read before anything moves: the objects go with the removal.
private _asked = _wanted apply {
    if (_isWeapon) then {
        [[_x getOrDefault ["attachments", []]] call FUNC(normalizeWeapon), objNull, ""]
    } else {
        [[], _x getOrDefault ["container", objNull], [_x] call _fnc_uidOf]
    };
};

private _count = count _all;

switch (true) do {
    case (_isWeapon): {_container addWeaponCargoGlobal [_class, -_count]};
    case (_kind isEqualTo "backpack"): {_container addBackpackCargoGlobal [_class, -_count]};
    default {_container addItemCargoGlobal [_class, -_count]};
};

// What really left: of a weapon, those before less an equal one for each still there; of a container,
// the objects that are gone.
private _gone = _all apply {true};

if (_isWeapon) then {
    private _still = weaponsItemsCargo _container;

    if (isNil "_still") then {_still = []};

    {
        private _array = [_x] call FUNC(normalizeWeapon);

        if (toLowerANSI (_array select 0) isEqualTo _key) then {
            private _index = -1;

            {
                if (_index < 0 && {_gone select _forEachIndex} && {((_x select 0) select 1) isEqualTo _array}) then {
                    _index = _forEachIndex;
                };
            } forEach _all;

            if (_index >= 0) then {
                _gone set [_index, false];
            };
        };
    } forEach _still;
} else {
    private _objects = (everyContainer _container) apply {_x select 1};

    {
        if ((_x select 1) in _objects) then {
            _gone set [_forEachIndex, false];
        };
    } forEach _all;
};

private _notes = _all apply {-1};

{
    if (_gone select _forEachIndex) then {
        _notes set [_forEachIndex, ["out", +(_x select 0)] call FUNC(journalNote)];
    };
} forEach _all;

// Back into the container, verified; what does not go back has left and is a stray.
private _strays = [];
private _strayNotes = [];

private _fnc_putBack = {
    params ["_index"];

    private _payload = (_all select _index) select 0;
    private _rest = [_container, _payload] call FUNC(addPayload);

    if (_rest isEqualTo []) then {
        ["in", _notes select _index] call FUNC(journalNote);
    } else {
        ERROR_2("Could not put %1 back into %2 - it is handed on to be put back.",_rest,typeOf _container);
        _strays pushBack _rest;
        _strayNotes pushBack (_notes select _index);
    };
};

if ((_gone findIf {!_x}) >= 0) exitWith {
    ERROR_3("Could not take all %1x %2 out of %3 - what left goes back, nothing is moved.",_count,_class,typeOf _container);

    {
        if (_x) then {[_forEachIndex] call _fnc_putBack};
    } forEach _gone;

    [_none, _strays, _noNotes, _strayNotes]
};

// Each one asked for gets its own - the same object, else the same id, else the same weapon - or the
// first one left of the class: identical items are the same item.
private _assigned = _all apply {false};
private _payloads = [];
private _payloadNotes = [];

// The first one not given away yet that passes a test, given [payload, object, id]; -1 for none.
private _fnc_first = {
    params ["_test"];

    private _found = -1;

    {
        if (_found < 0 && {!(_assigned select _forEachIndex)} && {_x call _test}) then {
            _found = _forEachIndex;
        };
    } forEach _all;

    _found
};

{
    _x params ["_array", "_object", "_uid"];

    private _index = -1;

    if (_isWeapon) then {
        _index = [{((_this select 0) select 1) isEqualTo _array}] call _fnc_first;
    } else {
        if (!isNull _object) then {
            _index = [{(_this select 1) isEqualTo _object}] call _fnc_first;
        };

        if (_index < 0 && {_uid isNotEqualTo ""}) then {
            _index = [{(_this select 2) isEqualTo _uid}] call _fnc_first;
        };
    };

    if (_index < 0) then {
        _index = _assigned find false;
    };

    if (_index < 0) then {
        _payloads pushBack [];
        _payloadNotes pushBack -1;
    } else {
        _assigned set [_index, true];
        _payloads pushBack +((_all select _index) select 0);
        _payloadNotes pushBack (_notes select _index);
    };
} forEach _asked;

{
    if (!_x) then {[_forEachIndex] call _fnc_putBack};
} forEach _assigned;

[_payloads, _strays, _payloadNotes, _strayNotes]
