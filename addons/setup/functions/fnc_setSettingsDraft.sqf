#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes a text of server settings the draft: read by the settings registry (einv_main_fnc_parseSettings),
 * written out again in its own words - the way the wizard compares and counts it - and kept as what it names,
 * setting by setting. The game is not touched: what is in use changes only with Save.
 *
 * Arguments:
 * 0: Text of the server settings <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["einv1, gui_searchTime=0.8"] call einv_setup_fnc_setSettingsDraft;
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _values = ([_text] call EFUNC(main,parseSettings)) select 0;
private _canonical = [_values] call EFUNC(main,writeSettings);

GVAR(draftSettings) = ([_canonical] call EFUNC(main,parseSettings)) select 0;
GVAR(draftSettingsText) = _canonical;
