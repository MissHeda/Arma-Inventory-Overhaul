#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a set of entries weighs together, in config mass, for the weight shown on a section's header.
 *
 * A weapon brings its attachments and loaded magazines along. A uniform, vest or backpack lying in a
 * container brings its contents too, as the engine counts them against the container's load as well.
 *
 * Arguments:
 * 0: Entries (fnc_getContents) <ARRAY of HASHMAPs>
 *
 * Return Value:
 * Mass, in tenths of a pound <NUMBER>
 *
 * Example:
 * [[uniformContainer player] call aio_storage_fnc_getContents] call aio_storage_fnc_getMass;
 *
 * Public: No
 */

params [["_entries", [], [[]]]];

private _mass = 0;

{
    private _entry = _x;

    _mass = _mass + (([_entry get "class"] call EFUNC(items,getInfo)) get "mass") * (_entry getOrDefault ["count", 1]);

    // [weapon, muzzle, rail, optic, [magazine, rounds] or [], [second magazine, rounds] or [], bipod] -
    // the weapon itself is counted above.
    {
        if (_forEachIndex > 0) then {
            private _class = "";

            if (_x isEqualType "") then {_class = _x};
            if (_x isEqualType [] && {_x isNotEqualTo []}) then {_class = _x select 0};

            if (_class isNotEqualTo "") then {
                _mass = _mass + (([_class] call EFUNC(items,getInfo)) get "mass");
            };
        };
    } forEach (_entry getOrDefault ["attachments", []]);

    private _inside = _entry getOrDefault ["container", objNull];

    if (!isNull _inside) then {
        _mass = _mass + ([[_inside] call FUNC(getContents)] call FUNC(getMass));
    };
} forEach _entries;

_mass
