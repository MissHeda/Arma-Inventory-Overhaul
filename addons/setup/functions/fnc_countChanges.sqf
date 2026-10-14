#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many changes the draft holds against what was last saved or loaded - the rows Review lists
 * (fnc_changeRows "saved"), so the header's "4 changes" and that list always agree: the preset, the cell
 * size, the switch to force it over the mission, and each group or rule added, changed or taken away. For
 * the header and the dots on the steps.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [all changes, preset or cell size changed, statements changed] <ARRAY>
 *
 * Example:
 * (call einv_setup_fnc_countChanges) select 0;
 *
 * Public: No
 */

private _kinds = (["saved", false] call FUNC(changeRows)) apply {_x select 0};

[count _kinds, ("preset" in _kinds) || {"cell" in _kinds}, ("group" in _kinds) || {"rule" in _kinds}]
