#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A unit's backpack, vest and uniform - Antistasi's order for using a magazine item (fnc_useMagazineItem) - with
 * those a "Use items from ..." setting closes to the class put last (aio_storage_fnc_useState "blocked"). Without
 * limits the order stays as it is. Containers the unit does not have stay in as null, as Antistasi's list has them.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Class <STRING>
 *
 * Return Value:
 * [container, ...] <ARRAY>
 *
 * Example:
 * [player, "A3U_lockpick"] call aio_compat_antistasi_fnc_useOrder;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]]];

private _open = [];
private _closed = [];

{
    _x params ["_container", "_kind"];

    if (([_class, _kind] call EFUNC(storage,useState)) isEqualTo "blocked") then {
        _closed pushBack _container;
    } else {
        _open pushBack _container;
    };
} forEach [[backpackContainer _unit, "backpack"], [vestContainer _unit, "vest"], [uniformContainer _unit, "uniform"]];

_open + _closed
