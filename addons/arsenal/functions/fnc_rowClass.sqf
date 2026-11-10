#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The class of a row of an arsenal list: the row's data (lnbData [row, 0] of a list with columns, lbData of a plain one),
 * or what the stock's adapter reads from it (GVAR(pool) "rowClass") - JNA keeps a whole array there.
 *
 * Arguments:
 * 0: The list <CONTROL>
 * 1: The row <NUMBER>
 *
 * Return Value:
 * The class, "" for none <STRING>
 *
 * Example:
 * [_list, 3] call aio_arsenal_fnc_rowClass;
 *
 * Public: No
 */

params [["_list", controlNull, [controlNull]], ["_row", -1, [0]]];

if (isNull _list || {_row < 0}) exitWith {""};

if (count GVAR(pool) > 0) exitWith {
    private _class = [_list, _row] call (GVAR(pool) get "rowClass");

    [_class, ""] select (isNil "_class" || {!(_class isEqualType "")})
};

if (ctrlType _list == 102) exitWith {_list lnbData [_row, 0]};

_list lbData _row
