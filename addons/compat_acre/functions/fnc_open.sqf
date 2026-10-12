#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens ACRE2's dialog for a radio. The window steps aside first (einv_gui_fnc_stepAside) - ACRE's dialog
 * does not open over another one, as TFAR's does not - and comes back on the same containers when the
 * dialog is closed. It is the call ACRE's own item menu makes (acre_sys_gui_fnc_openRadio), which also
 * hands the voice to the unit being remote controlled.
 *
 * Arguments:
 * 0: ACRE radio id, e.g. "ACRE_PRC152_ID_1" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ACRE_PRC152_ID_1"] call einv_compat_acre_fnc_open;
 *
 * Public: No
 */

params [["_radioId", "", [""]]];

if (_radioId isEqualTo "") exitWith {};

[{
    params ["_radioId"];

    [_radioId] call acre_sys_gui_fnc_openRadio;
}, [_radioId]] call EFUNC(gui,stepAside);
