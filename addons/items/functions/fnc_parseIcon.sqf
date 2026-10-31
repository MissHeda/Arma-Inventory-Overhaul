#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads the value of icon= (a rule) or aio_icon (an item's config): how large an item's picture is drawn in
 * its tile and where. The one reader of that value, as fnc_parseMask is of masks.
 *
 *   1.4              the picture 1.4 times as large as it is fitted into the tile
 *   1.4@0.1:-0.05    and moved a tenth of the tile's width to the right and a twentieth of its height up
 *   1.4@0.1,-0.05    the same, as config writes it - a rules text cannot, since its comma ends a statement
 *                    (fnc_parseRules joins a comma typed there back); the writer (fnc_formatIcon) uses the colon
 *
 * The scale is ICON_SCALE_MIN to ICON_SCALE_MAX (0.25 to 4), each offset -ICON_OFFSET_MAX to ICON_OFFSET_MAX
 * (-1 to 1): across, positive to the right, as a share of the tile's width, and down, positive downwards, as a
 * share of its height. All to two decimals. A scale of 1 with no offset is the plain picture and a legal value,
 * which is how a rule takes back what a broader one set.
 *
 * What is past a limit is cut down and said so; what cannot be read gives [] and the reason. A picture that
 * reaches out of its tile is cut to the tile by the window, whatever the numbers are.
 *
 * Arguments:
 * 0: The value, as typed (spaces are ignored) <STRING>
 *
 * Return Value:
 * [icon, notes] <ARRAY>
 *   icon  - [scale, across, down] <ARRAY>, [] when it cannot be read
 *   notes - what was left out or cut down, each naming the value <ARRAY of STRING>
 *
 * Example:
 * ["1.4@0.1:-0.05"] call aio_items_fnc_parseIcon;
 * // [[1.4, 0.1, -0.05], []]
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _value = (_text splitString (toString [32, 9, 10, 13])) joinString "";
private _notes = [];

// Digits with one dot at most: 12, 0.5, 1.25. No sign.
private _fnc_isNumber = {
    params ["_digits"];

    private _codes = toArray _digits;

    _codes findIf {_x >= 48 && {_x <= 57}} >= 0
    && {_codes findIf {(_x < 48 || {_x > 57}) && {_x != 46}} < 0}
    && {({_x == 46} count _codes) <= 1}
};

// The same with a minus or a plus in front: an offset.
private _fnc_isSigned = {
    params ["_digits"];

    if ((_digits select [0, 1]) in ["-", "+"]) then {
        _digits = _digits select [1];
    };

    [_digits] call _fnc_isNumber
};

// Both offsets, across and down, split by a comma (config) or a colon (a rules text): [] when they are not
// two numbers with exactly one such sign between them.
private _fnc_offsets = {
    params ["_offsetText"];

    private _parts = _offsetText splitString ",:";

    if (
        count _parts != 2 || {({_x in [44, 58]} count (toArray _offsetText)) != 1}
        || {!([_parts select 0] call _fnc_isSigned)} || {!([_parts select 1] call _fnc_isSigned)}
    ) exitWith {[]};

    _parts apply {parseNumber ((_x splitString "+") joinString "")}
};

if (_value isEqualTo "") exitWith {
    [[], ["icon= without a value - this part is left out"]]
};

private _at = _value find "@";
private _scaleText = if (_at < 0) then {_value} else {_value select [0, _at]};

if !([_scaleText] call _fnc_isNumber) exitWith {
    [[], [format ["icon=%1 is no picture scale like 1.4 or 1.4@0.1:-0.05 - this part is left out", _value]]]
};

private _offsets = if (_at < 0) then {[0, 0]} else {[_value select [_at + 1]] call _fnc_offsets};

if (_offsets isEqualTo []) exitWith {
    [[], [format ["icon=%1: the offsets are two numbers, across and down, like @0.1:-0.05 (@0.1,-0.05 in config) - this part is left out", _value]]]
};

_offsets params ["_across", "_down"];

private _scale = parseNumber _scaleText;

if (_scale < ICON_SCALE_MIN || {_scale > ICON_SCALE_MAX}) then {
    _scale = (_scale max ICON_SCALE_MIN) min ICON_SCALE_MAX;
    _notes pushBack format ["icon=%1: the scale is between %2 and %3 - cut to %4", _value, ICON_SCALE_MIN, ICON_SCALE_MAX, _scale];
};

if (abs _across > ICON_OFFSET_MAX || {abs _down > ICON_OFFSET_MAX}) then {
    _across = (_across max (-ICON_OFFSET_MAX)) min ICON_OFFSET_MAX;
    _down = (_down max (-ICON_OFFSET_MAX)) min ICON_OFFSET_MAX;
    _notes pushBack format ["icon=%1: an offset is between -%2 and %2 of the tile - cut down", _value, ICON_OFFSET_MAX];
};

// To two decimals: finer would come back from str as 1e-05, which no rule can read again. A minus before
// a zero ("-0") is not written either.
_scale = (round (_scale * 100)) / 100;
_across = (round (_across * 100)) / 100;
_down = (round (_down * 100)) / 100;

if (_across == 0) then {_across = 0};
if (_down == 0) then {_down = 0};

[[_scale, _across, _down], _notes]
