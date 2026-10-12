#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Closes the window with an exit code. In the Eden editor 1 applies the changes to the selected units, 2
 * discards them. Nothing happens when the window is not open.
 *
 * Arguments:
 * 0: Exit code <NUMBER> (default: 2)
 *
 * Return Value:
 * None
 *
 * Example:
 * [2] call einv_arsenal_fnc_close;
 *
 * Public: No
 */

params [["_exitCode", 2, [0]]];

private _display = findDisplay IDD_ARSENAL;

if (isNull _display) exitWith {};

_display closeDisplay _exitCode;
