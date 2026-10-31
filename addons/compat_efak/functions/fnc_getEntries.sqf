#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a kit holds, as the window's entries - the same keys aio_storage_fnc_getContents gives, so the
 * tiles, their layout, dragging and counting work as in any container. Piled by the window's rules
 * (aio_items_fnc_getInfo "stack"), not by that mod's rows: a magazine of several rounds lies full with
 * the full ones and opened with those of the same fill, as their rounds are kept in the kit
 * (efak_core_fnc_getCharges); one of a single round - a grenade - carries that round, as cargo shows it.
 *
 * Laid out, they lie where the kit's places say (aio_storage_fnc_getLayout on "kit:" + the lowercase
 * class), each with its key, compartment, cell and size - the kit ops find a tile and a free cell that
 * way, on the machine that runs them, as every window draws the kit.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Laid out <BOOL> (default: false)
 *
 * Return Value:
 * Entries, in the order the kit lists its contents <ARRAY of HASHMAPs>
 *
 * Example:
 * ["efak_IFAK_7"] call aio_compat_efak_fnc_getEntries;
 * ["efak_IFAK_7", true] call aio_compat_efak_fnc_getEntries;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_laidOut", false, [false]]];

private _entries = [];

{
    _x params ["_class", "_count"];

    private _info = [_class] call EFUNC(items,getInfo);
    private _stack = (_info getOrDefault ["stack", 1]) max 1;
    private _size = [_class] call EFAKFUNC(core,getMagazineSize);

    // [rounds, how many] per pile.
    private _piles = [];

    if (_size > 1) then {
        // The emptiest first - never more opened ones than the kit holds of the class.
        private _opened = ([_kit, _class] call EFAKFUNC(core,getCharges)) select [0, _count];
        private _full = (_count - count _opened) max 0;

        if (_full > 0) then {
            _piles pushBack [_size, _full];
        };

        {
            private _rounds = _x;
            private _index = _piles findIf {(_x select 0) == _rounds};

            if (_index < 0) then {
                _piles pushBack [_rounds, 1];
            } else {
                private _pile = _piles select _index;
                _pile set [1, (_pile select 1) + 1];
            };
        } forEach _opened;
    } else {
        // A magazine of one round - a grenade - carries that round, as cargo shows it; an item none.
        _piles pushBack [parseNumber (isClass (configFile >> "CfgMagazines" >> _class)), _count];
    };

    {
        _x params ["_rounds", "_left"];

        while {_left > 0} do {
            _entries pushBack createHashMapFromArray [
                ["class", _class],
                ["count", _left min _stack],
                ["ammo", _rounds],
                ["capacity", _info getOrDefault ["capacity", 0]],
                ["attachments", []],
                ["container", objNull]
            ];

            _left = _left - _stack;
        };
    } forEach _piles;
} forEach ([_kit] call EFAKFUNC(core,getContents));

if (_laidOut && {_entries isNotEqualTo []}) then {
    _entries = (["kit:" + toLowerANSI _kit, _entries] call EFUNC(storage,getLayout)) getOrDefault ["entries", _entries];

    // The layout gives each tile its key; one it did not is given it here, the same way.
    {
        if !("key" in _x) then {
            _x set ["key", [_x] call EFUNC(storage,entryKey)];
        };
    } forEach _entries;
};

_entries
