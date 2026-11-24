#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Antistasi's A3A_fnc_mineSweep (an engineer clears the mines around): after each mine it deletes the nearest weapon
 * holder within 9 m, taken for the disarmed mine, and keeps only its first magazine. A pile of this mod lying there
 * (GroundWeaponHolder_Scripted, aio_storage_fnc_getGroundHolder) would go with everything in it, so it is left out of
 * that search (fnc_patched). Antistasi's own file otherwise.
 *
 * Arguments:
 * As A3A_fnc_mineSweep
 *
 * Return Value:
 * As A3A_fnc_mineSweep
 *
 * Public: No
 */

private _find = "nearestObjects [position _unit, [""WeaponHolderSimulated"", ""GroundWeaponHolder"", ""WeaponHolder""], 9]";

_this call (["mineSweep", A3A_FILE_MINESWEEP, [
    [_find, format ["((%1) select {typeOf _x isNotEqualTo ""GroundWeaponHolder_Scripted""})", _find]]
]] call FUNC(patched))
