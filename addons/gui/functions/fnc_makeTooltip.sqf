#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Makes the name at the mouse: a centred label on its tooltip glass, on the display and hidden, which
 * fnc_updateHover fills and shows and fnc_onFrame keeps beside the pointer. Made after every build
 * (fnc_drawTopLayer) and again whenever it has to lie over something made after it (fnc_raiseTooltip).
 * It is not kept anywhere here: the caller says where (uiNamespace tooltip).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * The label <CONTROL>
 *
 * Example:
 * [_display] call einv_gui_fnc_makeTooltip;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

private _theme = GVAR(theme);

private _tooltip = [
    _display, controlNull, [0, 0, 0, TEXT_UNIT * 0.85], "", TEXT_UNIT * 0.58,
    _theme getOrDefault ["text", [1, 1, 1, 1]], _theme getOrDefault ["font", "PuristaMedium"], 2
] call FUNC(uiLabel);

_tooltip ctrlSetBackgroundColor (_theme getOrDefault ["tooltipBg", [0.03, 0.03, 0.03, 0.96]]);
_tooltip ctrlShow false;

_tooltip
