#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The colour of an item's tiles, from its own color=, its categories and tint=: its own colour first; else the category tint=
 * names when it is one of them, else the first of them the setup gives a colour (category=... color=). One of them without a
 * colour of its own leaves the look's own tile of the item's kind (weapons, ammunition, gear and medical have a hint of
 * colour there). No colour at all - tint=none, or no category (cats=none) - is the plain tile, the look's tile of everything
 * else, whatever the item is. fnc_getInfo answers it for the rules in effect, the setup wizard's item editor for what is being
 * picked (issue #40).
 *
 * Arguments:
 * 0: The item's categories, "groups" of fnc_getInfo <ARRAY of STRING>
 * 1: tint=, "" for none <STRING>
 * 2: Compiled rules (fnc_compileRules) <HASHMAP>
 * 3: color=, six hex digits, "" for none <STRING> (default: "")
 *
 * Return Value:
 * [colour [r, g, b] or [] for the look's own, plain <BOOL>] <ARRAY>
 *
 * Example:
 * [["medical", "tool"], "tool", call aio_items_fnc_currentRules] call aio_items_fnc_tileTint;
 *
 * Public: No
 */

params [["_groups", [], [[]]], ["_tint", "", [""]], ["_compiled", createHashMap, [createHashMap]], ["_own", "", [""]]];

if (count _own == 6) then {
    private _digits = "0123456789abcdef";
    private _nibbles = (toLowerANSI _own splitString "") apply {_digits find _x};

    if (_nibbles findIf {_x < 0} >= 0) then {
        _own = "";
    } else {
        _own = [0, 2, 4] apply {((_nibbles select _x) * 16 + (_nibbles select (_x + 1))) / 255};
    };
};

if (_own isEqualType []) exitWith {[_own, false]};

if (_tint isEqualTo "none" || {_groups isEqualTo []}) exitWith {[[], true]};

private _categoryDefs = _compiled getOrDefault ["categoryDefs", createHashMap];
private _pick = if (_tint in _groups) then {
    _tint
} else {
    (_groups select {((_categoryDefs getOrDefault [_x, []]) param [2, ""]) isNotEqualTo ""}) param [0, ""]
};

if (_pick isEqualTo "") exitWith {[[], false]};

[([_pick, _compiled] call FUNC(categoryInfo)) get "color", false]
