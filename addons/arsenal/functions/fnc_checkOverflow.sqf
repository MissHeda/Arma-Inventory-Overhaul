#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which of a unit's uniform, vest and backpack hold something that lies nowhere on their grid - the
 * inventory window would show it apart, in red. A whole loadout comes in at once (loaded, imported,
 * a smaller vest put on), and the engine only checked its weight.
 *
 * Laid out the way the window would, without keeping that layout.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Names of the uniform, vest and backpack with too much in them, [] when everything fits <ARRAY>
 *
 * Example:
 * [player] call einv_arsenal_fnc_checkOverflow;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _names = [];

// fnc_getSections also marks each container with its unit, which its compartments depend on.
{
    private _container = _x get "container";
    private _layout = [_container, [_container] call EFUNC(storage,getContents), false] call EFUNC(storage,getLayout);

    if ((_layout get "overflow") isNotEqualTo []) then {
        _names pushBack (_x get "title");
    };
} forEach ([_unit] call EFUNC(storage,getSections));

_names
