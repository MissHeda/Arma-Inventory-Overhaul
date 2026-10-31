#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Fades and hides the tiles by the search field and the categories again (fnc_applyFilter, turning the paged boxes to what it found)
 * for a change that came from a keystroke or a click on the strip of categories - not once per key or click: what is typed
 * (GVAR(filter)) and what is chosen (GVAR(groupFilters)) are already set by the caller; the tiles follow once a
 * COALESCE_TYPING after the last key, and a category click once per rest (fnc_coalesce, key "filter"). A box that
 * is drawn meanwhile reads the same state, so nothing shows a stale search.
 *
 * Arguments:
 * 0: It comes from typing - wait for the last key <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [true] call einv_gui_fnc_filterSoon;
 *
 * Public: No
 */

params [["_typing", false, [false]]];

["filter", {
    [true] call FUNC(applyFilter);
}, [], [COALESCE_GAP, COALESCE_TYPING] select _typing, _typing] call FUNC(coalesce);
