#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which throwables a unit may throw and which it may not, by the "Use items from ..." settings: the classes
 * of grenades, smoke shells and chemlights it carries, split into those with at least one copy where it can
 * be used (fnc_useCarried) and those that lie only in containers that are closed to them.
 *
 * A throwable the game shows as loaded in the throw muzzle is counted like the others - the throw muzzle's
 * magazine is one of the unit's own, and it lies in a container all the same.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * [classes that may be thrown, classes that may not - only blocked copies] <ARRAY of ARRAY of STRING>
 *
 * Example:
 * [player] call aio_storage_fnc_throwState;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

// The magazines the throw weapon takes, in every muzzle (hand grenades, mini grenades, smoke shells, ...):
// lower case, made once.
if (isNil QGVAR(throwClasses)) then {
    private _all = [];

    {
        _all append ((compatibleMagazines ["Throw", _x]) apply {toLowerANSI _x});
    } forEach getArray (configFile >> "CfgWeapons" >> "Throw" >> "muzzles");

    GVAR(throwClasses) = _all arrayIntersect _all;
};

private _full = ((magazinesAmmoFull _unit) select {(toLowerANSI (_x select 0)) in GVAR(throwClasses)}) apply {
    private _entry = +_x;

    // Not "loaded": useCarried takes out only entries that are not, and every throwable is a plain one.
    _entry set [2, false];

    _entry
};

private _usable = (([_unit, [[], [], _full]] call FUNC(useCarried)) select 2) apply {_x select 0};

_usable = _usable arrayIntersect _usable;

private _all = _full apply {_x select 0};
private _blocked = (_all arrayIntersect _all) select {
    private _class = _x;

    (_usable findIf {_x == _class}) < 0
};

[_usable, _blocked]
