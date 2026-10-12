#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes a radio the one in use - ACRE2's own call for it (acre_api_fnc_setCurrentRadio, which only takes
 * a radio the player carries). The window shows it as soon as it looks again
 * (einv_gui_fnc_requestRebuild).
 *
 * Arguments:
 * 0: ACRE radio id, e.g. "ACRE_PRC152_ID_1" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ACRE_PRC152_ID_1"] call einv_compat_acre_fnc_makeActive;
 *
 * Public: No
 */

params [["_radioId", "", [""]]];

if (_radioId isEqualTo "") exitWith {};

[_radioId] call acre_api_fnc_setCurrentRadio;

[] call EFUNC(gui,requestRebuild);
