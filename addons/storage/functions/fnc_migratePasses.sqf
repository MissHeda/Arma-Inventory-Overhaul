#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which container's surplus may go to which, for a unit's worn containers in the order uniform, vest,
 * backpack (those it has): each container to the ones after it - the order of preference -, and, when
 * asked for, then to the ones before it. The surplus pass of every unit goes on only (fnc_opMigrate,
 * fnc_requestMigrate); the player's overflow sweep goes both ways (fnc_requestSweep) before anything is
 * put on the ground, since a cell anywhere is better than none.
 *
 * Arguments:
 * 0: How many containers the unit has <NUMBER>
 * 1: Both ways - after the passes on, the passes back <BOOL> (default: false)
 *
 * Return Value:
 * Passes in the order they run, [from index, [target indices in the order they are tried]] each <ARRAY>
 *
 * Example:
 * [3, true] call aio_storage_fnc_migratePasses;
 *
 * Public: No
 */

params [["_count", 0, [0]], ["_wide", false, [false]]];

private _indices = [];

for "_k" from 0 to (_count - 1) do {
    _indices pushBack _k;
};

private _passes = [];

// On: the uniform to the vest and backpack, the vest to the backpack.
for "_i" from 0 to (_count - 2) do {
    _passes pushBack [_i, _indices select [_i + 1]];
};

// Back: what still fits nowhere after them, from the vest to the uniform, from the backpack to the uniform and vest.
if (_wide) then {
    for "_i" from 1 to (_count - 1) do {
        _passes pushBack [_i, _indices select [0, _i]];
    };
};

_passes
