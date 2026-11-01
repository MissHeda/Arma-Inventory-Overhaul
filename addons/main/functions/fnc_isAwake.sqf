#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit is alive and awake: ACE's own answer (ace_common_fnc_isAwake, its unconsciousness) when ACE is loaded, else
 * the engine's - alive and not incapacitated. ACE is no requirement of the mod.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Awake <BOOL>
 *
 * Example:
 * [player] call aio_main_fnc_isAwake;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!isNil QACEFUNC(common,isAwake)) exitWith {
    [_unit] call ACEFUNC(common,isAwake)
};

alive _unit && {lifeState _unit in ["HEALTHY", "INJURED"]}
