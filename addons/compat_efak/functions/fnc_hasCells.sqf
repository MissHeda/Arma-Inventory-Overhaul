#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether so many of an item still find free cells in a kit whose grid a rule or its config gives it
 * (fnc_roomMode "cells") - its room then, instead of Enhanced First Aid Kits' capacity. As in any
 * container (einv_storage_fnc_hasSpace): what it holds is laid out once more with them added, from the
 * places everyone shares; nothing is kept. They first fill the piles of their kind that are not full
 * yet - a magazine only those of its rounds -, and only what is left needs free cells, a tile per
 * stack's worth. Magazines of different rounds lie on tiles of their own.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Item class <STRING>
 * 2: How many <NUMBER> (default: 1)
 * 3: Rounds of the magazines: one number for all of them, -1 for full, or one per magazine <NUMBER or
 *    ARRAY> (default: -1)
 *
 * Return Value:
 * They all have room <BOOL>
 *
 * Example:
 * ["efak_IFAK_7", "ACE_fieldDressing", 3] call einv_compat_efak_fnc_hasCells;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_class", "", [""]], ["_count", 1, [0]], ["_rounds", -1, [0, []]]];

if (_kit isEqualTo "" || {_class isEqualTo ""}) exitWith {false};
if (_count < 1) exitWith {true};

private _info = [_class] call EFUNC(items,getInfo);
private _stack = (_info getOrDefault ["stack", 1]) max 1;
private _capacity = _info getOrDefault ["capacity", 0];

// How many of which rounds: a magazine lies with those of its fill, anything else is one kind.
private _groups = [];

if (_capacity > 0) then {
    private _list = if (_rounds isEqualType []) then {
        (_rounds select [0, _count]) apply {[_capacity, _x] select (_x isEqualType 0 && {_x >= 0})}
    } else {
        []
    };

    // Those the list does not name are as the number says - full when it says nothing.
    private _rest = [_capacity, _rounds] select (_rounds isEqualType 0 && {_rounds >= 0});

    for "_i" from (count _list) to (_count - 1) do {
        _list pushBack _rest;
    };

    {
        private _ammo = _x;
        private _index = _groups findIf {(_x select 0) == _ammo};

        if (_index < 0) then {
            _groups pushBack [_ammo, 1];
        } else {
            (_groups select _index) set [1, ((_groups select _index) select 1) + 1];
        };
    } forEach _list;
} else {
    _groups pushBack [0, _count];
};

private _entries = [_kit] call FUNC(getEntries);
private _lower = toLowerANSI _class;
private _probes = [];

{
    _x params ["_ammo", "_left"];

    private _probe = createHashMapFromArray [
        ["class", _class], ["count", 1], ["ammo", _ammo], ["capacity", _capacity], ["attachments", []], ["container", objNull]
    ];
    private _key = [_probe] call EFUNC(storage,entryKey);

    // What fits onto piles of its kind that are not full yet.
    if (_stack > 1) then {
        {
            private _had = _x getOrDefault ["count", 1];

            if (
                _had < _stack && {toLowerANSI (_x getOrDefault ["class", ""]) isEqualTo _lower}
                && {([_x] call EFUNC(storage,entryKey)) isEqualTo _key}
            ) then {
                _left = _left - (_stack - _had);
            };
        } forEach _entries;
    };

    // The rest a tile per stack's worth.
    while {_left > 0} do {
        private _tile = +_probe;

        _tile set ["count", _left min _stack];
        _probes pushBack _tile;
        _left = _left - _stack;
    };
} forEach _groups;

if (_probes isEqualTo []) exitWith {true};

["kit:" + toLowerANSI _kit, _entries + _probes, false] call EFUNC(storage,getLayout);

_probes findIf {_x getOrDefault ["overflow", true]} < 0
