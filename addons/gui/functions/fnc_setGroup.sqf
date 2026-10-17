#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A click on an icon of the strip at the side of a loot box (fnc_drawGroupStrip), run a frame later: the box shows only
 * that category - the tiles of other categories fade as the search field's do (fnc_applyFilter) and a paged box turns to its
 * first page with a match. A click on the category that is chosen, or on "All", shows everything again (and gives back the
 * pages the choice moved). Only that box's tiles are touched; the search field works with it - a tile has to match both.
 *
 * Arguments:
 * 0: The box's container <OBJECT>
 * 1: "weapon", "ammo", "gear", "medical", "food", "tool" or "misc"; "all" for everything <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_crate, "medical"] call einv_gui_fnc_setGroup;
 *
 * Public: No
 */

disableSerialization;

params [["_holder", objNull, [objNull]], ["_group", "all", [""]]];

if (isNull _holder) exitWith {};

private _old = [_holder] call FUNC(boxGroup);
// The category chosen again, or "All", is no category.
private _new = ["", _group] select (_group isNotEqualTo "all" && {_group isNotEqualTo _old});

GVAR(groupFilters) = GVAR(groupFilters) select {(_x select 0) isNotEqualTo _holder};

if (_new isNotEqualTo "") then {
    GVAR(groupFilters) pushBack [_holder, _new];
};

// The strip says which is chosen.
[_holder] call FUNC(paintGroupStrip);

// The tiles follow once per rest for a run of clicks (fnc_filterSoon).
[false] call FUNC(filterSoon);
