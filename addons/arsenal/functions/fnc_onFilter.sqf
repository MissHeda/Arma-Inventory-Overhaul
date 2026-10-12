#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The search field changed (the "filter" hook): the catalog's list - or the loadouts', in the Loadouts view
 * - is worked out again for what is typed. The catalog's frame does it once the typing has been still for
 * SEARCH_DEBOUNCE seconds; emptying the field shows the category again at once.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_onFilter;
 *
 * Public: No
 */

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];

if (isNull (_column getOrDefault ["group", controlNull])) exitWith {};

// The loadouts' rows are drawn by the loadouts (the column is told to draw them again).
if (GVAR(view) isEqualTo "loadouts") exitWith {
    [
        uiNamespace getVariable [QEGVAR(gui,display), displayNull], _column getOrDefault ["rect", [0, 0, 0, 0]],
        EGVAR(gui,theme), "loadouts"
    ] call FUNC(drawColumn);
};

private _text = EGVAR(gui,filter);
private _was = _column getOrDefault ["searched", false];

_column set ["searched", _text isNotEqualTo ""];
_column set ["dirty", true];
_column set ["searchAt", [diag_tickTime, 0] select (_text isEqualTo "")];

// The chips grey out while there is text and come back without it.
if (_was isNotEqualTo (_text isNotEqualTo "")) then {
    _column set ["barDirty", true];
};

// A new list starts at the top.
_column set ["restoreRow", 0];
