#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Notes what a kit holds the first time this window touches it - opening it, dragging over it, packing
 * into it, taking out of it, unpacking it - for the packing-off rule (fnc_repackable). Kept until the
 * window opens anew (fnc_onWindowOpen). Not for a kit nobody has carried, nor before its contents reached this machine:
 * it would look empty.
 *
 * Arguments:
 * 0: Kit class <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["efak_IFAK_7"] call aio_compat_efak_fnc_snapshot;
 *
 * Public: No
 */

params [["_kit", "", [""]]];

private _key = toLowerANSI _kit;

if (
    _key isEqualTo ""
    || {_key in GVAR(kitStart)}
    || {!(missionNamespace getVariable [QEFAKGVAR(core,contentsSynced), true])}
    || {_key in (missionNamespace getVariable [QEFAKGVAR(core,needsConversion), createHashMap])}
) exitWith {};

// Copies: a note that shares that mod's own table would change with the kit and let nothing back in.
GVAR(kitStart) set [_key, [+([_kit] call EFAKFUNC(core,getContents)), +([_kit] call EFAKFUNC(core,getCharges))]];
