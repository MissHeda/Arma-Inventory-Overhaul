#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What a Sort button is made of, for fnc_drawSection and fnc_drawWindow: its label in the order the player
 * has now ("Sort: Name", fnc_sortText), the sorting icon, and a width that fits the widest label of all the
 * orders - the label changes in place when a click steps to the next order (fnc_sortButtons), so the button
 * keeps its size and the caption line does not move.
 *
 * Where there is no room for that, a compact one: the icon and "Sort", or the icon alone - the order it sorts
 * by is then in its tooltip (fnc_sortText, fnc_sortButtons). A kit window's title row steps down to these
 * before it leaves Sort out (fnc_drawWindow).
 *
 * Arguments:
 * 0: Height of the button <NUMBER>
 * 1: Text height - the label's size <NUMBER>
 * 2: Theme <HASHMAP>
 * 3: Compact - 0 the full label, 1 the icon and "Sort", 2 the icon alone <NUMBER> (default: 0)
 *
 * Return Value:
 * [label, icon, width] <ARRAY>
 *
 * Example:
 * [0.017, 0.0125, _theme] call aio_gui_fnc_sortChip;
 *
 * Public: No
 */

params ["_height", "_size", "_theme", ["_compact", 0, [0]]];

private _icon = UI_TEX(icon_sort_desc_ca);

// Compact: the same words whatever the order, so the width is theirs.
if (_compact > 0) exitWith {
    private _short = ["", LLSTRING(Section_Sort)] select (_compact == 1);

    [_short, _icon, [_short, _icon, _height, _size, _theme] call FUNC(buttonWidth)]
};

private _width = 0;

{
    _width = _width max ([(([_x] call FUNC(sortText)) select 0), _icon, _height, _size, _theme] call FUNC(buttonWidth));
} forEach SORT_MODES;

[(([GVAR(sortMode)] call FUNC(sortText)) select 0), _icon, _width]
