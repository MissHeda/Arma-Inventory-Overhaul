#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes the footer's hint while something is dragged: what the keys do, or - over a target that cannot
 * take it, or that will tire the soldier - why (fnc_updateDrag). Called every frame of a drag with the parts
 * the target gives, so it writes only when they differ from what stands there: rewriting structured text
 * every frame costs more than the whole drag.
 *
 * Arguments:
 * 0: The hint, [[text, colour key], ...] - keys of the theme, as fnc_showHint takes them; written one after
 *    the other with a gap <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[["+2.4 kg: you will be Overloaded", "loss"]]] call einv_gui_fnc_dragHint;
 *
 * Public: No
 */

disableSerialization;

params [["_parts", [], [[]]]];

private _hint = uiNamespace getVariable [QGVAR(hint), controlNull];

if (isNull _hint || {_parts isEqualTo GVAR(dragHintShown)}) exitWith {};

GVAR(dragHintShown) = _parts;

private _theme = GVAR(theme);
private _font = _theme getOrDefault ["font", "PuristaMedium"];

// Structured text takes its colours as #RRGGBB.
private _fnc_hex = {
    params ["_color"];

    "#" + (((_color select [0, 3]) apply {
        private _value = round ((_x max 0 min 1) * 255);
        ("0123456789ABCDEF" select [floor (_value / 16), 1]) + ("0123456789ABCDEF" select [_value mod 16, 1])
    }) joinString "")
};

private _texts = [];

{
    _x params ["_text", ["_key", "text2"]];

    if (_texts isNotEqualTo []) then {
        _texts pushBack "    ";
    };

    _texts pushBack (text _text setAttributes [
        "color", [_theme getOrDefault [_key, [1, 1, 1, 1]]] call _fnc_hex,
        "font", _font
    ]);
} forEach _parts;

_hint ctrlSetStructuredText (composeText _texts setAttributes ["align", "left", "size", str (_hint getVariable [QGVAR(textScale), 1])]);
[_hint] call FUNC(fitHint);
