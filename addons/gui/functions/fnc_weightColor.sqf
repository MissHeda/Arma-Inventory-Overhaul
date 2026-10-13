#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The colour of a load on the weight card (fnc_drawEquipmentCards): the bar's fill, the tier's words and
 * the preview of a pick-up (fnc_previewWeight). Light is the quiet text2, Heavy the accent, Overloaded and
 * Critical the loss colour - all from the theme. Inside a tier the colour is plain; over the last 6 % of
 * the bar before a tier's limit it blends into that tier's, so the fill does not jump where a limit is
 * crossed and the player sees it coming without any mark on the bar.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Load, config mass <NUMBER>
 * 2: Theme <HASHMAP> (default: the window's)
 *
 * Return Value:
 * Colour [r, g, b, a] <ARRAY>
 *
 * Example:
 * [player, 640, _theme] call einv_gui_fnc_weightColor;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_load", 0, [0]], ["_theme", GVAR(theme), [createHashMap]]];

private _colors = [
    _theme getOrDefault ["text2", [0.639, 0.675, 0.725, 1]],
    _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]],
    _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]],
    _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]
];

private _limits = [_unit] call EFUNC(weight,getLimits);
private _band = ((_limits get "critical") max 1) * 0.06;
private _tier = [_unit, _load] call EFUNC(weight,getTier);

// The tier the load would be in a little further up: when it is another one, the blend has begun.
private _ahead = [_unit, _load + _band] call EFUNC(weight,getTier);
private _color = _colors select _tier;

if (_ahead > _tier) then {
    private _limit = _limits get (["", "heavy", "overloaded", "critical"] select _ahead);
    private _share = (((_load - (_limit - _band)) / _band) max 0) min 1;
    private _target = _colors select _ahead;

    _color = [0, 1, 2, 3] apply {linearConversion [0, 1, _share, _color select _x, _target select _x]};
};

_color
