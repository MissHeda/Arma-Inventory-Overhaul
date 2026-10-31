#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The background colour of an item's tile: the colour the setup gives one of its categories (category=... color=, the item's
 * "tileColor"), else the look's own colour of its tile category (the theme's "tileBg"). Either way at the strength the theme
 * gives that category's tiles, so the tile transparency of the palette counts for both.
 *
 * Arguments:
 * 0: Theme <HASHMAP>
 * 1: The item's info (einv_items_fnc_getInfo) <HASHMAP>
 * 2: Fallback <ARRAY> (default: [1, 1, 1, 0.075])
 *
 * Return Value:
 * Colour [r, g, b, a] <ARRAY>
 *
 * Example:
 * [_theme, _info] call einv_gui_fnc_tileColour;
 *
 * Public: No
 */

params [["_theme", createHashMap, [createHashMap]], ["_info", createHashMap, [createHashMap]], ["_fallback", [1, 1, 1, 0.075], [[]]]];

private _plain = +((_theme getOrDefault ["tileBg", []]) param [_info getOrDefault ["category", 0], _fallback]);

if !(_plain isEqualType []) then {
    _plain = +_fallback;
};

private _own = _info getOrDefault ["tileColor", []];

if (count _own < 3) exitWith {_plain};

(_own select [0, 3]) + [_plain param [3, 1]]
