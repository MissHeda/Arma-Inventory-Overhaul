#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Registers an arsenal with a stock of its own that is built on the vanilla Virtual Arsenal (RscDisplayArsenal), such as
 * Antistasi's JNA arsenal. While the grid panel lies on such an arsenal, what the panel adds to the soldier is taken from
 * the stock and what it takes away is given back to it, so nothing is made or lost.
 *
 * The adapter is a hash map of code:
 * - "claims"    [args] -> BOOL: this vanilla open is the arsenal's (args: BIS_fnc_arsenal "Open"'s, or [] at arsenalOpened)
 * - "panel"     [] -> BOOL: the grid panel lies beside its list
 * - "rowClass"  [list, row] -> STRING: the class of a row of its cargo lists ("" for none)
 * - "available" [class] -> NUMBER: how many of the class may be taken now, -1 without a limit
 * - "census"    [containers] -> ANY: what the containers hold, in the stock's own terms
 * - "settle"    [before, after] -> NOTHING: takes from the stock what came in, gives back what went out
 * - "name"      STRING: shown in the RPT
 *
 * Arguments:
 * 0: The adapter <HASHMAP>
 *
 * Return Value:
 * Registered <BOOL>
 *
 * Example:
 * [_adapter] call aio_arsenal_fnc_registerPool;
 *
 * Public: Yes
 */

params [["_adapter", createHashMap, [createHashMap]]];

private _name = _adapter getOrDefault ["name", "?"];
private _missing = ["claims", "panel", "rowClass", "available", "census", "settle"] select {
    !((_adapter getOrDefault [_x, 0]) isEqualType {})
};

if (_missing isNotEqualTo []) exitWith {
    WARNING_2("Pool adapter %1 not registered - missing: %2.",_name,_missing);
    false
};

GVAR(poolAdapters) pushBack _adapter;
INFO_1("Pool adapter registered: %1.",_name);

true
