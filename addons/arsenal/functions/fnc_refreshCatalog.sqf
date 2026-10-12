#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The supply or the rules changed: the lists are worked out again and the cards rebound. The lists of every
 * category are dropped for a change of supply, the rows too for a change of rules (the rows are dropped by
 * the event itself, the catalog's frame notices).
 *
 * Arguments:
 * 0: Drop the lists, not only rebind <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [true] call einv_arsenal_fnc_refreshCatalog;
 *
 * Public: No
 */

params [["_dropLists", false, [false]]];

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];

if (_dropLists) then {
    GVAR(lists) = createHashMap;
    GVAR(uniqueCache) = createHashMap;
    _column set ["listKey", []];
};

// The rows are read in the background again from the top, so what the rules changed shows.
_column set ["warmKey", []];
_column set ["names", createHashMap];
_column set ["dirty", true];
_column set ["barDirty", true];
_column set ["searchAt", 0];
