#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an item's name matches what is typed in the search field (GVAR(filter)): by its name or short
 * name as the window shows them (fnc_itemName: a kit by the name its player gave it), upper or lower case
 * alike. An empty field matches everything. Whether the item was searched is not asked here.
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * Matches <BOOL>
 *
 * Example:
 * ["FirstAidKit"] call aio_gui_fnc_matchesFilter;
 *
 * Public: No
 */

params [["_class", "", [""]]];

private _filter = toLower GVAR(filter);

_filter isEqualTo ""
|| {(toLower ([_class] call FUNC(itemName))) find _filter >= 0}
|| {(toLower ([_class, true] call FUNC(itemName))) find _filter >= 0}
