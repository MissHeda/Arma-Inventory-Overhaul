#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Says something in the footer's hint of the open window, in one of the theme's colours: a refusal in the loss
 * colour is einv_gui_fnc_flashHint's, this is for how it went - added, given back, loaded. The next hover
 * replaces it.
 *
 * Arguments:
 * 0: Text <STRING>
 * 1: The theme's colour to write it in - "text", "text2", "muted", "accent", "gain", "loss" <STRING>
 *    (default: "text2")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Loaded Rifleman"] call einv_arsenal_fnc_message;
 *
 * Public: No
 */

params [["_text", "", [""]], ["_colorKey", "text2", [""]]];

[_text, _colorKey] call EFUNC(gui,showHint);
