#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes a text into the footer's hint in one of the theme's colours - how it went, rather than why
 * something did not (fnc_flashHint, which stays the loss-coloured reason). The next time the mouse lands
 * on something else, the hint names that instead (fnc_updateHover).
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
 * ["Loaded Rifleman"] call einv_gui_fnc_showHint;
 *
 * Public: No
 */

disableSerialization;

params [["_text", "", [""]], ["_colorKey", "text2", [""]]];

private _hint = uiNamespace getVariable [QGVAR(hint), controlNull];

if (isNull _hint || {_text isEqualTo ""}) exitWith {};

private _color = GVAR(theme) getOrDefault [_colorKey, [0.639, 0.675, 0.725, 1]];
private _hex = "#" + ((_color select [0, 3]) apply {
    private _value = round ((_x max 0 min 1) * 255);
    ("0123456789ABCDEF" select [floor (_value / 16), 1]) + ("0123456789ABCDEF" select [_value mod 16, 1])
} joinString "");

_hint ctrlSetStructuredText (text _text setAttributes ["color", _hex]);
