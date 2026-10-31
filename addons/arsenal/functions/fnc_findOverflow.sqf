#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What lies on no cell of a unit's uniform, vest or backpack - the entries the inventory window would show
 * apart, in red (fnc_checkOverflow says only which container has some). Laid out the way the window would,
 * without keeping that layout - and everything that lies in the staging space (fnc_staging), which goes when
 * the window closes (the question of fnc_confirmClose names both).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * One [container, entry] per entry with no room or in the staging space, an entry as fnc_getContents makes it <ARRAY>
 *
 * Example:
 * [player] call einv_arsenal_fnc_findOverflow;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _found = [];

// fnc_getSections also marks each container with its unit, which its compartments depend on.
{
    private _container = _x get "container";
    private _layout = [_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout);

    {
        _found pushBack [_container, _x];
    } forEach (_layout getOrDefault ["overflow", []]);
} forEach ([_unit] call EFUNC(storage,getSections));

// What lies in the staging space is gone with the window as well.
private _staging = GVAR(staging);

if (!isNull _staging) then {
    {
        _found pushBack [_staging, _x];
    } forEach ([_staging] call EFUNC(storage,getContents));
};

_found
