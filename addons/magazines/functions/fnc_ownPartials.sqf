#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Every partly filled magazine of a class in the player's own uniform, vest and backpack, as the parts a
 * repack works on: the window's top-level grids of those three containers (not a body's gear, the
 * overflow row, a kit's window or a container opened from inside them), one part per magazine - a pile of
 * several gives one for each - ascending by rounds, alike ones in window order.
 *
 * A part is [container, cell [col, row, compartment, w, h], rounds, how many magazines its tile stands
 * for, root].
 *
 * Arguments:
 * 0: Magazine class <STRING>
 *
 * Return Value:
 * Parts, ascending by rounds <ARRAY>
 *
 * Example:
 * ["30Rnd_65x39_caseless_mag"] call einv_magazines_fnc_ownPartials;
 *
 * Public: No
 */

params [["_class", "", [""]]];

private _unit = EGVAR(gui,unit);
private _own = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] - [objNull];
private _key = toLowerANSI _class;
private _capacity = ([_class] call EFUNC(items,getInfo)) getOrDefault ["capacity", 0];
private _found = [];

{
    private _grid = _x;
    private _gridIndex = _forEachIndex;

    if (
        (_grid getOrDefault ["container", objNull]) in _own
        && {!(_grid getOrDefault ["virtual", true])}
        && {!(_grid getOrDefault ["overflow", false])}
        && {(_grid getOrDefault ["kit", ""]) isEqualTo ""}
    ) then {
        {
            private _ammo = _x getOrDefault ["ammo", 0];

            if (
                toLowerANSI (_x getOrDefault ["class", ""]) isEqualTo _key && {_ammo > 0} && {_ammo < _capacity}
                && {!(_x getOrDefault ["hidden", false])} && {!(_x getOrDefault ["pending", false])}
            ) then {
                private _part = [
                    _grid get "container",
                    [_x get "col", _x get "row", _x getOrDefault ["block", 0], _x get "w", _x get "h"],
                    _ammo,
                    _x getOrDefault ["count", 1],
                    _unit
                ];

                // Rounds first, then where it lies; the running number keeps sort away from the arrays.
                for "_i" from 1 to (_x getOrDefault ["count", 1]) do {
                    _found pushBack [_ammo, _gridIndex, _x get "row", _x get "col", count _found, _part];
                };
            };
        } forEach (_grid getOrDefault ["tiles", []]);
    };
} forEach (uiNamespace getVariable [QEGVAR(gui,grids), []]);

_found sort true;

_found apply {_x select 5}
