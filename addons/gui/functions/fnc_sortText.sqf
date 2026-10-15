#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The words of a Sort button for the order the player has now: its label, "Sort: Name", and what its tooltip
 * says - that the next click sorts by the next order. The button shows the order the container was last
 * sorted by, and a click steps on to the next one and sorts by that (fnc_sortHolder), so the tooltip names
 * what the click will do.
 *
 * Arguments:
 * 0: The order, one of SORT_MODES <STRING>
 *
 * Return Value:
 * [label, tooltip] <ARRAY>
 *
 * Example:
 * ["weight"] call einv_gui_fnc_sortText;
 *
 * Public: No
 */

params [["_mode", SORT_DEFAULT, [""]]];

private _words = [LLSTRING(Sort_Name), LLSTRING(Sort_Weight), LLSTRING(Sort_Size), LLSTRING(Sort_Type)];
private _tips = [LLSTRING(Sort_Name_Next), LLSTRING(Sort_Weight_Next), LLSTRING(Sort_Size_Next), LLSTRING(Sort_Type_Next)];

private _at = (SORT_MODES find _mode) max 0;

[
    format [LLSTRING(Section_SortBy), _words select _at],
    _tips select ((_at + 1) mod count SORT_MODES)
]
