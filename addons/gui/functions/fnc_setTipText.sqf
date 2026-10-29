#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts a name on the name at the mouse (fnc_makeTooltip): plain text on its label, or - while the palette's titles gradient is on -
 * the letters running from the titles' colour into the gradient's (fnc_gradientText). The text is kept on the control, so that one
 * made again over something (fnc_raiseTooltip) gets it back.
 *
 * Arguments:
 * 0: The name at the mouse <CONTROL>
 * 1: Text <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_tooltip, "MX 6.5 mm"] call einv_gui_fnc_setTipText;
 *
 * Public: No
 */

params ["_tooltip", ["_text", "", [""]]];

_tooltip setVariable [QGVAR(tipText), _text];

if !(_tooltip getVariable [QGVAR(gradient), false]) exitWith {
    _tooltip ctrlSetText _text;
};

private _theme = missionNamespace getVariable [QGVAR(theme), createHashMap];
private _from = _theme getOrDefault ["titleColor", []];

if (count _from < 3) then {
    _from = _theme getOrDefault ["accent", [1, 1, 1, 1]];
};

_tooltip ctrlSetStructuredText ([
    _text, _theme getOrDefault ["font", "PuristaMedium"], TEXT_UNIT * 0.58, 2, (_from select [0, 3]) + [1], _theme getOrDefault ["titleGradient", [1, 1, 1]]
] call FUNC(gradientText));
