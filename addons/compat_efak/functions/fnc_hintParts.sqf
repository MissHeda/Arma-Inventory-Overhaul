#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the hint adds for a kit, after its name, size and weight: how full it is, in that mod's own
 * measure - what its kit window shows. Nothing for a kit nobody has carried yet, nor while its contents
 * have not reached this machine.
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

[[format [
    "%1 / %2 %3",
    round ([_class] call EFAKFUNC(core,getUsedCapacity)),
    round ([_class] call EFAKFUNC(core,getCapacity)),
    localize "STR_efak_gui_MassUnit"
], "text2"]]
