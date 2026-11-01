#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A unit's name as the window shows it: ACE's (ace_common_fnc_getName, which a body keeps after death) when ACE is loaded,
 * else the engine's - "" where the engine has none to give (a body's can come back as an error text). ACE is no requirement
 * of the mod.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Name, "" for none <STRING>
 *
 * Example:
 * [cursorObject] call aio_main_fnc_unitName;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {""};

if (!isNil QACEFUNC(common,getName)) exitWith {
    [_unit, false, true] call ACEFUNC(common,getName)
};

private _name = name _unit;

["", _name] select ((_name find "Error") < 0)
