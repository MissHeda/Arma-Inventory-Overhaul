#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What a Sort button is made of, for fnc_drawSection and fnc_drawWindow: its label in the order the player
 * has now ("Sort: Name", fnc_sortText), the sorting icon, and a width that fits the widest label of all the
 * orders - the label changes in place when a click steps to the next order (fnc_sortButtons), so the button
 * keeps its size and the caption line does not move.
 *
 * Arguments:
 * 0: Height of the button <NUMBER>
 * 1: Text height - the label's size <NUMBER>
 * 2: Theme <HASHMAP>
 *
 * Return Value:
 * [label, icon, width] <ARRAY>
 *
 * Example:
 * [0.017, 0.0125, _theme] call einv_gui_fnc_sortChip;
 *
 * Public: No
 */

params ["_height", "_size", "_theme"];

private _icon = UI_TEX(icon_sort_desc_ca);
private _width = 0;

{
    _width = _width max ([(([_x] call FUNC(sortText)) select 0), _icon, _height, _size, _theme] call FUNC(buttonWidth));
} forEach SORT_MODES;

[(([GVAR(sortMode)] call FUNC(sortText)) select 0), _icon, _width]
