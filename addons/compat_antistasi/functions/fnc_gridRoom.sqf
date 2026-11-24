#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many of a class the grid has room for where Antistasi's traders and the Bazaar put a purchase: a unit (its
 * uniform, vest and backpack together) or one of a unit's worn containers - as aio_storage_fnc_addFit finds the cells,
 * free cells the only limit. Anything else - a crate, a vehicle, a pile - is left to the engine's load (-1): what does
 * not fit its grid there stays in it, shown apart, and nothing is lost.
 *
 * Arguments:
 * 0: A unit or a container <OBJECT>
 * 1: Class <STRING>
 * 2: At most this many are asked about <NUMBER> (default: 1)
 *
 * Return Value:
 * How many fit, -1 for no grid limit here <NUMBER>
 *
 * Example:
 * [player, "FirstAidKit", 5] call aio_compat_antistasi_fnc_gridRoom;
 *
 * Public: No
 */

params [["_target", objNull, [objNull]], ["_class", "", [""]], ["_most", 1, [0]]];

if (isNull _target || {_class isEqualTo ""}) exitWith {-1};

_most = 1 max floor _most;

if (_target isKindOf "CAManBase") exitWith {
    private _fit = 0;

    {
        _fit = _fit + (_x select 1);
    } forEach ([_target, _class, _most] call EFUNC(storage,addFit));

    _fit
};

// One of a unit's worn containers: what lands in it.
private _unit = [_target] call EFUNC(storage,rootOf);

if (isNull _unit || {!(_unit isKindOf "CAManBase")} || {!(_target in [uniformContainer _unit, vestContainer _unit, backpackContainer _unit])}) exitWith {-1};

private _fit = 0;

{
    if ((_x select 0) isEqualTo _target) then {
        _fit = _fit + (_x select 1);
    };
} forEach ([_unit, _class, _most] call EFUNC(storage,addFit));

_fit
