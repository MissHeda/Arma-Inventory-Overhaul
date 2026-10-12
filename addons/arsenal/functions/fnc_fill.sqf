#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * "Fill with it": adds as many of a class as the container has room for, by the rules of the quick add -
 * room by weight and cells on the grid for each one.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Container <OBJECT>
 *
 * Return Value:
 * How many were added <NUMBER>
 *
 * Example:
 * ["ACE_fieldDressing", vestContainer player] call einv_arsenal_fnc_fill;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_container", objNull, [objNull]]];

if (_class isEqualTo "" || {isNull _container}) exitWith {0};

// More than the cells can hold, whatever the stack: the quick add takes what fits.
private _cells = 0;

{
    _x params [["_cols", 0], ["_rows", 0]];

    _cells = _cells + _cols * _rows;
} forEach ([_container] call EFUNC(storage,getBlocks));

private _stack = (([_class] call EFUNC(items,getInfo)) getOrDefault ["stack", 1]) max 1;

[_class, ((_cells * _stack) min 400) max 1, _container, true] call FUNC(quickAdd)
