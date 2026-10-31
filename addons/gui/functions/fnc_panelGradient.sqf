#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Lays the palette's panels gradient over a panel (the theme's "panelGradient", fnc_theme): a fade, the gradient's colour at the
 * left running into nothing at the right, so the panel goes from that colour into its own. It keeps clear of the round corners -
 * a radius in from the left and right edges, where the panel's top and bottom are straight - so no square corner shows. Nothing
 * where the gradient is off.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: The panel's place [x, y, w, h] <ARRAY>
 * 3: The panel's corner radius, as a height <NUMBER>
 *
 * Return Value:
 * The fade, or controlNull <CONTROL>
 *
 * Example:
 * [_display, controlNull, _rect, UNIT * 0.45] call aio_gui_fnc_panelGradient;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", ["_radius", 0, [0]]];

private _color = (missionNamespace getVariable [QGVAR(theme), createHashMap]) getOrDefault ["panelGradient", []];

if (count _color < 3) exitWith {controlNull};

_rect params ["_left", "_top", "_width", "_height"];

private _inset = SQUARE(_radius);
private _fade = [_display, "AIO_PanelCorner", _parent, [_left + _inset, _top, (_width - _inset * 2) max 0, _height]] call FUNC(uiCreate);

_fade ctrlSetText UI_TEX(fade_strip_ca);
_fade ctrlSetTextColor ((_color select [0, 3]) + [_color param [3, 1]]);

_fade
