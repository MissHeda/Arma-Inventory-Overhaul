#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Creates an item's picture in its own colours, fitted into its box without stretching and always
 * upright - turned pictures came out squashed in the phase 1 test. A path that cannot be shown - a
 * placeholder word in a mod's config, a file that is not there - draws nothing (fnc_safePicture): the
 * engine would pop up a message over the window for it.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Texture - the item's picture <STRING>
 * 4: Colour it is multiplied with, to fade it <ARRAY> (default: [1, 1, 1, 1])
 *
 * Return Value:
 * The picture <CONTROL>
 *
 * Example:
 * [_display, _group, [0, 0, 0.1, 0.05], getText (configFile >> "CfgWeapons" >> "arifle_MX_F" >> "picture")] call einv_gui_fnc_uiPicture;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_texture", ["_color", [1, 1, 1, 1]]];

private _ctrl = [_display, "EINV_Picture", _parent, _rect] call FUNC(uiCreate);
_ctrl ctrlSetText ([_texture] call FUNC(safePicture));
_ctrl ctrlSetTextColor _color;

_ctrl
