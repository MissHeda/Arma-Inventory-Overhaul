#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the hint adds for a kit, after its name, size and weight: how full it is, as its kit window shows
 * it (fnc_fillState) - in that mod's own measure, or in cells for a kit a rule or its config gives a
 * grid. Nothing for a kit nobody has carried yet, nor while its contents have not reached this machine.
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * Parts [[text, theme colour key], ...] <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7"] call einv_compat_efak_fnc_hintParts;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (
    !([_class] call FUNC(isKit))
    || {toLowerANSI _class in (missionNamespace getVariable [QEFAKGVAR(core,needsConversion), createHashMap])}
    || {!(missionNamespace getVariable [QEFAKGVAR(core,contentsSynced), true])}
) exitWith {[]};

[[([_class] call FUNC(fillState)) select 0, "text2"]]
