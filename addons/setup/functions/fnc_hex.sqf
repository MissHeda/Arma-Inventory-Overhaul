#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A theme colour as structured text writes colours: #RRGGBB. The alpha is left out - structured text
 * would read a fourth byte as the first.
 *
 * Arguments:
 * 0: Colour [r, g, b, a] <ARRAY>
 *
 * Return Value:
 * Colour <STRING>
 *
 * Example:
 * [[0.84, 0.54, 0.1, 1]] call aio_setup_fnc_hex;
 *
 * Public: No
 */

params [["_color", [1, 1, 1, 1], [[]]]];

private _digits = "0123456789ABCDEF";

"#" + (((_color select [0, 3]) apply {
    private _value = round (((_x max 0) min 1) * 255);

    (_digits select [floor (_value / 16), 1]) + (_digits select [_value mod 16, 1])
}) joinString "")
