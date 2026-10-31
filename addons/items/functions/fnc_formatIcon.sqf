#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes the value of icon= (a rule) or aio_icon (an item's config) from [scale, across, down], the way
 * fnc_parseIcon reads it back: the scale alone when the picture is not moved, else the scale, an "@", and
 * the two offsets split by a colon - or by a comma, which is how config writes it. To two decimals, the
 * shortest way: [1.4, 0, 0] is "1.4", [1, 0.1, -0.05] is "1@0.1:-0.05".
 *
 * A rules text always uses the colon, since a comma ends a statement there.
 *
 * Arguments:
 * 0: The icon, [scale, across, down] <ARRAY>
 * 1: What splits the two offsets: ":" for a rules text, "," for config <STRING> (default: ":")
 *
 * Return Value:
 * The value <STRING>
 *
 * Example:
 * [[1.4, 0.1, -0.05]] call aio_items_fnc_formatIcon;
 * // "1.4@0.1:-0.05"
 *
 * Public: No
 */

params [["_icon", ICON_PLAIN, [[]]], ["_separator", ":", [""]]];

_icon params [["_scale", 1, [0]], ["_across", 0, [0]], ["_down", 0, [0]]];

// To two decimals, no minus before a zero: str would write -0 for it.
private _fnc_number = {
    params ["_number"];

    _number = (round (_number * 100)) / 100;

    if (_number == 0) then {_number = 0};

    str _number
};

if ((round (_across * 100)) == 0 && {(round (_down * 100)) == 0}) exitWith {
    [_scale] call _fnc_number
};

format ["%1@%2%3%4", [_scale] call _fnc_number, [_across] call _fnc_number, _separator, [_down] call _fnc_number]
