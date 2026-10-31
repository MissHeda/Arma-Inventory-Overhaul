#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * With packing into a kit switched off (its type's setting), what may still go back: what came out of
 * it since this window first touched it (fnc_snapshot) - a wrong click is not final until the window
 * closes, as in Enhanced First Aid Kits' own kit window. Counted as the tile stands for it: an opened
 * magazine by its fill, a full one among the full ones, anything else by its class.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Item class <STRING>
 * 2: The tile's rounds - a magazine's <NUMBER> (default: 0)
 *
 * Return Value:
 * How many may go back <NUMBER>
 *
 * Example:
 * ["efak_IFAK_7", "ACE_painkillers", 7] call aio_compat_efak_fnc_repackable;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_class", "", [""]], ["_ammo", 0, [0]]];

private _start = GVAR(kitStart) getOrDefault [toLowerANSI _kit, [[], []]];
private _size = [_class] call EFAKFUNC(core,getMagazineSize);
private _opened = _size > 1 && {_ammo > 0} && {_ammo < _size};

// How many of what the tile stands for a kit holds, [contents, opened magazines].
private _fnc_count = {
    params ["_contents", "_charges"];

    private _total = [_contents, _class] call EFAKFUNC(core,countItem);

    if (_size <= 1) exitWith {_total};

    private _rounds = (_charges select {(_x select 0) == _class}) apply {_x select 1};

    if (_opened) exitWith {{_x == _ammo} count _rounds};

    _total - count _rounds
};

((_start call _fnc_count) - ([[_kit] call EFAKFUNC(core,getContents), [_kit] call EFAKFUNC(core,getCharges)] call _fnc_count)) max 0
