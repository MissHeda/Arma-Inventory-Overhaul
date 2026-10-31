#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Writes a tip onto the colour popover's hint line (fnc_openPaletteMenu): grey words, as many lines as the line has room for.
 *
 * Arguments:
 * 0: The hint line <CONTROL>
 * 1: Tip <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_line, "Turns the item you are dragging"] call einv_gui_fnc_setMenuHint;
 *
 * Public: No
 */

params [["_line", controlNull, [controlNull]], ["_tip", "", [""]]];

if (isNull _line) exitWith {};

private _size = _line getVariable [QGVAR(hintSize), UNIT * 0.45];

_line ctrlSetStructuredText (text _tip setAttributes ["size", str (_size / (UNIT * 0.7)), "color", "#C7C7C7", "align", "left"]);
