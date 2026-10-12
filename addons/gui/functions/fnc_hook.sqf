#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Asks the window that attached (fnc_attach) what it wants done at one of the places the engine of this
 * addon offers: a CODE in the hook table (GVAR(hooks)), called with the arguments, or a flag that is
 * only looked at. A hook that is not there, or returns nothing, gives the default - so with an empty
 * table every function that asks behaves exactly as it did before hooks existed.
 *
 * The hooks and what each takes and returns are listed in docs/ARCHITECTURE.md, "Window engine for
 * other displays".
 *
 * Arguments:
 * 0: Name of the hook <STRING>
 * 1: Arguments for it, passed on as its _this <ARRAY> (default: [])
 * 2: What to answer when there is no hook or it answers nothing <ANY> (default: nil)
 *
 * Return Value:
 * The hook's answer, the flag's value, or the default <ANY>
 *
 * Example:
 * ["key", [_display, 14, false, false, false], false] call einv_gui_fnc_hook;
 *
 * Public: No
 */

params [["_name", "", [""]], ["_args", [], [[]]], "_default"];

if !(_name in GVAR(hooks)) exitWith {_default};

private _hook = GVAR(hooks) get _name;

if (isNil "_hook") exitWith {_default};

// A flag: not code, so nothing to call - its value is the answer.
if !(_hook isEqualType {}) exitWith {_hook};

private _result = _args call _hook;

if (isNil "_result") exitWith {_default};

_result
