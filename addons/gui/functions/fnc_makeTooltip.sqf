#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Makes the name at the mouse: a group, on the display and hidden, which fnc_updateHover fills and shows and fnc_onFrame keeps
 * beside the pointer. Its glass and its words are drawn into it by fnc_setTipText, which knows the size: round corners as the
 * comparison card has them (fnc_drawCompare), the words in the middle. Made after every build (fnc_drawTopLayer) and again
 * whenever it has to lie over something made after it (fnc_raiseTooltip). It is not kept anywhere here: the caller says where
 * (uiNamespace tooltip).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * The group <CONTROL>
 *
 * Example:
 * [_display] call einv_gui_fnc_makeTooltip;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

private _tip = [_display, "EINV_Group", controlNull, [-10, -10, 0, TEXT_UNIT * 0.85]] call FUNC(uiCreate);

// With the titles' gradient on, its words are structured text: their letters take the gradient (fnc_setTipText).
_tip setVariable [QGVAR(gradient), (GVAR(theme) getOrDefault ["titleGradient", []]) isNotEqualTo []];
_tip setVariable [QGVAR(tipParts), []];
_tip ctrlShow false;

_tip
