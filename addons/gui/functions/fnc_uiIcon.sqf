#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Creates an icon: a white texture tinted with a colour, fitted into its box without stretching - it
 * keeps its own shape whatever box it is given.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Texture <STRING>
 * 4: Colour, [] for the class's own <ARRAY> (default: [])
 *
 * Return Value:
 * The icon <CONTROL>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.1, 0.02, 0.03], "\z\einv\addons\gui\ui\icon_close_ca.paa", [1, 1, 1, 1]] call einv_gui_fnc_uiIcon;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_texture", ["_color", []]];

private _ctrl = [_display, "EINV_Icon", _parent, _rect] call FUNC(uiCreate);
_ctrl ctrlSetText _texture;

if (_color isNotEqualTo []) then {
    _ctrl ctrlSetTextColor _color;
};

_ctrl
