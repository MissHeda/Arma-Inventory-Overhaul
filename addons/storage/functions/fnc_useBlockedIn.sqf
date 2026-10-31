#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * In which of the unit's containers an item class lies where it cannot be used (fnc_useState) - for the
 * words of a refusal ("Take it out of the backpack first"). [] while nothing is limited, or when the item
 * lies only where it can be used, or nowhere.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Item class <STRING>
 *
 * Return Value:
 * Any of "uniform", "vest", "backpack", in that order <ARRAY of STRING>
 *
 * Example:
 * [player, "HandGrenade"] call einv_storage_fnc_useBlockedIn;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]]];

if (isNull _unit || {_class isEqualTo ""} || {!(missionNamespace getVariable [QGVAR(useActive), false])}) exitWith {[]};

private _in = [];

{
    private _kind = _x;
    private _container = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] select _forEachIndex;

    // In its cargo, or in the unit's hidden holder for it (Strict mode).
    if (
        !isNull _container
        && {([_class, _kind] call FUNC(useState)) isEqualTo "blocked"}
        && {
            ((itemCargo _container) findIf {_x == _class}) >= 0
            || {((magazineCargo _container) findIf {_x == _class}) >= 0}
            || {(toLowerANSI _class) in ([_container] call FUNC(hiddenClasses))}
        }
    ) then {
        _in pushBack _kind;
    };
} forEach USE_KINDS;

_in
