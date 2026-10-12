#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Creates a frame of one pixel around a box - a slot's or a tile's border.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Colour <ARRAY>
 *
 * Return Value:
 * The frame <CONTROL>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.1, 0.05, 0.05], [1, 1, 1, 0.2]] call einv_gui_fnc_uiFrame;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_color"];

private _ctrl = [_display, "EINV_Frame", _parent, _rect] call FUNC(uiCreate);
_ctrl ctrlSetText "";
_ctrl ctrlSetTextColor _color;

_ctrl
