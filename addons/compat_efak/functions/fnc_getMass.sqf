#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a kit really weighs, for the hint and the inspect card: its own mass, the extra weight its type
 * has empty (EFAK_emptyWeight), what it holds as that mod counts it - by default half - and what the
 * kits packed in it hold. The same that mod puts on the soldier carrying it (efak_core_fnc_updateVirtualLoad).
 * A kit nobody has carried yet holds nothing and weighs its own mass.
 *
 * Its own mass is the window's - the rules' weight= where one is set, as the weight addon puts it on
 * the soldier too.
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * Mass in tenths of a pound, -1 for anything that is no kit <NUMBER>
 *
 * Example:
 * ["efak_IFAK_7"] call aio_compat_efak_fnc_getMass;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if !([_class] call FUNC(isKit)) exitWith {-1};

private _mass = ([_class] call EFUNC(items,getInfo)) getOrDefault ["mass", 0];

// Both parts are that mod's own (Public: No) - still there in every version this was written against.
if (
    toLowerANSI _class in (missionNamespace getVariable [QEFAKGVAR(core,needsConversion), createHashMap])
    || {isNil QEFAKFUNC(core,getKitLoad)}
    || {isNil QEFAKFUNC(core,getWeightOffset)}
) exitWith {_mass};

([_class] call EFAKFUNC(core,getKitLoad)) params [["_load", 0], ["_offset", 0]];

_mass + ([_class] call EFAKFUNC(core,getWeightOffset)) + _load + _offset
