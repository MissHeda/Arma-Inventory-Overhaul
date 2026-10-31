#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * How many rows a page of a tall compartment has (the client setting einv_gui_pageRows), 0 for no pages: the setting
 * at 0 or at MAX_ROWS (the tallest a compartment gets) or more, else at least PAGE_MIN_ROWS.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Rows to a page, 0 for none <NUMBER>
 *
 * Example:
 * call einv_gui_fnc_pageRows;
 *
 * Public: No
 */

private _rows = missionNamespace getVariable [QGVAR(pageRows), 10];

if !(_rows isEqualType 0) exitWith {0};
if (_rows <= 0 || {_rows >= MAX_ROWS}) exitWith {0};

(round _rows) max PAGE_MIN_ROWS
