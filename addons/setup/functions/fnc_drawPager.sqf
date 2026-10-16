#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The foot of a class list's page (fnc_drawResults) or of its tree (fnc_drawTree): "31-60 of 212" on the
 * left, an arrow back and an arrow on on the right.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: The page shown, from 0 <NUMBER>
 * 5: How many pages there are <NUMBER>
 * 6: How many classes there are <NUMBER>
 * 7: How many are on this page <NUMBER>
 * 8: How many to a page <NUMBER>
 * 9: Code, called with [arguments, -1 or 1] a moment after an arrow was clicked <CODE>
 * 10: Arguments <ANY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _box, [0, 0.4, 0.3, 0.03], _theme, 0, 3, 80, 30, 30, {params ["_arguments", "_step"]}] call einv_setup_fnc_drawPager;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_box", "_rect", "_theme", ["_page", 0, [0]], ["_pages", 1, [0]], ["_total", 0, [0]], ["_shown", 0, [0]], ["_perPage", LIST_PAGE, [0]],
    ["_code", {}, [{}]], ["_arguments", []]
];
_rect params ["", "_footY", "_width", "_footH"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _turnW = SQUARE(_footH);

[
    _display, _box, [0, _footY, _width - _turnW * 2 - SQUARE(UNIT * 0.4), _footH],
    [LLSTRING(List_None), format [LLSTRING(List_Range), _page * _perPage + 1, _page * _perPage + _shown, _total]] select (_total > 0),
    TEXT_SMALL, _muted, _font, 0
] call EFUNC(gui,uiLabel);

{
    _x params ["_icon", "_step", "_enabled", "_buttonX"];

    [_display, _box, [_buttonX, _footY, _turnW, _footH], "", _icon, _theme, {
        params ["_code", "_arguments", "_step"];

        [_arguments, _step] call _code;
    }, [_code, _arguments, _step], _enabled, "ghost"] call FUNC(uiAction);
} forEach [
    [UI_TEX(icon_chevron_left_ca), -1, _page > 0, _width - _turnW * 2 - SQUARE(UNIT * 0.15)],
    [UI_TEX(icon_chevron_right_ca), 1, _page < _pages - 1, _width - _turnW]
];
